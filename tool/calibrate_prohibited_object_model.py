#!/usr/bin/env python3
"""Run local calibration for the K-SLAS prohibited object detector.

Place real exam-room test images under:

    tool/calibration_samples/<scenario_name>/*.jpg|*.png|*.jpeg|*.webp

Then run:

    python tool/calibrate_prohibited_object_model.py

The script writes:

    tool/calibration_reports/prohibited_object_calibration.csv
    tool/calibration_reports/prohibited_object_calibration.json

This is a local-only calibration helper. It does not upload images or use cloud AI.
"""

from __future__ import annotations

import argparse
import csv
import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np
from PIL import Image

DEFAULT_MODEL = Path("assets/ml_models/prohibited_object_detector.tflite")
DEFAULT_LABELS = Path("assets/ml_models/prohibited_object_labels.txt")
DEFAULT_MANIFEST = Path("assets/ml_models/prohibited_object_manifest.json")
DEFAULT_SAMPLES = Path("tool/calibration_samples")
DEFAULT_REPORTS = Path("tool/calibration_reports")

IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

PROHIBITED_LABELS = {"cell phone"}
MANUAL_REVIEW_LABELS = {
    "backpack",
    "book",
    "bottle",
    "cup",
    "handbag",
    "keyboard",
    "knife",
    "laptop",
    "mouse",
    "remote",
    "scissors",
    "suitcase",
    "tv",
}
ALLOWED_LABELS = {"???", "background", "none", "clean", "person", "chair", "dining table"}


@dataclass
class DetectionRecord:
    scenario: str
    image: str
    label: str
    confidence: float
    policy: str
    x: float
    y: float
    width: float
    height: float


@dataclass
class ScenarioSummary:
    scenario: str
    image_count: int
    detection_count: int
    high_risk_count: int
    manual_review_count: int
    ignored_count: int
    top_labels: dict[str, int]


def load_interpreter_class():
    try:
        from tflite_runtime.interpreter import Interpreter  # type: ignore

        return Interpreter
    except Exception:
        try:
            from ai_edge_litert.interpreter import Interpreter  # type: ignore

            return Interpreter
        except Exception:
            try:
                from tensorflow.lite.python.interpreter import Interpreter  # type: ignore

                return Interpreter
            except Exception as exc:
                raise RuntimeError(
                    "Install tflite-runtime, ai-edge-litert, or tensorflow. "
                    "Recommended on Windows: pip install ai-edge-litert"
                ) from exc


def load_labels(path: Path) -> list[str]:
    return [line.strip() for line in path.read_text().splitlines() if line.strip()]


def load_manifest(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text())


def image_paths(samples_dir: Path) -> list[Path]:
    return sorted(
        path
        for path in samples_dir.rglob("*")
        if path.is_file() and path.suffix.lower() in IMAGE_EXTENSIONS
    )


def preprocess_image(path: Path, input_shape: list[int], dtype: np.dtype, normalization: str) -> np.ndarray:
    if len(input_shape) != 4:
        raise ValueError(f"Expected 4D input shape, got {input_shape}")
    _, height, width, channels = input_shape
    if channels != 3:
        raise ValueError(f"Expected 3-channel RGB input, got {channels}")

    image = Image.open(path).convert("RGB").resize((width, height))
    array = np.asarray(image)

    if dtype == np.uint8:
        return np.expand_dims(array.astype(np.uint8), axis=0)

    array = array.astype(np.float32)
    if normalization == "-1..1":
        array = (array / 127.5) - 1.0
    elif normalization == "0..1":
        array = array / 255.0
    return np.expand_dims(array.astype(dtype), axis=0)


def squeeze_first(value: np.ndarray) -> np.ndarray:
    if value.ndim > 0 and value.shape[0] == 1:
        return value[0]
    return value


def label_for_class(labels: list[str], class_id: float) -> str:
    index = int(round(float(class_id)))
    if index < 0 or index >= len(labels):
        return f"unknown:{index}"
    return labels[index]


def policy_for(label: str, confidence: float, phone_threshold: float, manual_threshold: float) -> str:
    normalized = label.strip().lower()
    if normalized in ALLOWED_LABELS:
        return "ignored"
    if normalized in PROHIBITED_LABELS:
        return "high_risk" if confidence >= phone_threshold else "manual_review"
    if normalized in MANUAL_REVIEW_LABELS:
        return "manual_review" if confidence >= manual_threshold else "ignored"
    return "ignored"


def decode_outputs(
    image_path: Path,
    scenario: str,
    labels: list[str],
    outputs: list[np.ndarray],
    original_size: tuple[int, int],
    score_threshold: float,
    phone_threshold: float,
    manual_threshold: float,
) -> list[DetectionRecord]:
    if len(outputs) < 4:
        raise ValueError(f"Expected at least 4 outputs, got {len(outputs)}")

    boxes = squeeze_first(outputs[0])
    classes = squeeze_first(outputs[1])
    scores = squeeze_first(outputs[2])
    count_raw = squeeze_first(outputs[3])

    if count_raw.size:
        count = int(round(float(np.ravel(count_raw)[0])))
    else:
        count = len(scores)
    count = max(0, min(count, len(scores), len(classes), len(boxes)))

    image_width, image_height = original_size
    records: list[DetectionRecord] = []
    for index in range(count):
        confidence = float(scores[index])
        if confidence < score_threshold:
            continue

        label = label_for_class(labels, float(classes[index]))
        box = boxes[index]
        if len(box) < 4:
            continue

        ymin = float(np.clip(box[0], 0.0, 1.0))
        xmin = float(np.clip(box[1], 0.0, 1.0))
        ymax = float(np.clip(box[2], 0.0, 1.0))
        xmax = float(np.clip(box[3], 0.0, 1.0))
        width = max(0.0, (xmax - xmin) * image_width)
        height = max(0.0, (ymax - ymin) * image_height)
        if width <= 1 or height <= 1:
            continue

        policy = policy_for(label, confidence, phone_threshold, manual_threshold)
        records.append(
            DetectionRecord(
                scenario=scenario,
                image=str(image_path),
                label=label,
                confidence=round(confidence, 4),
                policy=policy,
                x=round(xmin * image_width, 2),
                y=round(ymin * image_height, 2),
                width=round(width, 2),
                height=round(height, 2),
            )
        )

    return records


