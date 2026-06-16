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

Active prohibited object detector path:

- `assets/ml_models/prohibited_object_detector.tflite`
- `assets/ml_models/prohibited_object_labels.txt`
- `assets/ml_models/prohibited_object_manifest.json`

Installed TFLite object detector contract:

- Model family: TensorFlow Hub EfficientDet-Lite0 COCO detector
- Input tensor: `[1, 320, 320, 3]` uint8, values `0..255`
- Output 0: detection boxes as `[1, N, 4]`, using `[ymin, xmin, ymax, xmax]`
- Output 1: class indexes as `[1, N]`
- Output 2: confidence scores as `[1, N]`
- Output 3: detection count as `[1]`
- Default threshold: `0.55`
- Default maximum objects read: `8`
- High-risk policy label: `cell phone`
- Manual-review policy labels: `book`, `laptop`, `keyboard`, `mouse`, `remote`,
  `tv`, `backpack`, `handbag`, `suitcase`, `bottle`, `cup`, `scissors`
- Custom KSLAS training is still required for reliable `calculator`,
  `paper notes`, `earphones`, `headphones`, `tablet`, and partially hidden object
  detection because those are not direct COCO classes in the installed baseline.

If `prohibited_object_detector.tflite` is missing or fails to load, the camera
monitor falls back to the Rust scan source. This keeps the exam flow alive while
still preventing false green approval.

Local activation steps:

1. Confirm the model output contract:

   `python tool/validate_prohibited_object_model.py`

2. Run Flutter checks:

   `flutter analyze`

   `flutter test test/features/local_ai/object_ai/tflite_object_detection_source_test.dart`

   `flutter test test/features/local_ai/object_ai/fallback_camera_object_source_test.dart`

3. Calibrate using real exam-room images before strict enforcement.

Minimum calibration targets before production enforcement:

- Clean desk false positive rate should be low enough for invigilator review.
- Phone detection should be reliable under typical webcam lighting.
- Book/paper/notes should trigger manual review, not automatic punishment.
- Every high-risk object event must have camera-frame evidence attached.

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
