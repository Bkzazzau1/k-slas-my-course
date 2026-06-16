# K-SLAS Prohibited Object Calibration Samples

Place real exam-room/webcam images into these folders before running calibration.

Recommended folders:

- `clean_desk/` — desk, face, keyboard, mouse, no cheating material
- `phone_visible/` — visible phone on desk, hand, chair, or side table
- `book_visible/` — book or textbook visible
- `laptop_extra/` — second laptop, monitor, or screen-like device
- `paper_notes/` — handwritten notes, printed paper, cheat sheet examples
- `calculator/` — calculator examples, because COCO may not detect calculators well
- `earphones/` — wired/wireless earphones, because COCO may not detect them well

Use realistic conditions:

- normal student webcam angle
- low/medium room lighting
- different desk colors
- phone partly hidden and fully visible
- objects near edge of frame
- clean desk samples from different rooms

Run from the Flutter project root:

```powershell
pip install ai-edge-litert pillow numpy
python tool\calibrate_prohibited_object_model.py
```

Reports are written to:

- `tool/calibration_reports/prohibited_object_calibration.csv`
- `tool/calibration_reports/prohibited_object_calibration.json`

Do not commit real student images. Use staged/non-sensitive test images only.
