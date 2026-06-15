import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../data/services/course_catalog_service.dart';
import '../models/face_verification_log.dart';
import '../models/student_face_profile.dart';
import '../models/student_trusted_device.dart';
import 'identity_trust_repository.dart';

class ApiIdentityTrustRepository implements IdentityTrustRepository {
  ApiIdentityTrustRepository({
    http.Client? client,
    CourseCatalogBackendConfig? config,
  })  : _client = client ?? http.Client(),
        _config = config ?? CourseCatalogBackendConfig.fromRuntime();

  final http.Client _client;
  final CourseCatalogBackendConfig _config;

  bool get isConfigured => _config.isConfigured;

  @override
  Future<StudentFaceProfile?> getFaceProfile(String studentId) async {
    if (!isConfigured) return null;
    final response = await _client.get(
      _uri(<String>['api', 'identity-trust', 'face-profiles', studentId]),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    if (!_isSuccess(response.statusCode)) return null;
    final body = _decodeMap(response.body);
    if (body == null) return null;
    return StudentFaceProfile.fromJson(_normalizeFaceProfile(body));
  }

  @override
  Future<StudentTrustedDevice?> getTrustedDevice({
    required String studentId,
    required String deviceId,
  }) async {
    if (!isConfigured) return null;
    final response = await _client.get(
      _uri(<String>['api', 'identity-trust', 'trusted-devices', studentId, deviceId]),
      headers: _headers,
    );
    if (response.statusCode == 404) return null;
    if (!_isSuccess(response.statusCode)) return null;
    final body = _decodeMap(response.body);
    if (body == null) return null;
    return StudentTrustedDevice.fromJson(_normalizeTrustedDevice(body));
  }

  @override
  Future<void> saveFaceProfile(StudentFaceProfile profile) async {
    if (!isConfigured) return;
    await _client.put(
      _uri(<String>['api', 'identity-trust', 'face-profiles', profile.studentId]),
      headers: _headers,
      body: jsonEncode(profile.toJson()),
    );
  }

  @override
  Future<void> saveTrustedDevice(StudentTrustedDevice device) async {
    if (!isConfigured) return;
    await _client.put(
      _uri(<String>['api', 'identity-trust', 'trusted-devices', device.studentId, device.deviceId]),
      headers: _headers,
      body: jsonEncode(device.toJson()),
    );
  }

  @override
  Future<void> saveFaceVerificationLog(FaceVerificationLog log) async {
    if (!isConfigured) return;
    await _client.post(
      _uri(<String>['api', 'identity-trust', 'verification-logs']),
      headers: _headers,
      body: jsonEncode(log.toJson()),
    );
  }

  Map<String, String> get _headers => <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config.accessToken}',
      };

  Uri _uri(List<String> segments) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments.where((segment) => segment.isNotEmpty);
    return base.replace(pathSegments: <String>[...baseSegments, ...segments]);
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, Object?>? _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return Map<String, Object?>.from(data);
      return Map<String, Object?>.from(decoded);
    }
    return null;
  }

  Map<String, Object?> _normalizeFaceProfile(Map<String, Object?> json) {
    return <String, Object?>{
      'id': json['id'],
      'studentId': json['studentId'] ?? json['student_id'],
      'faceEmbedding': json['faceEmbedding'] ?? json['face_embedding'],
      'modelVersion': json['modelVersion'] ?? json['model_version'],
      'captureCount': json['captureCount'] ?? json['capture_count'],
      'enrollmentStatus': json['enrollmentStatus'] ?? json['enrollment_status'],
      'createdAt': json['createdAt'] ?? json['created_at'],
      'updatedAt': json['updatedAt'] ?? json['updated_at'],
      'referenceImageUrl': json['referenceImageUrl'] ?? json['reference_image_url'],
    };
  }

  Map<String, Object?> _normalizeTrustedDevice(Map<String, Object?> json) {
    return <String, Object?>{
      'id': json['id'],
      'studentId': json['studentId'] ?? json['student_id'],
      'deviceId': json['deviceId'] ?? json['device_id'],
      'deviceType': json['deviceType'] ?? json['device_type'],
      'osName': json['osName'] ?? json['os_name'],
      'osVersion': json['osVersion'] ?? json['os_version'],
      'appVersion': json['appVersion'] ?? json['app_version'],
      'firstSeenAt': json['firstSeenAt'] ?? json['first_seen_at'],
      'lastSeenAt': json['lastSeenAt'] ?? json['last_seen_at'],
      'trustStatus': json['trustStatus'] ?? json['trust_status'],
      'lastFaceMatchScore': json['lastFaceMatchScore'] ?? json['last_face_match_score'],
    };
  }
}
