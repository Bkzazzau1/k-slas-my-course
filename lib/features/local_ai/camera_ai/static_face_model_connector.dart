import 'package:camera/camera.dart';

import 'face_model_connector.dart';

class StaticFaceModelConnector implements FaceModelConnector {
  StaticFaceModelConnector({
    this.faces = const <FaceDetectionBox>[],
    this.imageWidth = 640,
    this.imageHeight = 480,
    this.inferenceTimeMs = 1,
  });

  final List<FaceDetectionBox> faces;
  final int imageWidth;
  final int imageHeight;
  final int inferenceTimeMs;

  bool _ready = false;

  @override
  String get connectorId => 'static_face_model_connector';

  @override
  bool get isReady => _ready;

  @override
  Future<void> load() async {
    _ready = true;
  }

  @override
  Future<FaceDetectionOutput> detectFaces(CameraImage image) async {
    return FaceDetectionOutput(
      faces: faces,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      inferenceTimeMs: inferenceTimeMs,
    );
  }

  @override
  Future<void> dispose() async {
    _ready = false;
  }
}
