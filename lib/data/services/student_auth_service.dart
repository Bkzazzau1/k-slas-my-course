import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../models/student_profile_model.dart';
import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';
import 'student_profile_storage.dart';

class StudentAuthService {
  StudentAuthService._();

  static const String _kAccessToken = 'academic.accessToken';

  static Future<bool> login({
    required String identity,
    required String password,
    http.Client? client,
  }) async {
    final config = CourseCatalogBackendConfig.fromRuntime();
    if (LiveSessionRuntimeModeStore.load() !=
            LiveSessionRuntimeMode.production ||
        config.apiBaseUrl.trim().isEmpty) {
      return false;
    }

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.post(
        _uri(config.apiBaseUrl, const ['api', 'auth', 'login']),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'identity': identity, 'password': password}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      final token = decoded['access_token']?.toString().trim() ?? '';
      final user = decoded['user'];
      if (token.isEmpty || user is! Map) return false;

      await GetStorage().write(_kAccessToken, token);
      await _hydrateStudentProfile(Map<String, dynamic>.from(user));
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> logout() async {
    await GetStorage().remove(_kAccessToken);
    await StudentProfileStorage.clear();
  }

  static bool get hasToken =>
      (GetStorage().read(_kAccessToken)?.toString().trim() ?? '').isNotEmpty;

  static Future<void> _hydrateStudentProfile(Map<String, dynamic> user) async {
    final roles = (user['roles'] as List? ?? const [])
        .whereType<Map>()
        .map((role) => role['code']?.toString().trim().toLowerCase() ?? '')
        .toSet();
    if (!roles.contains('student')) return;

    final firstName = user['first_name']?.toString() ?? '';
    final lastName = user['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final current = StudentProfileStorage.load();
    await StudentProfileStorage.save(
      StudentProfileModel(
        schoolId: current?.schoolId ?? 'kslas',
        schoolName: current?.schoolName ?? 'K-SLAS',
        departmentId: current?.departmentId ?? '',
        departmentName: current?.departmentName ?? '',
        level: current?.level ?? 0,
        semester: current?.semester ?? 0,
        selectedCourses: current?.selectedCourses ?? const [],
        fullName: fullName.isEmpty ? current?.fullName ?? 'Student' : fullName,
        matricNo: user['matric_no']?.toString() ?? current?.matricNo,
        email: user['email']?.toString() ?? current?.email,
        phone: user['phone']?.toString() ?? current?.phone,
        studentCategoryKey: current?.studentCategoryKey,
      ),
    );
  }

  static Uri _uri(String apiBaseUrl, List<String> segments) {
    final base = Uri.parse(apiBaseUrl);
    final baseSegments = base.pathSegments.where((s) => s.isNotEmpty);
    return base.replace(pathSegments: [...baseSegments, ...segments]);
  }
}
