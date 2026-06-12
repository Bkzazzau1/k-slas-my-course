Bundled model:

- `assets/ml_models/forbidden_devices_classifier.onnx`
- `assets/ml_models/vision_manifest.json`
- `assets/ml_models/vision_model_metrics.json`

The current ONNX file is a bootstrap classifier trained on synthetic grayscale
device silhouettes. It is enough to exercise real Rust-native inference end to
end, but it should be replaced with a production-trained model before relying
on it for strict exam enforcement.

Expected model contract:

- Input tensor: `[1, 1, 128, 128]` float32, values normalized to `0..1`
- Output tensor: class probabilities aligned to `vision_manifest.json`
- Labels: `background`, `phone`, `laptop`

To regenerate the bootstrap asset:

- Run `python tool/generate_bootstrap_vision_model.py`

If model loading fails, the app falls back to the built-in Rust heuristic
detector instead of blocking the scan flow.
