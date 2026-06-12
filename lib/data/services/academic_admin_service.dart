import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/academic_admin_model.dart';
import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';
import 'student_profile_storage.dart';

class AcademicAdminService {
  AcademicAdminService._();

  static final AcademicAdminGateway gateway = RemoteAcademicAdminGateway(
    fallback: LocalAcademicAdminGateway.instance,
  );
}

abstract class AcademicAdminGateway {
  Future<void> createStaff(AcademicStaffDraft draft);
  Future<void> createStudent(StudentRegistrationDraft draft);
  Future<List<CourseModel>> fetchEligibleCourses();
  Future<List<CourseRegistrationItem>> registerCourses(List<CourseModel> items);
  String get providerLabel;
}

class LocalAcademicAdminGateway implements AcademicAdminGateway {
  LocalAcademicAdminGateway._();

  static final LocalAcademicAdminGateway instance =
      LocalAcademicAdminGateway._();

  @override
  String get providerLabel => 'Demo academic admin';

  @override
  Future<void> createStaff(AcademicStaffDraft draft) async {}

  @override
  Future<void> createStudent(StudentRegistrationDraft draft) async {}

  @override
  Future<List<CourseModel>> fetchEligibleCourses() async => const [
    CourseModel('CSC 305', 'Data Structures', notes: true, pastQuestions: true),
    CourseModel('CSC 309', 'Operating Systems', notes: true),
    CourseModel('MTH 202', 'Linear Algebra', pastQuestions: true),
  ];

  @override
  Future<List<CourseRegistrationItem>> registerCourses(
    List<CourseModel> items,
  ) async {
    final current = StudentProfileStorage.load();
    await StudentProfileStorage.save(
      StudentProfileModel(
        schoolId: current?.schoolId ?? 'kslas',
        schoolName: current?.schoolName ?? 'KSLAS',
        departmentId: current?.departmentId ?? '1',
        departmentName: current?.departmentName ?? 'Computer Science',
        level: current?.level ?? 300,
        semester: current?.semester ?? 1,
        selectedCourses: items.map((course) => course.code).toList(),
        fullName: current?.fullName ?? 'Demo Student',
        matricNo: current?.matricNo,
        email: current?.email,
        phone: current?.phone,
        studentCategoryKey: current?.studentCategoryKey,
      ),
    );
    return items
        .map(
          (course) => CourseRegistrationItem(
            course: course,
            status: 'pending',
            academicSession: '2025/2026',
          ),
        )
        .toList();
  }
}

class RemoteAcademicAdminGateway implements AcademicAdminGateway {
  RemoteAcademicAdminGateway({
    http.Client? client,
    CourseCatalogBackendConfig? config,
    required AcademicAdminGateway fallback,
  }) : _client = client ?? http.Client(),
       _config = config ?? CourseCatalogBackendConfig.fromRuntime(),
       _fallback = fallback;

  final http.Client _client;
  final CourseCatalogBackendConfig _config;
  final AcademicAdminGateway _fallback;

  bool get isConfigured =>
      LiveSessionRuntimeModeStore.load() == LiveSessionRuntimeMode.production &&
      _config.isConfigured;

  @override
  String get providerLabel =>
      isConfigured ? 'Go academic admin API' : _fallback.providerLabel;

  @override
  Future<void> createStaff(AcademicStaffDraft draft) async {
    if (!isConfigured) return _fallback.createStaff(draft);
    final response = await _client.post(
      _uri(['api', 'staff']),
      headers: _jsonHeaders,
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallback.createStaff(draft);
    }
  }

  @override
  Future<void> createStudent(StudentRegistrationDraft draft) async {
    if (!isConfigured) return _fallback.createStudent(draft);
    final response = await _client.post(
      _uri(['api', 'students']),
      headers: _jsonHeaders,
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallback.createStudent(draft);
    }
  }

  @override
  Future<List<CourseModel>> fetchEligibleCourses() async {
    if (!isConfigured) return _fallback.fetchEligibleCourses();
    try {
      final response = await _client.get(
        _uri(['api', 'my', 'eligible-courses']),
        headers: _headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback.fetchEligibleCourses();
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic>
          ? decoded['items']
          : decoded;
      if (items is! List) return _fallback.fetchEligibleCourses();
      return items.whereType<Map>().map((raw) {
        final item = Map<String, dynamic>.from(raw);
        return CourseModel(
          item['code']?.toString() ?? '',
          item['title']?.toString() ?? '',
          id: int.tryParse(item['id']?.toString() ?? ''),
          notes: true,
          pastQuestions: true,
        );
      }).toList();
    } catch (_) {
      return _fallback.fetchEligibleCourses();
    }
  }

  @override
  Future<List<CourseRegistrationItem>> registerCourses(
    List<CourseModel> items,
  ) async {
    if (!isConfigured) return _fallback.registerCourses(items);
    final ids = items.map((course) => course.id).whereType<int>().toList();
    if (ids.isEmpty) return _fallback.registerCourses(items);
    final response = await _client.post(
      _uri(['api', 'my', 'course-registrations']),
      headers: _jsonHeaders,
      body: jsonEncode({'course_ids': ids, 'academic_session': '2025/2026'}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallback.registerCourses(items);
    }
    final decoded = jsonDecode(response.body);
    final bodyItems = decoded is Map<String, dynamic>
        ? decoded['items']
        : decoded;
    if (bodyItems is! List) return _fallback.registerCourses(items);
    return bodyItems
        .whereType<Map>()
        .map(
          (item) =>
              CourseRegistrationItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_config.accessToken}',
  };

  Map<String, String> get _jsonHeaders => {
    ..._headers,
    'Content-Type': 'application/json',
  };

  Uri _uri(List<String> segments) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments.where((s) => s.isNotEmpty);
    return base.replace(pathSegments: [...baseSegments, ...segments]);
  }
}
