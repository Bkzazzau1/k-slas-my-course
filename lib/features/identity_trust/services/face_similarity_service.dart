import 'dart:math' as math;

class FaceSimilarityService {
  const FaceSimilarityService();

  double cosineSimilarity(List<double> first, List<double> second) {
    if (first.isEmpty || second.isEmpty || first.length != second.length) {
      return 0;
    }

    var dot = 0.0;
    var firstNorm = 0.0;
    var secondNorm = 0.0;

    for (var i = 0; i < first.length; i++) {
      dot += first[i] * second[i];
      firstNorm += first[i] * first[i];
      secondNorm += second[i] * second[i];
    }

    final denominator = math.sqrt(firstNorm) * math.sqrt(secondNorm);
    if (denominator == 0) return 0;
    return dot / denominator;
  }
}
