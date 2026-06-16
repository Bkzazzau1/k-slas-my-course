Bundled model:

- `assets/ml_models/forbidden_devices_classifier.onnx`
- `assets/ml_models/vision_manifest.json`
- `assets/ml_models/vision_model_metrics.json`

The current ONNX file is a bootstrap classifier trained on synthetic grayscale
device silhouettes. It is enough to exercise real Rust-native inference end to
end, but it should be replaced with a production-trained model before relying
on it for strict exam enforcement.

Expected object model contract:

- Input tensor: `[1, 1, 128, 128]` float32, values normalized to `0..1`
- Output tensor: class probabilities aligned to `vision_manifest.json`
- Labels: `background`, `phone`, `laptop`

Face detector model path:

- `assets/ml_models/face_detector.tflite`

Expected face detector contract:

- Input tensor: `[1, 128, 128, 1]` float32, values normalized to `0..1`
- Output 0: boxes as `[1, N, 4]`, ordered `[ymin, xmin, ymax, xmax]`, normalized `0..1`
- Output 1: confidence scores as `[1, N]`
- Default threshold: `0.55`
- Default maximum faces read: `4`

If `face_detector.tflite` is missing or fails to load, the Flutter camera
monitor falls back to the local frame-derived face source instead of blocking
the exam session.

To regenerate the bootstrap asset:

- Run `python tool/generate_bootstrap_vision_model.py`

If object model loading fails, the app falls back to the built-in Rust heuristic
detector instead of blocking the scan flow.
