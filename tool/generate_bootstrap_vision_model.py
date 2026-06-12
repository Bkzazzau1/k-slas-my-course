from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import onnx
from onnx import TensorProto, helper, numpy_helper


IMAGE_SIZE = 128
GRID_SIZE = 16
POOL_SIZE = IMAGE_SIZE // GRID_SIZE
CLASS_NAMES = ["background", "phone", "laptop"]
SEED = 20260325
TRAIN_SAMPLES_PER_CLASS = 900
VALIDATION_SAMPLES_PER_CLASS = 240
LEARNING_RATE = 0.9
EPOCHS = 420
L2 = 1e-4


@dataclass(frozen=True)
class DatasetSplit:
    features: np.ndarray
    labels: np.ndarray


def _clamp01(image: np.ndarray) -> np.ndarray:
    return np.clip(image, 0.0, 1.0)


def _gradient_background(rng: np.random.Generator) -> np.ndarray:
    base = rng.uniform(0.62, 0.9)
    noise = rng.normal(0.0, rng.uniform(0.025, 0.08), size=(IMAGE_SIZE, IMAGE_SIZE))
    x_grad = np.linspace(
        rng.uniform(-0.12, 0.12),
        rng.uniform(-0.12, 0.12),
        IMAGE_SIZE,
        dtype=np.float32,
    )
    y_grad = np.linspace(
        rng.uniform(-0.1, 0.1),
        rng.uniform(-0.1, 0.1),
        IMAGE_SIZE,
        dtype=np.float32,
    )
    image = base + noise + x_grad[None, :] + y_grad[:, None]

    for _ in range(int(rng.integers(0, 5))):
        h = int(rng.integers(6, 18))
        w = int(rng.integers(6, 20))
        x0 = int(rng.integers(0, IMAGE_SIZE - w))
        y0 = int(rng.integers(0, IMAGE_SIZE - h))
        shade = rng.uniform(-0.18, 0.12)
        image[y0 : y0 + h, x0 : x0 + w] += shade

    return _clamp01(image.astype(np.float32))


def _draw_box(
    image: np.ndarray,
    x0: int,
    y0: int,
    width: int,
    height: int,
    fill: float,
    border: float,
    inset_fill: float | None = None,
) -> None:
    x1 = min(IMAGE_SIZE, x0 + width)
    y1 = min(IMAGE_SIZE, y0 + height)
    image[y0:y1, x0:x1] = fill
    image[y0:y1, x0 : min(x0 + 2, x1)] = border
    image[y0:y1, max(x1 - 2, x0) : x1] = border
    image[y0 : min(y0 + 2, y1), x0:x1] = border
    image[max(y1 - 2, y0) : y1, x0:x1] = border
    if inset_fill is None or width < 8 or height < 8:
        return

    inset = 4
    ix0 = min(x1, x0 + inset)
    iy0 = min(y1, y0 + inset)
    ix1 = max(ix0, x1 - inset)
    iy1 = max(iy0, y1 - inset)
    image[iy0:iy1, ix0:ix1] = inset_fill


def _make_background_sample(rng: np.random.Generator) -> np.ndarray:
    image = _gradient_background(rng)
    for _ in range(int(rng.integers(0, 3))):
        radius = int(rng.integers(4, 14))
        cx = int(rng.integers(radius, IMAGE_SIZE - radius))
        cy = int(rng.integers(radius, IMAGE_SIZE - radius))
        yy, xx = np.ogrid[:IMAGE_SIZE, :IMAGE_SIZE]
        mask = (xx - cx) ** 2 + (yy - cy) ** 2 <= radius**2
        image[mask] = rng.uniform(0.18, 0.9)
    return _clamp01(image)


