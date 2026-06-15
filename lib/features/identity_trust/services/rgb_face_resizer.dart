class RgbFaceResizeRequest {
  const RgbFaceResizeRequest({
    required this.values,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.targetWidth,
    required this.targetHeight,
  });

  final List<int> values;
  final int sourceWidth;
  final int sourceHeight;
  final int targetWidth;
  final int targetHeight;
}

class RgbFaceResizer {
  const RgbFaceResizer();

  List<int> resizeCenterSquare(RgbFaceResizeRequest request) {
    if (request.sourceWidth <= 0 || request.sourceHeight <= 0) {
      throw ArgumentError('Source image dimensions must be greater than zero.');
    }
    if (request.targetWidth <= 0 || request.targetHeight <= 0) {
      throw ArgumentError('Target image dimensions must be greater than zero.');
    }

    final expectedLength = request.sourceWidth * request.sourceHeight * 3;
    if (request.values.length < expectedLength) {
      throw ArgumentError('RGB input is smaller than expected.');
    }

    final cropSize = request.sourceWidth < request.sourceHeight
        ? request.sourceWidth
        : request.sourceHeight;
    final cropLeft = ((request.sourceWidth - cropSize) / 2).floor();
    final cropTop = ((request.sourceHeight - cropSize) / 2).floor();

    final output = List<int>.filled(request.targetWidth * request.targetHeight * 3, 0);

    for (var y = 0; y < request.targetHeight; y++) {
      final srcY = cropTop + ((y * cropSize) / request.targetHeight).floor();
      final safeY = srcY.clamp(0, request.sourceHeight - 1).toInt();

      for (var x = 0; x < request.targetWidth; x++) {
        final srcX = cropLeft + ((x * cropSize) / request.targetWidth).floor();
        final safeX = srcX.clamp(0, request.sourceWidth - 1).toInt();

        final sourceIndex = ((safeY * request.sourceWidth) + safeX) * 3;
        final targetIndex = ((y * request.targetWidth) + x) * 3;

        output[targetIndex] = request.values[sourceIndex];
        output[targetIndex + 1] = request.values[sourceIndex + 1];
        output[targetIndex + 2] = request.values[sourceIndex + 2];
      }
    }

    return output;
  }
}
