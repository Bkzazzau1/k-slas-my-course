import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class AcousticWatchdog {
  AcousticWatchdog({required this.onPcmChunk});

  final void Function(Uint8List chunk) onPcmChunk;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSubscription;

  bool _running = false;

  bool get isRunning => _running;

  Future<bool> start() async {
    if (_running) return true;

    final permission = await _recorder.hasPermission();
    if (!permission) {
      return false;
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );

    _audioSubscription = stream.listen(
      (chunk) {
        if (chunk.isEmpty) return;
        onPcmChunk(chunk);
      },
      onError: (_) {
        // Keep best-effort background monitoring behavior.
      },
      cancelOnError: false,
    );

    _running = true;
    return true;
  }

  Future<void> stop({bool dispose = false}) async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    _running = false;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {
      // Best effort shutdown.
    }

    if (!dispose) return;

    try {
      await _recorder.dispose();
    } catch (_) {
      // Best effort disposal.
    }
  }
}
