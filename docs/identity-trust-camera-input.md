# Identity Trust Camera Input Flow

The camera input provider is available at:

```text
lib/features/identity_trust/services/camera_face_embedding_input_provider.dart
```

It converts an initialized Flutter `CameraController` into a `FaceEmbeddingInput` for the face embedding connector.

## Current MVP flow

```text
CameraController
↓
takePicture()
↓
JPEG bytes
↓
FaceEmbeddingInput
↓
FaceEmbeddingConnector
↓
ModelLiveFaceEmbeddingSource
↓
ExamStartTrustService
```

## Example use

```dart
final liveSource = ModelLiveFaceEmbeddingSource(
  connector: YourRealFaceEmbeddingConnector(),
  inputProvider: CameraFaceEmbeddingInputProvider(
    cameraController: cameraController,
  ),
);

final trustService = ExamStartTrustService(
  repository: identityRepository,
  liveFaceEmbeddingSource: liveSource,
);
```

## Next implementation detail

The current provider sends JPEG bytes to the connector. The real connector must decode the image, detect/crop the face, resize it to the model input size, normalize pixel values, and generate the face embedding.
