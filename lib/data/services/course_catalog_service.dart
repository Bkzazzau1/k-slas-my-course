import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import 'live_session_runtime_mode_service.dart';
import 'student_profile_storage.dart';

class CourseCatalogBackendConfig {
  const CourseCatalogBackendConfig({
    required this.apiBaseUrl,
    required this.accessToken,
  });

  static const String _kApiBaseUrl = 'academic.apiBaseUrl';
  static const String _kAccessToken = 'academic.accessToken';
  static const String _kLiveSessionApiBaseUrl = 'liveSessions.apiBaseUrl';

  static const String _kGoApiBaseEnv = 'KSLAS_GO_API_BASE_URL';
  static const String _kApiBaseEnv = 'KSLAS_API_BASE_URL';
  static const String _kGoAccessTokenEnv = 'KSLAS_GO_ACCESS_TOKEN';
  static const String _kAccessTokenEnv = 'KSLAS_ACCESS_TOKEN';
  static const String _kLiveSessionGoApiBaseEnv =
      'LIVE_SESSION_GO_API_BASE_URL';
  static const String _kLiveSessionApiBaseEnv = 'LIVE_SESSION_API_BASE_URL';

  final String apiBaseUrl;
  final String accessToken;

  bool get isConfigured => apiBaseUrl.isNotEmpty && accessToken.isNotEmpty;

  factory CourseCatalogBackendConfig.fromRuntime() {
    final box = GetStorage();
    final storedApiBaseUrl = box.read(_kApiBaseUrl)?.toString().trim() ?? '';
    final storedAccessToken = box.read(_kAccessToken)?.toString().trim() ?? '';
    final storedLiveSessionBase =
        box.read(_kLiveSessionApiBaseUrl)?.toString().trim() ?? '';

    final apiBaseUrl = storedApiBaseUrl.isNotEmpty
        ? storedApiBaseUrl
        : _firstNonEmpty([
            const String.fromEnvironment(_kGoApiBaseEnv).trim(),
            const String.fromEnvironment(_kApiBaseEnv).trim(),
            storedLiveSessionBase,
            const String.fromEnvironment(_kLiveSessionGoApiBaseEnv).trim(),
            const String.fromEnvironment(_kLiveSessionApiBaseEnv).trim(),
          ]);

    final accessToken = storedAccessToken.isNotEmpty
        ? storedAccessToken
        : _firstNonEmpty([
            const String.fromEnvironment(_kGoAccessTokenEnv).trim(),
            const String.fromEnvironment(_kAccessTokenEnv).trim(),
          ]);

    return CourseCatalogBackendConfig(
      apiBaseUrl: apiBaseUrl,
      accessToken: accessToken,
    );
  }

  static String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}

abstract class CourseCatalogGateway {
  Future<List<CourseModel>> fetchCourses();

  String get providerLabel;
}

class LocalCourseCatalogGateway implements CourseCatalogGateway {
  LocalCourseCatalogGateway._();

  static final LocalCourseCatalogGateway instance =
      LocalCourseCatalogGateway._();

  static const List<CourseModel> _seededCourses = [
    CourseModel(
      'CSC 305',
      'Data Structures',
      notes: true,
      pastQuestions: true,
      progress: 72,
    ),
    CourseModel(
      'MTH 202',
      'Linear Algebra',
      notes: true,
      pastQuestions: false,
      progress: 48,
    ),
    CourseModel(
      'GST 201',
      'Use of English',
      notes: false,
      pastQuestions: true,
      progress: 54,
    ),
  ];

  @override
  String get providerLabel => 'Demo course catalog';

  @override
  Future<List<CourseModel>> fetchCourses() async =>
      List<CourseModel>.from(_seededCourses);

  CourseModel? hintForCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final course in _seededCourses) {
      if (course.code.trim().toUpperCase() == normalized) {
        return course;
      }
    }
    return null;
  }
}

