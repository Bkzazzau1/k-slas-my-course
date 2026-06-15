# Camera Face Input

Use this provider when an initialized `CameraController` is available.

File:

```text
lib/features/identity_trust/services/preprocessed_camera_face_embedding_input_provider.dart
```

Import:

```dart
import 'package:my_courses/features/identity_trust/camera_identity_trust.dart';
```

Flow:

```text
Camera still image
JPEG bytes
Image preprocessor
JPEG decoder
RGB resize to 112 x 112
FaceEmbeddingInput
FaceEmbeddingConnector
ExamStartTrustService
```

Example:

```dart
final liveSource = ModelLiveFaceEmbeddingSource(
  connector: StaticFaceEmbeddingConnector(
    embedding: const <double>[1, 0, 0],
  ),
  inputProvider: PreprocessedCameraFaceEmbeddingInputProvider(
    cameraController: cameraController,
  ),
);
```

Replace the static connector with the real local model connector when inference is ready.
