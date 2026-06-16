class LocalFaceEmbeddingRunnerInput {
  const LocalFaceEmbeddingRunnerInput({
    required this.values,
    required this.width,
    required this.height,
    required this.channels,
  });

  final List<double> values;
  final int width;
  final int height;
  final int channels;
}

abstract class LocalFaceEmbeddingRunner {
  Future<void> load(String modelAssetPath);

  Future<List<double>> run(LocalFaceEmbeddingRunnerInput input);

  Future<void> dispose();
}

class EmptyLocalFaceEmbeddingRunner implements LocalFaceEmbeddingRunner {
  const EmptyLocalFaceEmbeddingRunner();

  @override
  Future<void> load(String modelAssetPath) async {}

  @override
  Future<List<double>> run(LocalFaceEmbeddingRunnerInput input) async {
    return const <double>[];
  }

  @override
  Future<void> dispose() async {}
}
