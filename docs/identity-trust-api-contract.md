# Identity Trust API Contract

Frontend repository:

```text
lib/features/identity_trust/services/api_identity_trust_repository.dart
```

The repository uses `CourseCatalogBackendConfig.fromRuntime()` for:

```text
apiBaseUrl
accessToken
```

Authorization header:

```text
Authorization: Bearer <accessToken>
```

## Endpoints

### Get student face profile

```http
GET /api/identity-trust/face-profiles/{studentId}
```

Response can be direct JSON or wrapped in `data`.

Expected fields:

```json
{
  "id": "face-1",
  "student_id": "KASU/CSC/001",
  "face_embedding": [1, 0, 0],
  "model_version": "mobilefacenet-v1",
  "capture_count": 3,
  "enrollment_status": "active",
  "created_at": "2026-01-01T00:00:00.000Z",
  "updated_at": "2026-01-01T00:00:00.000Z",
  "reference_image_url": null
}
```

The frontend also accepts camelCase keys.

### Save student face profile

```http
PUT /api/identity-trust/face-profiles/{studentId}
```

Body is `StudentFaceProfile.toJson()`.

### Get trusted device

```http
GET /api/identity-trust/trusted-devices/{studentId}/{deviceId}
```

Expected fields:

```json
{
  "id": "device-1",
  "student_id": "KASU/CSC/001",
  "device_id": "abc123",
  "device_type": "desktop_or_laptop",
  "os_name": "windows",
  "os_version": "11",
  "app_version": "1.0.0",
  "first_seen_at": "2026-01-01T00:00:00.000Z",
  "last_seen_at": "2026-01-01T00:00:00.000Z",
  "trust_status": "trusted",
  "last_face_match_score": 0.91
}
```

### Save trusted device

```http
PUT /api/identity-trust/trusted-devices/{studentId}/{deviceId}
```

Body is `StudentTrustedDevice.toJson()`.

### Save verification log

```http
POST /api/identity-trust/verification-logs
```

Body is `FaceVerificationLog.toJson()`.
