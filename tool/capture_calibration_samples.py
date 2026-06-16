#!/usr/bin/env python3
"""Capture K-SLAS prohibited-object calibration images from a local webcam.

Examples:

    python tool/capture_calibration_samples.py --scenario clean_desk --count 10
    python tool/capture_calibration_samples.py --scenario phone_visible --count 10
    python tool/capture_calibration_samples.py --scenario book_visible --count 10

Keys while preview window is open:

    SPACE or C  capture current frame
    Q or ESC    quit

This tool is local-only. It does not upload images.
"""

from __future__ import annotations

import argparse
from datetime import datetime
from pathlib import Path
import sys
import time

SAMPLES_DIR = Path("tool/calibration_samples")
VALID_SCENARIOS = {
    "clean_desk",
    "phone_visible",
    "book_visible",
    "laptop_extra",
    "paper_notes",
    "calculator",
    "earphones",
}


def next_sample_path(scenario_dir: Path, scenario: str) -> Path:
    existing = sorted(scenario_dir.glob(f"{scenario}_*.jpg"))
    next_index = len(existing) + 1
    while True:
        candidate = scenario_dir / f"{scenario}_{next_index:03d}.jpg"
        if not candidate.exists():
            return candidate
        next_index += 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Capture webcam samples for K-SLAS object calibration.")
    parser.add_argument("--scenario", required=True, choices=sorted(VALID_SCENARIOS))
    parser.add_argument("--count", type=int, default=10)
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--delay", type=float, default=0.3, help="Seconds to wait after each capture.")
    parser.add_argument("--width", type=int, default=1280)
    parser.add_argument("--height", type=int, default=720)
    args = parser.parse_args()

    try:
        import cv2  # type: ignore
    except Exception:
        print("ERROR: opencv-python is required. Install it with:")
        print("  pip install opencv-python")
        return 1

    scenario_dir = SAMPLES_DIR / args.scenario
    scenario_dir.mkdir(parents=True, exist_ok=True)

    cap = cv2.VideoCapture(args.camera)
    if not cap.isOpened():
        print(f"ERROR: Could not open camera index {args.camera}")
        return 1

    cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)

    captured = 0
    print(f"Capturing scenario: {args.scenario}")
    print("Press SPACE/C to capture, Q/ESC to quit.")

    window_name = f"K-SLAS Calibration Capture - {args.scenario}"
    try:
        while captured < args.count:
            ok, frame = cap.read()
            if not ok:
                print("ERROR: Failed to read webcam frame.")
                break

            preview = frame.copy()
            cv2.putText(
                preview,
                f"{args.scenario}: {captured}/{args.count} captured",
                (20, 36),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.9,
                (0, 255, 0),
                2,
                cv2.LINE_AA,
            )
            cv2.putText(
                preview,
                "SPACE/C=capture  Q/ESC=quit",
                (20, 72),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (255, 255, 255),
                2,
                cv2.LINE_AA,
            )
            cv2.imshow(window_name, preview)
            key = cv2.waitKey(1) & 0xFF

            if key in (27, ord("q"), ord("Q")):
                break
            if key in (32, ord("c"), ord("C")):
                out_path = next_sample_path(scenario_dir, args.scenario)
                stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
                cv2.imwrite(str(out_path), frame)
                captured += 1
                print(f"[{captured}/{args.count}] saved {out_path} at {stamp}")
                time.sleep(args.delay)
    finally:
        cap.release()
        cv2.destroyAllWindows()

    print(f"Done. Captured {captured} image(s) in {scenario_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
