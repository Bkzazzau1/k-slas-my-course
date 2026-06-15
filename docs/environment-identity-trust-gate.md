# Environment Identity Trust Gate

File:

```text
lib/modules/proctoring/services/environment_identity_trust_gate.dart
```

## Purpose

This service runs face identity and trusted-device verification from the room-scan overlay, where the live `CameraController` already exists.

## Behavior

If identity trust services are registered in GetX:

```text
IdentityTrustRepository
FaceEmbeddingConnector
```

then the gate runs:

```text
CameraController
ExamStartIdentityOrchestrator
ExamStartTrustService
allow / review / block
```

If the services are not registered yet, the gate allows the current room-scan flow to continue. This keeps the existing demo working while the real backend/model services are still being connected.

## Overlay usage

Inside `_startExam()` before `completeEnvironmentScan()`:

```dart
final gate = const EnvironmentIdentityTrustGate();
final result = await gate.verify(
  proctoring: proctoring,
  cameraController: camera!,
);

if (!result.allowed) {
  setState(() => startingExam = false);
  return;
}
```
