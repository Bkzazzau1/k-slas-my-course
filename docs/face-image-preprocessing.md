# Face Image Preprocessing Layer

The preprocessing layer is available at:

```text
lib/features/identity_trust/services/face_image_preprocessor.dart
```

## Purpose

This layer prepares camera image data before it reaches the local face embedding connector.

## Current MVP

The current implementation includes a pass-through preprocessor. It preserves the image bytes and attaches preprocessing metadata.

## Final target

The real implementation should:

1. Decode the camera image.
2. Detect the face region.
3. Align the face.
4. Resize to the model input size.
5. Normalize pixel values.
6. Return `FaceEmbeddingInput` for the TFLite or ONNX connector.

## Recommended model input

```text
112 x 112 RGB
mean 127.5
std 128.0
```
