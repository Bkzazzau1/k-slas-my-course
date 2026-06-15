import '../core/local_ai_event.dart';

class CameraReadinessResult {
  const CameraReadinessResult({
    required this.isAvailable,
    required this.permissionGranted,
    required this.faceVisible,
    required this.lightingOk,
    this.message,
  });

  final bool isAvailable;
  final bool permissionGranted;
  final bool faceVisible;
  final bool lightingOk;
  final String? message;

  bool get canStartExam =>
      isAvailable && permissionGranted && faceVisible && lightingOk;

  List<LocalAiEvent> toEvents({String? sessionId, String? studentId}) {
    if (canStartExam) return const <LocalAiEvent>[];

    return <LocalAiEvent>[
      LocalAiEvent(
        type: LocalAiEventType.cameraReadinessFailed,
        severity: LocalAiSeverity.high,
        timestamp: DateTime.now(),
        riskPoints: 0,
        sessionId: sessionId,
        studentId: studentId,
        message: message ?? 'Camera readiness check failed.',
        metadata: <String, Object?>{
          'isAvailable': isAvailable,
          'permissionGranted': permissionGranted,
          'faceVisible': faceVisible,
          'lightingOk': lightingOk,
        },
      ),
    ];
  }
}

class CameraReadinessService {
  Future<CameraReadinessResult> evaluate({
    required bool isAvailable,
    required bool permissionGranted,
    required bool faceVisible,
    required bool lightingOk,
  }) async {
    return CameraReadinessResult(
      isAvailable: isAvailable,
      permissionGranted: permissionGranted,
      faceVisible: faceVisible,
      lightingOk: lightingOk,
      message: _messageFor(
        isAvailable: isAvailable,
        permissionGranted: permissionGranted,
        faceVisible: faceVisible,
        lightingOk: lightingOk,
      ),
    );
  }

  String? _messageFor({
    required bool isAvailable,
    required bool permissionGranted,
    required bool faceVisible,
    required bool lightingOk,
  }) {
    if (!isAvailable) return 'No camera detected.';
    if (!permissionGranted) return 'Camera permission is not granted.';
    if (!faceVisible) return 'Student face is not visible.';
    if (!lightingOk) return 'Lighting is not good enough for proctoring.';
    return null;
  }
}
