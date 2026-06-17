import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_courses/features/local_ai/audio_ai/audio_environment_learning_service.dart';
import 'package:my_courses/features/local_ai/audio_ai/environment_sound_classifier.dart';

void main() {
  test('learn reports progress and classifies quiet environment', () async {
    final snapshots = <AudioEnvironmentLearningSnapshot>[];
    final service = AudioEnvironmentLearningService(
      sampler: _FakeAudioEnvironmentSampler(
        amplitudes: const <double>[0.03, 0.04, 0.03, 0.05, 0.04],
      ),
      sampleDuration: const Duration(milliseconds: 40),
      progressInterval: const Duration(milliseconds: 10),
    );

    final result = await service.learn(onProgress: snapshots.add);

    expect(snapshots, isNotEmpty);
    expect(result.classification.type, EnvironmentSoundType.quiet);
    expect(result.observation.voiceConfidence, lessThan(0.70));
  });

  test('learn identifies speech-like human voice pattern', () async {
    final service = AudioEnvironmentLearningService(
      sampler: _FakeAudioEnvironmentSampler(
        amplitudes: const <double>[0.10, 0.60, 0.12, 0.58, 0.11, 0.62],
      ),
      sampleDuration: const Duration(milliseconds: 40),
      progressInterval: const Duration(milliseconds: 10),
    );

    final result = await service.learn();

    expect(result.observation.voiceConfidence, greaterThanOrEqualTo(0.70));
    expect(result.classification.type, EnvironmentSoundType.humanVoice);
  });
}

class _FakeAudioEnvironmentSampler implements AudioEnvironmentSampler {
  _FakeAudioEnvironmentSampler({required this.amplitudes});

  final List<double> amplitudes;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<Stream<Uint8List>> start() async {
    return Stream<Uint8List>.fromIterable(amplitudes.map(_pcmChunk));
  }

  @override
  Future<void> stop() async {}

  Uint8List _pcmChunk(double amplitude) {
    final bytes = Uint8List(200);
    final data = ByteData.sublistView(bytes);
    final sample = (amplitude.clamp(0.0, 1.0) * 32767).round();
    for (var i = 0; i + 1 < bytes.length; i += 2) {
      data.setInt16(i, sample, Endian.little);
    }
    return bytes;
  }
}
