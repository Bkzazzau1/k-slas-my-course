import 'package:camera/camera.dart';

import '../controller/proctoring_controller.dart';
import 'local_ai_camera_binding.dart';

/// Owns the camera and local monitoring binding for one live exam route.
///
/// This runtime never sends frames to a cloud model. The camera stream is
/// consumed by the existing on-device [LocalAiCameraBinding].
abstract interface class LiveExamCameraRuntime {
  bool get isActive;

  Future<bool> start();

  Future<void> stop();
}

class LocalLiveExamCameraRuntime implements LiveExamCameraRuntime {
  LocalLiveExamCameraRuntime({
    required this.proctoringController,
    Future<List<CameraDescription>> Function()? cameraDiscovery,
  }) : _cameraDiscovery = cameraDiscovery ?? availableCameras;

  final ProctoringController proctoringController;
  final Future<List<CameraDescription>> Function() _cameraDiscovery;

  CameraController? _cameraController;
  LocalAiCameraBinding? _binding;
  bool _starting = false;

  @override
  bool get isActive {
    final controller = _cameraController;
    return (_binding?.isActive ?? false) &&
        controller != null &&
        controller.value.isInitialized &&
        controller.value.isStreamingImages;
  }

  @override
  Future<bool> start() async {
    if (isActive) return true;
    if (_starting) return false;
    _starting = true;

    CameraController? openingController;
    LocalAiCameraBinding? openingBinding;
    try {
      await stop();
      final cameras = await _cameraDiscovery();
      if (cameras.isEmpty) return false;

      final selected = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      openingController = controller;
      await controller.initialize();

      final binding = LocalAiCameraBinding(
        proctoringController: proctoringController,
      );
      openingBinding = binding;
      await binding.attach(controller);

      if (!binding.isActive || !controller.value.isStreamingImages) {
        await binding.detach();
        await controller.dispose();
        return false;
      }

      _cameraController = controller;
      _binding = binding;
      openingController = null;
      openingBinding = null;
      return true;
    } catch (_) {
      try {
        await openingBinding?.detach();
      } catch (_) {}
      try {
        await openingController?.dispose();
      } catch (_) {}
      return false;
    } finally {
      _starting = false;
    }
  }

  @override
  Future<void> stop() async {
    final binding = _binding;
    final controller = _cameraController;
    _binding = null;
    _cameraController = null;

    try {
      await binding?.detach();
    } catch (_) {}
    try {
      await controller?.dispose();
    } catch (_) {}
  }
}
