import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class CameraScanFrame {
  const CameraScanFrame({
    required this.mode,
    required this.timestamp,
    required this.luma,
    required this.signature,
    this.cameraImage,
    this.decodedImage,
  });

  final String mode;
  final DateTime timestamp;
  final double luma;
  final List<int> signature;
  final CameraImage? cameraImage;
  final img.Image? decodedImage;
}

abstract class CameraScanFrameSource {
  Future<void> start({
    required CameraController controller,
    required bool Function() shouldContinue,
    required Future<void> Function(CameraScanFrame frame) onFrame,
    required void Function(String message) onStatus,
  });

  Future<void> stop(CameraController? controller);
}

class DefaultCameraScanFrameSource implements CameraScanFrameSource {
  DefaultCameraScanFrameSource({
    this.stillCaptureInterval = const Duration(milliseconds: 1400),
    this.initialStillCaptureDelay = const Duration(milliseconds: 500),
  });

  final Duration stillCaptureInterval;
  final Duration initialStillCaptureDelay;

  Timer? _stillTimer;
  bool _active = false;
  bool _processingFrame = false;
  Future<void> Function(CameraScanFrame frame)? _onFrame;
  bool Function()? _shouldContinue;
  void Function(String message)? _onStatus;

  @override
  Future<void> start({
    required CameraController controller,
    required bool Function() shouldContinue,
    required Future<void> Function(CameraScanFrame frame) onFrame,
    required void Function(String message) onStatus,
  }) async {
    await stop(controller);
    _active = true;
    _processingFrame = false;
    _onFrame = onFrame;
    _shouldContinue = shouldContinue;
    _onStatus = onStatus;

    if (_shouldUseStillCaptureFirst) {
      _startStillCapture(controller);
      return;
    }

    try {
      await controller.startImageStream(_handleLiveFrame);
      onStatus('live-frame');
    } catch (_) {
      onStatus('stream-unavailable');
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!_isUsable) return;
      _startStillCapture(controller);
    }
  }

  @override
  Future<void> stop(CameraController? controller) async {
    _stillTimer?.cancel();
    _stillTimer = null;
    _active = false;
    _processingFrame = false;
    _onFrame = null;
    _shouldContinue = null;
    _onStatus = null;

    if (controller == null || !controller.value.isInitialized) return;
    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
    } catch (_) {}
  }

  bool get _shouldUseStillCaptureFirst {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get _isUsable => _active && (_shouldContinue?.call() ?? false);

  void _startStillCapture(CameraController controller) {
    _onStatus?.call('still-frame');
    _stillTimer?.cancel();
    _stillTimer = Timer.periodic(stillCaptureInterval, (_) {
      unawaited(_captureStillFrame(controller));
    });
    Future<void>.delayed(initialStillCaptureDelay, () {
      if (_isUsable) unawaited(_captureStillFrame(controller));
    });
  }

  Future<void> _captureStillFrame(CameraController controller) async {
    if (!_isUsable || _processingFrame || !controller.value.isInitialized) {
      return;
    }

    _processingFrame = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        _onStatus?.call('still-frame-unreadable');
        return;
      }

      await _onFrame?.call(
        CameraScanFrame(
          mode: 'still-frame',
          timestamp: DateTime.now(),
          luma: _averageDecodedLuma(decoded),
          signature: _decodedFrameSignature(decoded),
          decodedImage: decoded,
        ),
      );
    } catch (error) {
      _onStatus?.call(
        'still-frame-busy: Camera is busy; the app will keep retrying. $error',
      );
    } finally {
      _processingFrame = false;
    }
  }

  void _handleLiveFrame(CameraImage image) {
    if (!_isUsable || _processingFrame) return;
    _processingFrame = true;
    unawaited(_processLiveFrame(image));
  }

  Future<void> _processLiveFrame(CameraImage image) async {
    try {
      await _onFrame?.call(
        CameraScanFrame(
          mode: 'live-frame',
          timestamp: DateTime.now(),
          luma: _averageLuma(image),
          signature: _frameSignature(image),
          cameraImage: image,
        ),
      );
    } finally {
      _processingFrame = false;
    }
  }

  double _averageLuma(CameraImage image) {
    if (image.planes.isEmpty || image.planes.first.bytes.isEmpty) return 0.5;
    final bytes = image.planes.first.bytes;
    final step = math.max(1, bytes.length ~/ 600);
    var total = 0;
    var count = 0;
    for (var i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }
    if (count == 0) return 0.5;
    return (total / count / 255).clamp(0.0, 1.0);
  }

  List<int> _frameSignature(CameraImage image) {
    if (image.planes.isEmpty || image.planes.first.bytes.isEmpty) {
      return const <int>[128];
    }
    final bytes = image.planes.first.bytes;
    const buckets = 48;
    final signature = <int>[];
    for (var bucket = 0; bucket < buckets; bucket++) {
      final start = (bytes.length * bucket / buckets).floor();
      final end = (bytes.length * (bucket + 1) / buckets).floor();
      if (end <= start) {
        signature.add(bytes[start.clamp(0, bytes.length - 1)]);
        continue;
      }
      var total = 0;
      var count = 0;
      final step = math.max(1, (end - start) ~/ 12);
      for (var i = start; i < end; i += step) {
        total += bytes[i];
        count++;
      }
      signature.add(count == 0 ? 128 : (total / count).round());
    }
    return signature;
  }

  double _averageDecodedLuma(img.Image image) {
    final stepX = math.max(1, image.width ~/ 24);
    final stepY = math.max(1, image.height ~/ 24);
    var total = 0.0;
    var count = 0;
    for (var y = 0; y < image.height; y += stepY) {
      for (var x = 0; x < image.width; x += stepX) {
        final pixel = image.getPixel(x, y);
        total += (pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114);
        count++;
      }
    }
    if (count == 0) return 0.5;
    return (total / count / 255).clamp(0.0, 1.0);
  }

  List<int> _decodedFrameSignature(img.Image image) {
    const buckets = 48;
    final signature = <int>[];
    for (var bucket = 0; bucket < buckets; bucket++) {
      final x = ((bucket % 8) + 0.5) * image.width / 8;
      final y = ((bucket ~/ 8) + 0.5) * image.height / 6;
      final pixel = image.getPixel(
        x.floor().clamp(0, image.width - 1),
        y.floor().clamp(0, image.height - 1),
      );
      final luma = (pixel.r * 0.299) + (pixel.g * 0.587) + (pixel.b * 0.114);
      signature.add(luma.round().clamp(0, 255));
    }
    return signature;
  }
}
