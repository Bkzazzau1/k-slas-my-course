#!/usr/bin/env python3
"""Validate the K-SLAS prohibited object TFLite model contract.

Run from the Flutter project root after adding:

    assets/ml_models/prohibited_object_detector.tflite

Example:

    python tool/validate_prohibited_object_model.py

The script does not prove model accuracy. It only verifies that the file exists
and exposes the tensor contract expected by TfliteObjectDetectionSource.
"""

from __future__ import annotations

import json
from pathlib import Path
import sys

MODEL_PATH = Path("assets/ml_models/prohibited_object_detector.tflite")
MANIFEST_PATH = Path("assets/ml_models/prohibited_object_manifest.json")
LABELS_PATH = Path("assets/ml_models/prohibited_object_labels.txt")


def fail(message: str) -> int:
    print(f"ERROR: {message}")
    return 1


def main() -> int:
    if not MANIFEST_PATH.exists():
        return fail(f"Missing manifest: {MANIFEST_PATH}")
    if not LABELS_PATH.exists():
        return fail(f"Missing labels file: {LABELS_PATH}")
    if not MODEL_PATH.exists():
        return fail(
            f"Missing model: {MODEL_PATH}\n"
            "Add a real EfficientDet-Lite0 or SSD MobileNet-style TFLite model "
            "before relying on automatic material detection."
        )

    labels = [line.strip() for line in LABELS_PATH.read_text().splitlines() if line.strip()]
    if len(labels) < 2:
        return fail("Labels file must contain background plus at least one prohibited class.")

    manifest = json.loads(MANIFEST_PATH.read_text())
    expected_input = manifest.get("input", {}).get("shape")
    expected_dtype = manifest.get("input", {}).get("dtype")
    expected_outputs = manifest.get("outputs", [])

    try:
        from tflite_runtime.interpreter import Interpreter  # type: ignore
    except Exception:
        try:
            from ai_edge_litert.interpreter import Interpreter  # type: ignore
        except Exception:
            try:
                from tensorflow.lite.python.interpreter import Interpreter  # type: ignore
            except Exception:
                return fail(
                    "Install tflite-runtime, ai-edge-litert, or tensorflow to inspect the model.\n"
                    "Example: pip install ai-edge-litert"
                )

    interpreter = Interpreter(model_path=str(MODEL_PATH))
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    if not input_details:
        return fail("Model has no input tensor.")

    actual_input = list(input_details[0]["shape"])
    if expected_input and actual_input != expected_input:
        return fail(f"Input shape mismatch. Expected {expected_input}, got {actual_input}")

    actual_dtype = input_details[0]["dtype"].__name__
    if expected_dtype and actual_dtype != expected_dtype:
        return fail(f"Input dtype mismatch. Expected {expected_dtype}, got {actual_dtype}")

    if len(output_details) < 4:
        return fail(f"Model must expose at least 4 outputs. Found {len(output_details)}")

    print("K-SLAS prohibited object model contract check")
    print("------------------------------------------------")
    print(f"Model:  {MODEL_PATH}")
    print(f"Labels: {len(labels)} -> {', '.join(labels)}")
    print(f"Input:  {actual_input} dtype={input_details[0]['dtype']}")
    print("Outputs:")
    for index, detail in enumerate(output_details[:4]):
        expected_name = expected_outputs[index].get("name") if index < len(expected_outputs) else "unknown"
        print(f"  {index}: {expected_name} shape={list(detail['shape'])} dtype={detail['dtype']}")

    print("\nOK: tensor contract is structurally compatible.")
    print("Reminder: accuracy must still be validated with real exam-room images.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