class RemoteCourseCatalogGateway implements CourseCatalogGateway {
  RemoteCourseCatalogGateway({
    http.Client? client,
    CourseCatalogBackendConfig? config,
    LocalCourseCatalogGateway? fallbackGateway,
  }) : _client = client ?? http.Client(),
       _config = config ?? CourseCatalogBackendConfig.fromRuntime(),
       _fallbackGateway = fallbackGateway ?? LocalCourseCatalogGateway.instance;

  final http.Client _client;
  final CourseCatalogBackendConfig _config;
  final LocalCourseCatalogGateway _fallbackGateway;

  LiveSessionRuntimeMode get runtimeMode => LiveSessionRuntimeModeStore.load();
  bool get wantsProduction => runtimeMode == LiveSessionRuntimeMode.production;
  bool get isConfigured => wantsProduction && _config.isConfigured;

  @override
  String get providerLabel => wantsProduction
      ? 'Go academic API (demo fallback)'
      : _fallbackGateway.providerLabel;

  @override
  Future<List<CourseModel>> fetchCourses() async {
    if (!isConfigured) {
      return _fallbackGateway.fetchCourses();
    }

    try {
      final uri = _buildUri(const ['api', 'my', 'course-registrations']);
      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_config.accessToken}',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallbackGateway.fetchCourses();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _fallbackGateway.fetchCourses();
      }

      final items = _asList(decoded['items'])
          .map(_registeredCourseFromJson)
          .where((course) => course.code.trim().isNotEmpty)
          .toList();

      if (items.isEmpty) {
        return _fallbackGateway.fetchCourses();
      }

      await _syncRegisteredCoursesToProfile(items);

      return items;
    } catch (_) {
      return _fallbackGateway.fetchCourses();
    }
  }

  Uri _buildUri(
    List<String> pathSegments, {
    Map<String, String>? queryParameters,
  }) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();

    final mergedSegments = [...baseSegments];
    for (final segment in pathSegments) {
      if (mergedSegments.isNotEmpty &&
          mergedSegments.last.toLowerCase() == segment.toLowerCase()) {
        continue;
      }
      mergedSegments.add(segment);
    }

    return base.replace(
      pathSegments: mergedSegments,
      queryParameters: queryParameters,
    );
  }

  CourseModel _courseFromJson(Object? value) {
    final payload = _asMap(value);
    final code = _readString(payload['code']).toUpperCase();
    final title = _readString(payload['title'], fallback: code);
    final hint = _fallbackGateway.hintForCode(code);

    return CourseModel(
      code,
      title,
      id: int.tryParse(payload['id']?.toString() ?? ''),
      notes: hint?.notes ?? true,
      pastQuestions: hint?.pastQuestions ?? true,
      progress: hint?.progress ?? 0,
    );
  }

  CourseModel _registeredCourseFromJson(Object? value) {
    final payload = _asMap(value);
    final nestedCourse = _asMap(payload['course']);
    if (nestedCourse.isNotEmpty) {
      return _courseFromJson(nestedCourse);
    }
    final code = _readString(payload['course_code']).toUpperCase();
    final title = _readString(payload['course_title'], fallback: code);
    final hint = _fallbackGateway.hintForCode(code);
    return CourseModel(
      code,
      title,
      id: int.tryParse(payload['course_id']?.toString() ?? ''),
      notes: hint?.notes ?? true,
      pastQuestions: hint?.pastQuestions ?? true,
      progress: hint?.progress ?? 0,
    );
  }

  Future<void> _syncRegisteredCoursesToProfile(
    List<CourseModel> courses,
  ) async {
    final profile = StudentProfileStorage.load();
    if (profile == null) return;
    await StudentProfileStorage.save(
      StudentProfileModel(
        schoolId: profile.schoolId,
        schoolName: profile.schoolName,
        departmentId: profile.departmentId,
        departmentName: profile.departmentName,
        level: profile.level,
        semester: profile.semester,
        selectedCourses: courses.map((course) => course.code).toList(),
        fullName: profile.fullName,
        matricNo: profile.matricNo,
        email: profile.email,
        phone: profile.phone,
        studentCategoryKey: profile.studentCategoryKey,
      ),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return const {};
  }

  static List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    return const [];
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}
