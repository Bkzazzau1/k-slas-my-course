# Exam Start Identity Orchestrator

The orchestrator is available at:

```text
lib/modules/proctoring/services/exam_start_identity_orchestrator.dart
```

## Purpose

It connects the exam-start gateway to the identity trust system.

## Flow

```text
ExamStartDialog
CameraController
PreprocessedCameraFaceEmbeddingInputProvider
ModelLiveFaceEmbeddingSource
ExamStartTrustService
allow / review / block
```

## Student identity source

The orchestrator uses `StudentProfileStorage.load()` to resolve the current student ID.

Priority:

```text
matricNo
email
empty result if neither exists
```

## Example

```dart
final orchestrator = ExamStartIdentityOrchestrator(
  repository: identityRepository,
  connector: StaticFaceEmbeddingConnector(
    embedding: const <double>[1, 0, 0],
  ),
);

final decision = await orchestrator.verify(
  ExamStartIdentityRequest(
    examId: examId,
    sessionId: sessionId,
    isHighStakesExam: true,
    cameraController: cameraController,
  ),
);

if (decision.canStartExam) {
  // Continue exam startup.
} else if (decision.reviewRequired) {
  // Send to invigilator/manual review.
} else {
  // Block startup.
}
```

Replace the static connector with the real TFLite or ONNX connector after local inference is implemented.