def summarize(records: list[DetectionRecord], images: list[Path], samples_dir: Path) -> list[ScenarioSummary]:
    scenario_to_images: dict[str, set[str]] = {}
    for image in images:
        scenario = image.relative_to(samples_dir).parts[0] if image.parent != samples_dir else "root"
        scenario_to_images.setdefault(scenario, set()).add(str(image))

    scenario_to_records: dict[str, list[DetectionRecord]] = {}
    for record in records:
        scenario_to_records.setdefault(record.scenario, []).append(record)

    summaries: list[ScenarioSummary] = []
    for scenario in sorted(scenario_to_images):
        scenario_records = scenario_to_records.get(scenario, [])
        top_labels: dict[str, int] = {}
        for record in scenario_records:
            top_labels[record.label] = top_labels.get(record.label, 0) + 1
        summaries.append(
            ScenarioSummary(
                scenario=scenario,
                image_count=len(scenario_to_images[scenario]),
                detection_count=len(scenario_records),
                high_risk_count=sum(1 for item in scenario_records if item.policy == "high_risk"),
                manual_review_count=sum(1 for item in scenario_records if item.policy == "manual_review"),
                ignored_count=sum(1 for item in scenario_records if item.policy == "ignored"),
                top_labels=dict(sorted(top_labels.items(), key=lambda item: item[1], reverse=True)),
            )
        )
    return summaries


def write_reports(records: list[DetectionRecord], summaries: list[ScenarioSummary], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    csv_path = out_dir / "prohibited_object_calibration.csv"
    json_path = out_dir / "prohibited_object_calibration.json"

    with csv_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(asdict(records[0]).keys()) if records else [
            "scenario", "image", "label", "confidence", "policy", "x", "y", "width", "height"
        ])
        writer.writeheader()
        for record in records:
            writer.writerow(asdict(record))

    payload = {
        "summary": [asdict(summary) for summary in summaries],
        "detections": [asdict(record) for record in records],
    }
    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    print(f"Wrote: {csv_path}")
    print(f"Wrote: {json_path}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Calibrate K-SLAS prohibited object detector locally.")
    parser.add_argument("--model", type=Path, default=DEFAULT_MODEL)
    parser.add_argument("--labels", type=Path, default=DEFAULT_LABELS)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--samples", type=Path, default=DEFAULT_SAMPLES)
    parser.add_argument("--out", type=Path, default=DEFAULT_REPORTS)
    parser.add_argument("--score-threshold", type=float, default=0.25)
    parser.add_argument("--phone-threshold", type=float, default=0.65)
    parser.add_argument("--manual-threshold", type=float, default=0.45)
    args = parser.parse_args()

    if not args.model.exists():
        raise FileNotFoundError(f"Missing model: {args.model}")
    if not args.labels.exists():
        raise FileNotFoundError(f"Missing labels: {args.labels}")
    if not args.samples.exists():
        raise FileNotFoundError(f"Missing samples folder: {args.samples}")

    images = image_paths(args.samples)
    if not images:
        print(f"No images found under {args.samples}")
        print("Add .jpg/.png/.webp images to scenario folders and rerun.")
        return 0

    manifest = load_manifest(args.manifest)
    labels = load_labels(args.labels)
    normalization = manifest.get("input", {}).get("normalization", "0..255")

    Interpreter = load_interpreter_class()
    interpreter = Interpreter(model_path=str(args.model))
    interpreter.allocate_tensors()

    input_details = interpreter.get_input_details()[0]
    output_details = interpreter.get_output_details()
    input_shape = list(input_details["shape"])
    input_dtype = input_details["dtype"]

    all_records: list[DetectionRecord] = []
    for image_path in images:
        scenario = image_path.relative_to(args.samples).parts[0] if image_path.parent != args.samples else "root"
        with Image.open(image_path) as image:
            original_size = image.size
        input_tensor = preprocess_image(image_path, input_shape, input_dtype, normalization)
        interpreter.set_tensor(input_details["index"], input_tensor)
        interpreter.invoke()
        outputs = [interpreter.get_tensor(detail["index"]) for detail in output_details[:4]]
        all_records.extend(
            decode_outputs(
                image_path=image_path,
                scenario=scenario,
                labels=labels,
                outputs=outputs,
                original_size=original_size,
                score_threshold=args.score_threshold,
                phone_threshold=args.phone_threshold,
                manual_threshold=args.manual_threshold,
            )
        )

    summaries = summarize(all_records, images, args.samples)
    write_reports(all_records, summaries, args.out)

    print("\nScenario summary")
    print("----------------")
    for summary in summaries:
        print(
            f"{summary.scenario}: images={summary.image_count}, detections={summary.detection_count}, "
            f"high_risk={summary.high_risk_count}, manual_review={summary.manual_review_count}, "
            f"ignored={summary.ignored_count}, top={summary.top_labels}"
        )

    print("\nPolicy reminder: phone can be high risk; book/paper-like materials should go to human review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
