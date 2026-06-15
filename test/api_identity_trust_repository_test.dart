import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_courses/data/services/course_catalog_service.dart';
import 'package:my_courses/features/identity_trust/services/api_identity_trust_repository.dart';

void main() {
  test('API repository fetches and normalizes face profile', () async {
    final repository = ApiIdentityTrustRepository(
      config: const CourseCatalogBackendConfig(
        apiBaseUrl: 'https://api.example.test',
        accessToken: 'token',
      ),
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(
          '''{
            "data": {
              "id": "face-1",
              "student_id": "KASU/CSC/001",
              "face_embedding": [1, 0, 0],
              "model_version": "demo-v1",
              "capture_count": 3,
              "enrollment_status": "active",
              "created_at": "2026-01-01T00:00:00.000Z",
              "updated_at": "2026-01-01T00:00:00.000Z"
            }
          }''',
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final profile = await repository.getFaceProfile('KASU/CSC/001');
    expect(profile?.studentId, 'KASU/CSC/001');
    expect(profile?.isActive, true);
    expect(profile?.faceEmbedding, const <double>[1, 0, 0]);
  });

  test('API repository returns null when not configured', () async {
    final repository = ApiIdentityTrustRepository(
      config: const CourseCatalogBackendConfig(apiBaseUrl: '', accessToken: ''),
    );

    final profile = await repository.getFaceProfile('KASU/CSC/001');
    expect(profile, isNull);
  });
}
