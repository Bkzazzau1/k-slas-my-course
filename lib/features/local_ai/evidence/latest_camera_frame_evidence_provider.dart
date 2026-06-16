import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

import 'camera_evidence_capture_hook.dart';
import 'evidence_capture_service.dart';

class LatestCameraFrameEvidenceProvider implements CameraEvidenceFrameProvider {
  LatestCameraFrameEvidenceProvider({
    Directory? outputDirectory,
    this.now = DateTime.now,
  }) : _outputDirectory = outputDirectory;

  final Directory? _outputDirectory;
  final DateTime Function() now;

  _StoredCameraFrame? _latestFrame;

  void rememberFrame(CameraImage image, DateTime capturedAt) {
    if (image.planes.isEmpty) return;
    _latestFrame = _StoredCameraFrame.fromCameraImage(image, capturedAt);
  }

  @override
  Future<EvidenceArtifact?> latestFrame(EvidenceArtifactRequest request) async {
    final frame = _latestFrame;
    if (frame == null) return null;

    final directory =
        _outputDirectory ??
        Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}k_slas_evidence',
        );
    await directory.create(recursive: true);

    final file = File(
      '${directory.path}${Platform.pathSeparator}${request.evidenceId}-${request.kind}.jpg',
    );
    final image = _grayscaleImage(frame);
    await file.writeAsBytes(img.encodeJpg(image, quality: 85), flush: true);

    return EvidenceArtifact(
      id: '${request.evidenceId}-${request.kind}',
      kind: request.kind,
      path: file.uri.toString(),
      status: 'captured',
      mimeType: 'image/jpeg',
      sizeBytes: await file.length(),
      metadata: <String, Object?>{
        'captureMode': 'latestCameraFrame',
        'studentId': request.studentId,
        'sessionId': request.sessionId,
        'eventType': request.event.type.name,
        'reason': request.reason,
        'frameCapturedAt': frame.capturedAt.toIso8601String(),
        'sourceWidth': frame.width,
        'sourceHeight': frame.height,
      },
    );
  }

  img.Image _grayscaleImage(_StoredCameraFrame frame) {
    final image = img.Image(width: frame.width, height: frame.height);
    for (var y = 0; y < frame.height; y++) {
      final rowOffset = y * frame.bytesPerRow;
      for (var x = 0; x < frame.width; x++) {
        final index = (rowOffset + x).clamp(0, frame.lumaBytes.length - 1);
        final value = frame.lumaBytes[index];
        image.setPixelRgb(x, y, value, value, value);
      }
    }
    return image;
  }
}

class _StoredCameraFrame {
  const _StoredCameraFrame({
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.lumaBytes,
    required this.capturedAt,
  });

  factory _StoredCameraFrame.fromCameraImage(
    CameraImage image,
    DateTime capturedAt,
  ) {
    final plane = image.planes.first;
    return _StoredCameraFrame(
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
      lumaBytes: Uint8List.fromList(plane.bytes),
      capturedAt: capturedAt,
    );
  }

  final int width;
  final int height;
  final int bytesPerRow;
  final Uint8List lumaBytes;
  final DateTime capturedAt;
}
