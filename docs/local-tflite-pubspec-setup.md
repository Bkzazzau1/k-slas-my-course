# Local TFLite Pubspec Setup

Add this dependency locally under dependencies in pubspec.yaml:

```yaml
tflite_flutter: ^0.12.1
```

Then run:

```powershell
flutter pub get
```

The asset folder is already declared:

```yaml
assets:
  - assets/ml_models/
```

Keep the model at:

```text
assets/ml_models/mobilefacenet.tflite
```

Important desktop note:

Desktop builds may require TensorFlow Lite native dynamic libraries to be added manually. Android and iOS are simpler, but iOS should be tested on a real device rather than simulator.

Current app path after this setup:

FaceEmbeddingConnectorSelector -> TfliteFaceEmbeddingConnector -> FlutterFaceEmbeddingRunner -> ExternalFaceInterpreterBridge

After adding the package, replace the neutral bridge internals with the actual interpreter calls.
