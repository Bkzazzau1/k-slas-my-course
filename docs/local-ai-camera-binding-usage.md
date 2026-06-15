# Local AI Camera Binding Usage

The first camera binding is available at:

```text
lib/modules/proctoring/services/local_ai_camera_binding.dart
```

It connects an existing Flutter `CameraController` to the local AI engine and the existing proctoring controller.

## Basic use

Add a field to the screen state:

```dart
LocalAiCameraBinding? localAiCameraBinding;
```

After camera initialization:

```dart
localAiCameraBinding = LocalAiCameraBinding(
  proctoringController: proctoring,
);
await localAiCameraBinding!.attach(controller);
```

Before camera disposal:

```dart
await localAiCameraBinding?.detach();
localAiCameraBinding = null;
```

## Current status

The camera stream pipeline is now ready. The current face source is still a placeholder. The next implementation step is to replace it with a real on-device face model connector.
