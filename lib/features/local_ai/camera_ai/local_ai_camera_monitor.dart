import 'dart:async';

import 'package:camera/camera.dart';

import '../core/local_ai_engine.dart';
import '../core/local_ai_event.dart';
import 'camera_face_source.dart';
import 'camera_frame_sampler.dart';
import 'face_presence_detector.dart';

class LocalAiCameraMonitor {
  LocalAiCameraMonitor({
    required this.cameraController,
    required this.localAiEngine,
    CameraFaceSource? faceSource,
    FacePresenceDetector? faceDetector,
    CameraFrameSampler? sampler,
  })  : faceSource = faceSource ?? const PlaceholderCameraFaceSource(),
        faceDetector = faceDetector ?? FacePresenceDetector(),
        sampler = sampler ?? CameraFrameSampler();

  final CameraController cameraController;
  final LocalAiEngine localAiEngine;
  final CameraFaceSource faceSource;
  final FacePresenceDetector faceDetector;
  final CameraFrameSampler sampler;

  bool _running = false;
  bool _analyzing = false;
  DateTime? _faceMissingSince;

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    if (!cameraController.value.isInitialized) {
      throw StateError('Camera controller is not initialized.');
    }

    _running = true;
    await cameraController.startImageStream(_onFrame);
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    sampler.reset();
    _faceMissingSince = null;

    try {
      if (cameraController.value.isStreamingImages) {
        await cameraController.stopImageStream();
      }
    } catch (_) {
      // Some camera backends throw if the stream has already stopped.
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final now = DateTime.now();
    if (!_running || _analyzing || !sampler.shouldProcess(now)) return;

    _analyzing = true;
    try {
      final missingSeconds = _faceMissingSince == null
          ? 0
          : now.difference(_faceMissingSince!).inSeconds;

      final observation = await faceSource.analyzeFrame(
        image: image,
        timestamp: now,
        faceMissingDurationSeconds: missingSeconds,
      );

      if (observation.hasFace) {
        _faceMissingSince = null;
      } else {
        _faceMissingSince ??= now;
      }

      final events = await localAiEngine.runDetector(
        faceDetector,
        observation,
      );

      await _handleImmediateCameraEvents(events);
    } finally {
      _analyzing = false;
    }
  }

  Future<void> _handleImmediateCameraEvents(List<LocalAiEvent> events) async {
    // Hook point for evidence capture or native alerts.
    // Dashboard integration should listen to localAiEngine.events instead.
    for (final event in events) {
      if (event.shouldAlertInvigilator) {
        // Keep this empty for now so the detector remains reusable and testable.
      }
    }
  }
}
