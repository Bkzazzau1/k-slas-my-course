import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';

class ExamProctoringBackendService {
  ExamProctoringBackendService._();

  static const _kActiveAttemptId = 'exam.activeAttemptId';
  static const _kActiveExamId = 'exam.activeExamId';

  static final http.Client _client = http.Client();

  static CourseCatalogBackendConfig get _config =>
      CourseCatalogBackendConfig.fromRuntime();

  static bool get _isConfigured =>
      LiveSessionRuntimeModeStore.load() == LiveSessionRuntimeMode.production &&
      _config.isConfigured;

  static int? get activeAttemptId {
    final raw = GetStorage().read(_kActiveAttemptId);
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  static Future<void> setActiveAttempt({
    required int examId,
    required int attemptId,
  }) async {
    final box = GetStorage();
    await box.write(_kActiveExamId, examId);
    await box.write(_kActiveAttemptId, attemptId);
  }

  static Future<void> clearActiveAttempt() async {
    final box = GetStorage();
    await box.remove(_kActiveExamId);
    await box.remove(_kActiveAttemptId);
  }

  static Future<int?> startAttempt({
    required int examId,
    required bool environmentConfirmed,
  }) async {
    if (!_isConfigured) return null;
    final payload = await _requestJson(
      method: 'POST',
      pathSegments: ['api', 'exams', '$examId', 'attempts'],
      body: {'environment_confirmed': environmentConfirmed},
    );
    final attemptId = _readInt(payload['id']);
    if (attemptId != null) {
      await setActiveAttempt(examId: examId, attemptId: attemptId);
    }
    return attemptId;
  }

  static Future<bool> submitAttempt({
    required int attemptId,
    required Map<String, dynamic> answerPayload,
    required int integrityScore,
    String? terminationReason,
  }) async {
    if (!_isConfigured) return true;
    try {
      await _requestJson(
        method: 'POST',
        pathSegments: ['api', 'exam-attempts', '$attemptId', 'submit'],
        body: {
          'answer_payload': answerPayload,
          'integrity_score': integrityScore,
          'termination_reason': terminationReason,
        },
      );
      await clearActiveAttempt();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> recordProctoringAlert({
    required String eventType,
    required String message,
    required String severity,
    required int integrityScore,
    Map<String, dynamic> evidence = const {},
  }) async {
    final attemptId = activeAttemptId;
    if (!_isConfigured || attemptId == null) return true;
    try {
      await _requestJson(
        method: 'POST',
        pathSegments: [
          'api',
          'exam-attempts',
          '$attemptId',
          'proctoring-alerts',
        ],
        body: {
          'event_type': eventType,
          'message': message,
          'severity': severity,
          'integrity_score': integrityScore,
          'evidence': evidence,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchInvigilatorAlerts({
    bool acknowledged = false,
  }) async {
    if (!_isConfigured) return const [];
    try {
      final payload = await _requestJson(
        method: 'GET',
        pathSegments: const ['api', 'invigilator', 'alerts'],
        queryParameters: {'acknowledged': acknowledged.toString()},
      );
      final items = payload['items'];
      if (items is! List) return const [];
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<Map<String, dynamic>> _requestJson({
    required String method,
    required List<String> pathSegments,
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(pathSegments, queryParameters: queryParameters);
    final response = switch (method) {
      'GET' => await _client.get(uri, headers: _headers),
      'POST' => await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(body ?? const {}),
      ),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Exam backend request failed (${response.statusCode})');
    }
    if (response.body.trim().isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Exam backend response is not a JSON object.');
  }

  static Uri _buildUri(
    List<String> pathSegments, {
    Map<String, String>? queryParameters,
  }) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    return base.replace(
      pathSegments: [...baseSegments, ...pathSegments],
      queryParameters: queryParameters,
    );
  }

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_config.accessToken}',
  };

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