def _make_phone_sample(rng: np.random.Generator) -> np.ndarray:
    image = _gradient_background(rng)
    height = int(rng.integers(50, 88))
    width = int(height * rng.uniform(0.48, 0.68))
    x0 = int(rng.integers(8, IMAGE_SIZE - width - 8))
    y0 = int(rng.integers(6, IMAGE_SIZE - height - 6))
    border = rng.uniform(0.02, 0.16)
    fill = rng.uniform(0.08, 0.24)
    inset = rng.uniform(0.28, 0.58)
    _draw_box(image, x0, y0, width, height, fill=fill, border=border, inset_fill=inset)

    if rng.random() < 0.6:
        notch_w = max(6, width // 4)
        notch_h = max(3, height // 18)
        notch_x = x0 + (width - notch_w) // 2
        notch_y = y0 + 2
        image[notch_y : notch_y + notch_h, notch_x : notch_x + notch_w] = border

    if rng.random() < 0.55:
        shadow_w = int(width * rng.uniform(0.65, 0.95))
        shadow_h = max(3, int(height * rng.uniform(0.02, 0.05)))
        sx0 = x0 + (width - shadow_w) // 2
        sy0 = min(IMAGE_SIZE - shadow_h, y0 + height + int(rng.integers(1, 4)))
        image[sy0 : sy0 + shadow_h, sx0 : sx0 + shadow_w] *= rng.uniform(0.55, 0.82)

    return _clamp01(image)


def _make_laptop_sample(rng: np.random.Generator) -> np.ndarray:
    image = _gradient_background(rng)
    screen_w = int(rng.integers(54, 98))
    screen_h = int(screen_w / rng.uniform(1.45, 2.15))
    x0 = int(rng.integers(8, IMAGE_SIZE - screen_w - 8))
    y0 = int(rng.integers(30, min(78, IMAGE_SIZE - screen_h - 16)))
    border = rng.uniform(0.02, 0.18)
    fill = rng.uniform(0.08, 0.25)
    inset = rng.uniform(0.28, 0.6)
    _draw_box(
        image,
        x0,
        y0,
        screen_w,
        screen_h,
        fill=fill,
        border=border,
        inset_fill=inset,
    )

    base_h = max(8, int(screen_h * rng.uniform(0.28, 0.45)))
    base_w = min(IMAGE_SIZE - x0, int(screen_w * rng.uniform(1.05, 1.22)))
    base_x = max(2, x0 - (base_w - screen_w) // 2)
    base_y = min(IMAGE_SIZE - base_h - 2, y0 + screen_h - int(rng.integers(0, 2)))
    image[base_y : base_y + base_h, base_x : base_x + base_w] = rng.uniform(0.18, 0.42)
    keyboard_y = base_y + max(2, base_h // 3)
    image[keyboard_y : keyboard_y + 2, base_x : base_x + base_w] *= rng.uniform(0.4, 0.7)

    if rng.random() < 0.45:
        trackpad_w = max(8, base_w // 5)
        trackpad_h = max(4, base_h // 4)
        tx0 = base_x + (base_w - trackpad_w) // 2
        ty0 = min(IMAGE_SIZE - trackpad_h, base_y + base_h - trackpad_h - 2)
        image[ty0 : ty0 + trackpad_h, tx0 : tx0 + trackpad_w] *= rng.uniform(0.45, 0.75)

    return _clamp01(image)


def _sample_for_label(rng: np.random.Generator, label: int) -> np.ndarray:
    if label == 0:
        return _make_background_sample(rng)
    if label == 1:
        return _make_phone_sample(rng)
    return _make_laptop_sample(rng)


def _downsample(images: np.ndarray) -> np.ndarray:
    pooled = images.reshape((-1, GRID_SIZE, POOL_SIZE, GRID_SIZE, POOL_SIZE)).mean(axis=(2, 4))
    return pooled.reshape((images.shape[0], GRID_SIZE * GRID_SIZE)).astype(np.float32)


def _build_split(rng: np.random.Generator, samples_per_class: int) -> DatasetSplit:
    images = []
    labels = []
    for label in range(len(CLASS_NAMES)):
        for _ in range(samples_per_class):
            images.append(_sample_for_label(rng, label))
            labels.append(label)

    stacked = np.stack(images).astype(np.float32)
    label_array = np.asarray(labels, dtype=np.int64)
    indices = rng.permutation(len(label_array))
    features = _downsample(stacked[indices])
    return DatasetSplit(features=features, labels=label_array[indices])


def _softmax(logits: np.ndarray) -> np.ndarray:
    shifted = logits - logits.max(axis=1, keepdims=True)
    exp = np.exp(shifted)
    return exp / exp.sum(axis=1, keepdims=True)


def _train_softmax(split: DatasetSplit) -> tuple[np.ndarray, np.ndarray]:
    features = split.features
    labels = split.labels
    classes = len(CLASS_NAMES)
    one_hot = np.eye(classes, dtype=np.float32)[labels]

    weights = np.zeros((features.shape[1], classes), dtype=np.float32)
    bias = np.zeros((classes,), dtype=np.float32)

    for epoch in range(EPOCHS):
        logits = features @ weights + bias
        probabilities = _softmax(logits)
        error = (probabilities - one_hot) / features.shape[0]

        grad_w = features.T @ error + L2 * weights
        grad_b = error.sum(axis=0)
        lr = LEARNING_RATE * (0.55 if epoch > EPOCHS * 0.7 else 1.0)
        weights -= lr * grad_w
        bias -= lr * grad_b

    return weights.astype(np.float32), bias.astype(np.float32)


def _evaluate(split: DatasetSplit, weights: np.ndarray, bias: np.ndarray) -> dict[str, object]:
    probabilities = _softmax(split.features @ weights + bias)
    predictions = probabilities.argmax(axis=1)
    confusion = np.zeros((len(CLASS_NAMES), len(CLASS_NAMES)), dtype=np.int64)
    for truth, predicted in zip(split.labels, predictions, strict=True):
        confusion[int(truth), int(predicted)] += 1

    per_class_top = {}
    for index, class_name in enumerate(CLASS_NAMES):
        class_scores = probabilities[split.labels == index, index]
        per_class_top[class_name] = {
            "meanConfidence": float(class_scores.mean()),
            "p10Confidence": float(np.quantile(class_scores, 0.10)),
            "p50Confidence": float(np.quantile(class_scores, 0.50)),
        }

    return {
        "accuracy": float((predictions == split.labels).mean()),
        "confusionMatrix": confusion.tolist(),
        "confidenceByClass": per_class_top,
    }


def _write_onnx(model_path: Path, weights: np.ndarray, bias: np.ndarray) -> None:
    input_info = helper.make_tensor_value_info(
        "input",
        TensorProto.FLOAT,
        [1, 1, IMAGE_SIZE, IMAGE_SIZE],
    )
    output_info = helper.make_tensor_value_info(
        "probabilities",
        TensorProto.FLOAT,
        [1, len(CLASS_NAMES)],
    )

    nodes = [
        helper.make_node(
            "AveragePool",
            inputs=["input"],
            outputs=["pooled"],
            kernel_shape=[POOL_SIZE, POOL_SIZE],
            strides=[POOL_SIZE, POOL_SIZE],
        ),
        helper.make_node("Flatten", inputs=["pooled"], outputs=["flat"], axis=1),
        helper.make_node(
            "Gemm",
            inputs=["flat", "weights", "bias"],
            outputs=["logits"],
            transB=0,
        ),
        helper.make_node("Softmax", inputs=["logits"], outputs=["probabilities"], axis=1),
    ]

    graph = helper.make_graph(
        nodes=nodes,
        name="bootstrap_forbidden_device_classifier",
        inputs=[input_info],
        outputs=[output_info],
        initializer=[
            numpy_helper.from_array(weights.astype(np.float32), name="weights"),
            numpy_helper.from_array(bias.astype(np.float32), name="bias"),
        ],
    )
    model = helper.make_model(
        graph,
        producer_name="my_courses_bootstrap_model",
        opset_imports=[helper.make_opsetid("", 13)],
    )
    onnx.checker.check_model(model)
    model_path.parent.mkdir(parents=True, exist_ok=True)
    onnx.save(model, model_path)


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    model_dir = repo_root / "assets" / "ml_models"
    model_path = model_dir / "forbidden_devices_classifier.onnx"
    metrics_path = model_dir / "vision_model_metrics.json"

    rng = np.random.default_rng(SEED)
    train_split = _build_split(rng, TRAIN_SAMPLES_PER_CLASS)
    validation_split = _build_split(rng, VALIDATION_SAMPLES_PER_CLASS)

    weights, bias = _train_softmax(train_split)
    _write_onnx(model_path, weights, bias)

    metrics = {
        "seed": SEED,
        "imageSize": IMAGE_SIZE,
        "gridSize": GRID_SIZE,
        "classes": CLASS_NAMES,
        "trainingSamplesPerClass": TRAIN_SAMPLES_PER_CLASS,
        "validationSamplesPerClass": VALIDATION_SAMPLES_PER_CLASS,
        "train": _evaluate(train_split, weights, bias),
        "validation": _evaluate(validation_split, weights, bias),
    }
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    print(f"Wrote {model_path}")
    print(f"Wrote {metrics_path}")
    print(
        "Validation accuracy:",
        f"{metrics['validation']['accuracy']:.4f}",
    )


if __name__ == "__main__":
    main()
