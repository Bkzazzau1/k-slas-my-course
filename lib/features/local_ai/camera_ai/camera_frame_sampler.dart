class CameraFrameSampler {
  CameraFrameSampler({this.minimumInterval = const Duration(milliseconds: 700)});

  final Duration minimumInterval;
  DateTime? _lastProcessedAt;

  bool shouldProcess(DateTime now) {
    final last = _lastProcessedAt;
    if (last == null || now.difference(last) >= minimumInterval) {
      _lastProcessedAt = now;
      return true;
    }
    return false;
  }

  void reset() {
    _lastProcessedAt = null;
  }
}
