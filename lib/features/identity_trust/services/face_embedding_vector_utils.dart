import 'dart:math' as math;

class FaceEmbeddingVectorUtils {
  FaceEmbeddingVectorUtils._();

  static List<double> normalizeRgb({
    required List<int> values,
    required int expectedLength,
    required double mean,
    required double std,
  }) {
    final output = List<double>.filled(expectedLength, 0);
    if (values.length < expectedLength) return const <double>[];
    for (var i = 0; i < expectedLength; i++) {
      output[i] = (values[i] - mean) / std;
    }
    return output;
  }

  static List<double> l2Normalize(List<double> values) {
    if (values.isEmpty) return const <double>[];
    var sumSquares = 0.0;
    for (final value in values) {
      sumSquares += value * value;
    }
    if (sumSquares <= 0) return const <double>[];
    final norm = math.sqrt(sumSquares);
    return values.map((value) => value / norm).toList(growable: false);
  }
}
