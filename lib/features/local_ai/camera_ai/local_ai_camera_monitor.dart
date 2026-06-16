import 'dart:async';

import 'package:camera/camera.dart';

import '../core/local_ai_engine.dart';
import '../core/local_ai_event.dart';
import '../object_ai/camera_object_source.dart';
import '../object_ai/fallback_camera_object_source.dart';
import '../object_ai/object_detection_detector.dart';
import '../object_ai/rust_scan_camera_object_source.dart';
import '../object_ai/tflite_object_detection_source.dart';
import 'camera_face_source.dart';
import 'camera_frame_sampler.dart';
import 'face_presence_detector.dart';
import 'fallback_camera_face_source.dart';
import 'frame_heuristic_face_source.dart';
import 'model_backed_face_source.dart';
import 'tflite_face_model_connector.dart';

class LocalAiCameraMonitor {
  LocalAiCameraMonitor({
    required this.cameraController,
    required this.localAiEngine,
    CameraFaceSource? faceSource,
    FacePresenceDetector? faceDetector,
    CameraObjectSource? objectSource,
    ObjectDetectionDetector? objectDetector,
    CameraFrameSampler? sampler,
    this.onFrameAvailable,
  }) : faceSource = faceSource ?? _defaultFaceSource(),
       faceDetector = faceDetector ?? FacePresenceDetector(),
       objectSource = objectSource ?? _defaultObjectSource(),
       objectDetector = objectDetector ?? ObjectDetectionDetector(),
       sampler = sampler ?? CameraFrameSampler();

  final CameraController cameraController;
  final LocalAiEngine localAiEngine;
  final CameraFaceSource faceSource;
  final FacePresenceDetector faceDetector;
  final CameraObjectSource objectSource;
  final ObjectDetectionDetector objectDetector;
  final CameraFrameSampler sampler;
  final void Function(CameraImage image, DateTime timestamp)? onFrameAvailable;

  bool _running = false;
  bool _analyzing = false;
  DateTime? _faceMissingSince;

  bool get isRunning => _running;

  static CameraFaceSource _defaultFaceSource() {
    return FallbackCameraFaceSource(
      primary: ModelBackedFaceSource(connector: TfliteFaceModelConnector()),
      fallback: const FrameHeuristicFaceSource(),
    );
  }

  static CameraObjectSource _defaultObjectSource() {
    return FallbackCameraObjectSource(
      primary: TfliteObjectDetectionSource(),
      fallback: const RustScanCameraObjectSource(),
    );
  }

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
    if (!_running) return;
    onFrameAvailable?.call(image, now);
    if (_analyzing || !sampler.shouldProcess(now)) return;

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

      final faceEvents = await localAiEngine.runDetector(
        faceDetector,
        observation,
      );
      await _runObjectDetection(image: image, timestamp: now);

      await _handleImmediateCameraEvents(faceEvents);
    } finally {
      _analyzing = false;
    }
  }

  Future<void> _runObjectDetection({
    required CameraImage image,
    required DateTime timestamp,
  }) async {
    final observations = await objectSource.analyzeFrame(
      image: image,
      timestamp: timestamp,
    );
    for (final observation in observations) {
      final events = await localAiEngine.runDetector(objectDetector, observation);
      await _handleImmediateCameraEvents(events);
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
