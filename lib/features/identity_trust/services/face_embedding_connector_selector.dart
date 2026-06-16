import '../../../data/services/live_session_runtime_mode_service.dart';
import 'external_face_interpreter_bridge.dart';
import 'face_embedding_connector.dart';
import 'flutter_face_embedding_runner.dart';
import 'onnx_face_embedding_connector.dart';
import 'static_face_embedding_connector.dart';
import 'tflite_face_embedding_connector.dart';

enum FaceEmbeddingRuntimeTarget { mobile, desktop, demo }

class FaceEmbeddingConnectorSelector {
  const FaceEmbeddingConnectorSelector({
    this.demoConnector,
    this.tfliteConnector,
    this.onnxConnector,
    this.runtimeMode,
    this.target = FaceEmbeddingRuntimeTarget.mobile,
  });

  final FaceEmbeddingConnector? demoConnector;
  final FaceEmbeddingConnector? tfliteConnector;
  final FaceEmbeddingConnector? onnxConnector;
  final LiveSessionRuntimeMode? runtimeMode;
  final FaceEmbeddingRuntimeTarget target;

  FaceEmbeddingConnector select() {
    final mode = runtimeMode ?? LiveSessionRuntimeModeStore.load();
    if (mode != LiveSessionRuntimeMode.production || target == FaceEmbeddingRuntimeTarget.demo) {
      return demoConnector ?? _demoConnector();
    }

    if (target == FaceEmbeddingRuntimeTarget.desktop) {
      return onnxConnector ?? OnnxFaceEmbeddingConnector();
    }

    return tfliteConnector ?? _mobileConnector();
  }

  String get providerLabel {
    final mode = runtimeMode ?? LiveSessionRuntimeModeStore.load();
    if (mode != LiveSessionRuntimeMode.production || target == FaceEmbeddingRuntimeTarget.demo) {
      return 'Demo static face embedding connector';
    }

    if (target == FaceEmbeddingRuntimeTarget.desktop) {
      return 'ONNX face embedding connector';
    }

    return 'TFLite face embedding connector';
  }

  FaceEmbeddingConnector _demoConnector() {
    return StaticFaceEmbeddingConnector(
      embedding: const <double>[1, 0, 0],
      version: 'demo-static-face-v1',
    );
  }

  FaceEmbeddingConnector _mobileConnector() {
    return TfliteFaceEmbeddingConnector(
      runner: FlutterFaceEmbeddingRunner(
        bridge: ExternalFaceInterpreterBridge(),
      ),
    );
  }
}
