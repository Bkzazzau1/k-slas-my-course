# Local AI Calibration Samples

Place non-sensitive test images here to calibrate and regression-test the pre-exam room scan.

Do not add real student images. Use staged rooms, dummy props, or synthetic images.

Expected folders:

- `clean_room/`
- `phone_on_desk/`
- `book_paper_note/`
- `second_screen_tv/`
- `headphones_earpiece/`
- `calculator/`
- `another_person/`
- `dark_room/`
- `outdoor_public_space/`
- `vehicle/`
- `desk_lap_walls_ceiling_floor/`

Update `manifest.json` when adding images. Tests will read that manifest and run the local detector against any listed files.
