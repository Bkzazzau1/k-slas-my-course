Bundled model:

- `assets/ml_models/forbidden_devices_classifier.onnx`
- `assets/ml_models/vision_manifest.json`
- `assets/ml_models/vision_model_metrics.json`

The current ONNX file is a bootstrap classifier trained on synthetic grayscale
device silhouettes. It is enough to exercise real Rust-native inference end to
end, but it should be replaced with a production-trained model before relying
on it for strict exam enforcement.

Legacy Rust object model contract:

- Input tensor: `[1, 1, 128, 128]` float32, values normalized to `0..1`
- Output tensor: class probabilities aligned to `vision_manifest.json`
- Labels: `background`, `phone`, `laptop`

Production prohibited object detector path:

- `assets/ml_models/prohibited_object_detector.tflite`

Expected TFLite object detector contract:

- Preferred model family: EfficientDet-Lite0 / SSD MobileNet style detector
- Input tensor: `[1, 320, 320, 3]` float32, values normalized to `-1..1`
- Output 0: detection boxes as `[1, N, 4]`, using `[ymin, xmin, ymax, xmax]`
- Output 1: class indexes as `[1, N]`
- Output 2: confidence scores as `[1, N]`
- Output 3: detection count as `[1]`
- Default threshold: `0.55`
- Default maximum objects read: `8`
- Initial policy labels: `cell phone`, `book`, `laptop`, `calculator`, `tablet`,
  `earphones`, `headphones`, `paper notes`, `extra screen`

If `prohibited_object_detector.tflite` is missing or fails to load, the camera
monitor falls back to the Rust scan source. This keeps the exam flow alive while
still preventing false green approval.

Face detector model path:

- `assets/ml_models/face_detector.tflite`

Expected face detector contract:

- Input tensor: `[1, 128, 128, 3]` float32, values normalized to `-1..1`
- Output 0: MediaPipe/BlazeFace raw box regressors as `[1, 896, 16]`
- Output 1: MediaPipe/BlazeFace raw confidence logits as `[1, 896, 1]`
- Decoder: anchors are generated with front-camera strides `[8, 16, 16, 16]`,
  scores use sigmoid activation, and overlapping boxes are pruned with NMS.
- Default threshold: `0.55`
- Default maximum faces read: `4`

If `face_detector.tflite` is missing or fails to load, the Flutter camera
monitor falls back to the local frame-derived face source instead of blocking
the exam session.

To regenerate the bootstrap asset:

- Run `python tool/generate_bootstrap_vision_model.py`

If object model loading fails, the app falls back to the built-in Rust heuristic
detector instead of blocking the scan flow.
