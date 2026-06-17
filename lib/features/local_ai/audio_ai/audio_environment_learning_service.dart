import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

import 'environment_sound_classifier.dart';

class AudioEnvironmentLearningSnapshot {
  const AudioEnvironmentLearningSnapshot({
    required this.elapsed,
    required this.total,
    required this.averageRms,
    required this.peakRms,
    required this.voiceConfidence,
    required this.feedback,
  });

  final Duration elapsed;
  final Duration total;
  final double averageRms;
  final double peakRms;
  final double voiceConfidence;
  final String feedback;

  double get progress {
    if (total.inMilliseconds <= 0) return 0;
    return (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }
}

class AudioEnvironmentLearningResult {
  const AudioEnvironmentLearningResult({
    required this.observation,
    required this.classification,
    required this.snapshots,
  });

  final EnvironmentSoundObservation observation;
  final EnvironmentSoundClassification classification;
  final List<AudioEnvironmentLearningSnapshot> snapshots;
}

abstract class AudioEnvironmentSampler {
  Future<Stream<Uint8List>> start();

  Future<bool> hasPermission();

  Future<void> stop();

  Future<void> dispose();
}

class RecordAudioEnvironmentSampler implements AudioEnvironmentSampler {
  RecordAudioEnvironmentSampler({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> start() {
    return _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
  }

  @override
  Future<void> stop() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Best effort shutdown so the exam gate can surface the real result.
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

class AudioEnvironmentLearningService {
  AudioEnvironmentLearningService({
    AudioEnvironmentSampler? sampler,
    EnvironmentSoundClassifier classifier = const EnvironmentSoundClassifier(),
    this.sampleDuration = const Duration(seconds: 5),
    this.progressInterval = const Duration(milliseconds: 500),
  }) : _sampler = sampler ?? RecordAudioEnvironmentSampler(),
       _classifier = classifier;

  final AudioEnvironmentSampler _sampler;
  final EnvironmentSoundClassifier _classifier;
  final Duration sampleDuration;
  final Duration progressInterval;

  Future<AudioEnvironmentLearningResult> learn({
    void Function(AudioEnvironmentLearningSnapshot snapshot)? onProgress,
  }) async {
    final allowed = await _sampler.hasPermission();
    if (!allowed) {
      throw StateError('Microphone permission is not granted.');
    }

    final rmsSamples = <double>[];
    final snapshots = <AudioEnvironmentLearningSnapshot>[];
    final startedAt = DateTime.now();
    final done = Completer<void>();
    StreamSubscription<Uint8List>? subscription;

    Timer? progressTimer;
    try {
      final stream = await _sampler.start();
      subscription = stream.listen(
        (chunk) {
          final rms = _pcm16Rms(chunk);
          if (rms > 0) rmsSamples.add(rms);
        },
        onError: done.completeError,
        cancelOnError: true,
      );

      progressTimer = Timer.periodic(progressInterval, (_) {
        final elapsed = DateTime.now().difference(startedAt);
        final snapshot = _snapshot(
          elapsed: elapsed > sampleDuration ? sampleDuration : elapsed,
          total: sampleDuration,
          rmsSamples: rmsSamples,
        );
        snapshots.add(snapshot);
        onProgress?.call(snapshot);
        if (elapsed >= sampleDuration && !done.isCompleted) {
          done.complete();
        }
      });

      await done.future.timeout(sampleDuration + const Duration(seconds: 2));
    } finally {
      progressTimer?.cancel();
      await subscription?.cancel();
      await _sampler.stop();
      await _sampler.dispose();
    }

    final observation = _observation(startedAt, rmsSamples);
    final classification = _classifier.classify(observation);
    return AudioEnvironmentLearningResult(
      observation: observation,
      classification: classification,
      snapshots: snapshots,
    );
  }

  AudioEnvironmentLearningSnapshot _snapshot({
    required Duration elapsed,
    required Duration total,
    required List<double> rmsSamples,
  }) {
    final stats = _stats(rmsSamples);
    final voiceConfidence = _voiceConfidence(rmsSamples);
    return AudioEnvironmentLearningSnapshot(
      elapsed: elapsed,
      total: total,
      averageRms: stats.average,
      peakRms: stats.peak,
      voiceConfidence: voiceConfidence,
      feedback: _feedbackFor(
        elapsed: elapsed,
        total: total,
        averageRms: stats.average,
        peakRms: stats.peak,
        voiceConfidence: voiceConfidence,
      ),
    );
  }

  EnvironmentSoundObservation _observation(
    DateTime startedAt,
    List<double> rmsSamples,
  ) {
    final stats = _stats(rmsSamples);
    final voiceConfidence = _voiceConfidence(rmsSamples);
    final sharpness = _sharpness(rmsSamples);
    final steadyLowNoise =
        stats.average >= 0.08 && stats.average <= 0.30 && stats.variance < 0.01;

    return EnvironmentSoundObservation(
      timestamp: startedAt,
      averageRms: stats.average,
      peakRms: stats.peak,
      dominantFrequencyHz: voiceConfidence >= 0.70
          ? 220
          : sharpness >= 0.55
          ? 2400
          : steadyLowNoise
          ? 90
          : 360,
      spectralCentroidHz: sharpness >= 0.55
          ? 2800
          : voiceConfidence >= 0.70
          ? 1150
          : steadyLowNoise
          ? 260
          : 700,
      voiceConfidence: voiceConfidence,
      voiceCount: voiceConfidence >= 0.88
          ? 2
          : voiceConfidence >= 0.70
          ? 1
          : 0,
      durationSeconds: sampleDuration.inSeconds,
    );
  }

  String _feedbackFor({
    required Duration elapsed,
    required Duration total,
    required double averageRms,
    required double peakRms,
    required double voiceConfidence,
  }) {
    final remaining =
        ((total - elapsed).inMilliseconds / Duration.millisecondsPerSecond)
            .ceil()
            .clamp(0, total.inSeconds);
    if (voiceConfidence >= 0.70) {
      return 'Human voice pattern detected. Stay silent for $remaining more seconds.';
    }
    if (peakRms >= 0.65) {
      return 'Loud sound detected. Keep the room quiet for $remaining more seconds.';
    }
    if (averageRms >= 0.20) {
      return 'Learning steady background sound. Remain still for $remaining more seconds.';
    }
    return 'Learning quiet room sound. Stay silent for $remaining more seconds.';
  }

  double _pcm16Rms(Uint8List bytes) {
    if (bytes.length < 2) return 0;
    final data = ByteData.sublistView(bytes);
    var sumSquares = 0.0;
    var count = 0;
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      final sample = data.getInt16(i, Endian.little) / 32768.0;
      sumSquares += sample * sample;
      count++;
    }
    if (count == 0) return 0;
    return math.sqrt(sumSquares / count).clamp(0.0, 1.0);
  }

  _AudioStats _stats(List<double> samples) {
    if (samples.isEmpty) return const _AudioStats(0, 0, 0);
    final average =
        samples.fold<double>(0, (sum, value) => sum + value) / samples.length;
    final peak = samples.reduce(math.max);
    final variance =
        samples.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - average, 2).toDouble(),
        ) /
        samples.length;
    return _AudioStats(average, peak, variance);
  }

  double _voiceConfidence(List<double> samples) {
    if (samples.length < 4) return 0;
    final stats = _stats(samples);
    final active = samples.where((value) => value >= 0.10).length;
    final activeRatio = active / samples.length;
    final modulation = stats.average <= 0 ? 0 : stats.variance / stats.average;
    final speechLike =
        (activeRatio * 0.55) + (modulation.clamp(0.0, 0.50) * 0.90);
    if (stats.peak < 0.12) return speechLike.clamp(0.0, 0.35);
    return speechLike.clamp(0.0, 0.95);
  }

  double _sharpness(List<double> samples) {
    if (samples.length < 3) return 0;
    var jumps = 0;
    for (var i = 1; i < samples.length; i++) {
      if ((samples[i] - samples[i - 1]).abs() >= 0.18) jumps++;
    }
    return (jumps / (samples.length - 1)).clamp(0.0, 1.0);
  }
}

class _AudioStats {
  const _AudioStats(this.average, this.peak, this.variance);

  final double average;
  final double peak;
  final double variance;
}
