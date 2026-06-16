import 'package:flutter/services.dart';

import 'face_embedding_connector.dart';
import 'tflite_face_embedding_connector.dart';

class FaceModelReadinessResult {
  const FaceModelReadinessResult({
    required this.assetFound,
    required this.connectorReady,
    required this.canProduceEmbedding,
    required this.message,
  });

  final bool assetFound;
  final bool connectorReady;
  final bool canProduceEmbedding;
  final String message;

  bool get ready => assetFound && connectorReady && canProduceEmbedding;
}

class FaceModelReadinessService {
  const FaceModelReadinessService({
    this.modelAssetPath = 'assets/ml_models/mobilefacenet.tflite',
  });

  final String modelAssetPath;

  Future<FaceModelReadinessResult> check(FaceEmbeddingConnector connector) async {
    final assetFound = await _assetExists();
    if (!assetFound && connector is TfliteFaceEmbeddingConnector) {
      return const FaceModelReadinessResult(
        assetFound: false,
        connectorReady: false,
        canProduceEmbedding: false,
        message: 'Face model asset was not found.',
      );
    }

    try {
      if (!connector.isReady) {
        await connector.load();
      }

      final output = await connector.run(
        FaceEmbeddingInput(
          values: List<int>.filled(112 * 112 * 3, 128),
          width: 112,
          height: 112,
          format: 'rgb',
          metadata: const <String, Object?>{'purpose': 'readiness_check'},
        ),
      );

      if (!output.isUsable) {
        return FaceModelReadinessResult(
          assetFound: assetFound,
          connectorReady: connector.isReady,
          canProduceEmbedding: false,
          message: 'Face connector is loaded but did not produce a usable embedding.',
        );
      }

      return FaceModelReadinessResult(
        assetFound: assetFound,
        connectorReady: connector.isReady,
        canProduceEmbedding: true,
        message: 'Face model is ready.',
      );
    } catch (e) {
      return FaceModelReadinessResult(
        assetFound: assetFound,
        connectorReady: connector.isReady,
        canProduceEmbedding: false,
        message: 'Face model readiness check failed: $e',
      );
    }
  }

  Future<bool> _assetExists() async {
    try {
      await rootBundle.load(modelAssetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
