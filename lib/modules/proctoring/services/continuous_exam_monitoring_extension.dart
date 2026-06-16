import '../../../features/local_ai/audio_ai/environment_sound_classifier.dart';
import '../controller/proctoring_controller.dart';
import 'continuous_exam_monitoring_policy.dart';

extension ContinuousExamMonitoringExtension on ProctoringController {
  static const ContinuousExamMonitoringPolicy _policy =
      ContinuousExamMonitoringPolicy();

  bool get cameraMustStayOnDuringExam => _policy.cameraMustRemainOn;
  bool get audioMustStayOnDuringExam => _policy.audioMustRemainOn;

  void registerContinuousGazeCheck({
    required bool lookingAtScreen,
  }) {
    if (!examMonitoringArmed.value || sessionTerminated.value) return;

    final result = _policy.evaluateGaze(
      lookingAtScreen: lookingAtScreen,
      currentWarnings: gazeWarnings.value,
    );

    gazeWarnings.value = result.warningCount;
    if (result.riskPoints > 0) {
      registerViolation(
        result.message,
        penalty: result.riskPoints,
        alert: true,
      );
    }

    if (!result.allowedToContinue) {
      forceBackgroundScan(
        'Student reached the look-away warning limit. Face the screen and complete verification again.',
      );
    }
  }

  void registerContinuousAudioCheck({
    required EnvironmentSoundObservation observation,
    bool steadySpeechLikePattern = false,
  }) {
    if (!examMonitoringArmed.value || sessionTerminated.value) return;

    final result = _policy.evaluateAudio(
      observation: observation,
      steadySpeechLikePattern: steadySpeechLikePattern,
    );

    if (result.riskPoints > 0) {
      registerViolation(
        '${result.message} Sound type: ${result.label}.',
        penalty: result.riskPoints,
        alert: true,
      );
    }

    if (!result.allowedToContinue) {
      forceBackgroundScan(
        'Audio environment changed during exam. Remove the sound source and verify again.',
      );
    }
  }

  void registerCameraStreamLost() {
    if (!examMonitoringArmed.value || sessionTerminated.value) return;
    registerViolation(
      'Camera stream stopped during exam. Camera must remain on.',
      penalty: 30,
      alert: true,
    );
    forceBackgroundScan('Camera must remain on during the exam. Reconnect and verify again.');
  }

  void registerAudioStreamLost() {
    if (!examMonitoringArmed.value || sessionTerminated.value) return;
    registerViolation(
      'Audio stream stopped during exam. Microphone must remain on.',
      penalty: 30,
      alert: true,
    );
    forceBackgroundScan('Microphone must remain on during the exam. Reconnect and verify again.');
  }
}
