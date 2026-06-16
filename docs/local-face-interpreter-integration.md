# Local Face Interpreter Integration

The app now has a bridge-based local face embedding runner.

Core runner:

lib/features/identity_trust/services/flutter_face_embedding_runner.dart

Neutral bridge scaffold:

lib/features/identity_trust/services/external_face_interpreter_bridge.dart

## Current status

The bridge is intentionally isolated so the project can keep building while the real local inference package is added later.

## Integration target

When the runtime package is added, implement the bridge so it:

1. Loads assets/ml_models/mobilefacenet.tflite.
2. Accepts float input shaped as 1 x 112 x 112 x 3.
3. Runs the model.
4. Returns the output embedding shaped as 1 x 192.

## Connector path

Camera enrollment and exam start verification already call:

TfliteFaceEmbeddingConnector -> LocalFaceEmbeddingRunner -> FlutterFaceEmbeddingRunner -> bridge

## Pubspec note

A dependency for a Flutter-compatible local model runtime is still required before the bridge can perform real inference.
