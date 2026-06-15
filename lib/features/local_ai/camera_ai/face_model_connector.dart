import 'package:camera/camera.dart';

class FaceDetectionBox {
  const FaceDetectionBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.confidence,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double? confidence;

  Map<String, Object?> toJson() => <String, Object?>{
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        'confidence': confidence,
      };
}

class FaceDetectionOutput {
  const FaceDetectionOutput({
    required this.faces,
    required this.imageWidth,
    required this.imageHeight,
    required this.inferenceTimeMs,
  });

  final List<FaceDetectionBox> faces;
  final int imageWidth;
  final int imageHeight;
  final int inferenceTimeMs;

  int get faceCount => faces.length;

  double? get primaryFaceConfidence {
    if (faces.isEmpty) return null;
    final confidences = faces
        .map((face) => face.confidence)
        .whereType<double>()
        .toList();
    if (confidences.isEmpty) return null;
    confidences.sort((a, b) => b.compareTo(a));
    return confidences.first;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'faceCount': faceCount,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'inferenceTimeMs': inferenceTimeMs,
        'primaryFaceConfidence': primaryFaceConfidence,
        'faces': faces.map((face) => face.toJson()).toList(),
      };
}

abstract class FaceModelConnector {
  String get connectorId;
  bool get isReady;

  Future<void> load();

  Future<FaceDetectionOutput> detectFaces(CameraImage image);

  Future<void> dispose();
}
