# Face Embedding Model Connectors

The identity trust module now has connector scaffolds for local face recognition models.

## TFLite connector

Path:

```text
lib/features/identity_trust/services/tflite_face_embedding_connector.dart
```

Default model asset:

```text
assets/ml_models/mobilefacenet.tflite
```

Best for Android, iOS, tablets, and edge inference.

## ONNX connector

Path:

```text
lib/features/identity_trust/services/onnx_face_embedding_connector.dart
```

Default model asset:

```text
assets/ml_models/mobilefacenet.onnx
```

Best for Windows and future native desktop integration.

## Current status

Both connectors currently define configuration and class structure only. They return an empty embedding until a runtime package is selected and inference is implemented.

## Next work

Decode the camera image, crop the face, resize to the model input size, normalize pixels, run inference, normalize the output embedding, and return the result to `ExamStartTrustService`.
