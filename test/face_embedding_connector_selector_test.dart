import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/data/services/live_session_runtime_mode_service.dart';
import 'package:my_courses/features/identity_trust/services/face_embedding_connector_selector.dart';
import 'package:my_courses/features/identity_trust/services/onnx_face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/static_face_embedding_connector.dart';
import 'package:my_courses/features/identity_trust/services/tflite_face_embedding_connector.dart';

void main() {
  test('connector selector chooses static connector in demo mode', () {
    final connector = const FaceEmbeddingConnectorSelector(
      runtimeMode: LiveSessionRuntimeMode.demo,
    ).select();

    expect(connector, isA<StaticFaceEmbeddingConnector>());
  });

  test('connector selector chooses tflite for production mobile', () {
    final connector = const FaceEmbeddingConnectorSelector(
      runtimeMode: LiveSessionRuntimeMode.production,
      target: FaceEmbeddingRuntimeTarget.mobile,
    ).select();

    expect(connector, isA<TfliteFaceEmbeddingConnector>());
  });

  test('connector selector chooses onnx for production desktop', () {
    final connector = const FaceEmbeddingConnectorSelector(
      runtimeMode: LiveSessionRuntimeMode.production,
      target: FaceEmbeddingRuntimeTarget.desktop,
    ).select();

    expect(connector, isA<OnnxFaceEmbeddingConnector>());
  });
}
