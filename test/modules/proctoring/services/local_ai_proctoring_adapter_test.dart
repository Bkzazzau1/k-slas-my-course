import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/services/integrity_ledger_service.dart';
import 'package:my_courses/features/local_ai/local_ai.dart';
import 'package:my_courses/modules/proctoring/controller/proctoring_controller.dart';
import 'package:my_courses/modules/proctoring/services/local_ai_proctoring_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    Get.testMode = true;
    await IntegrityLedgerService.clearAllForStudent('KASU/CSC/001');
    await EvidenceCaptureService().clearAllForStudent('KASU/CSC/001');
  });

  test(
    'adapter should attach evidence manifest to high-risk camera events',
    () async {
      final engine = LocalAiEngine();
      final controller = ProctoringController();
      final evidenceService = EvidenceCaptureService();
      final adapter = LocalAiProctoringAdapter(
        localAiEngine: engine,
        proctoringController: controller,
        evidenceCaptureService: evidenceService,
      );

      await controller.startSession(
        level: AssessmentIntegrityLevel.highStakesExam,
        studentId: 'KASU/CSC/001',
      );
      adapter.start();

      await engine.ingest(
        LocalAiEvent(
          type: LocalAiEventType.multipleFacesDetected,
          severity: LocalAiSeverity.high,
          timestamp: DateTime.now(),
          riskPoints: 25,
          studentId: 'KASU/CSC/001',
          sessionId: controller.activeSessionId.value,
          message: 'Multiple faces detected in camera feed.',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      final entries = IntegrityLedgerService.pendingLedgerEntries(
        'KASU/CSC/001',
      );
      expect(entries, isNotEmpty);
      expect(entries.first.evidencePath, startsWith('evidence://'));
      expect(entries.first.metadata['evidence'], isNotNull);

      final manifests = evidenceService.loadManifests('KASU/CSC/001');
      expect(manifests, hasLength(1));
      expect(manifests.first.eventType, 'multipleFacesDetected');
      expect(
        manifests.first.artifacts.any(
          (artifact) => artifact.kind == 'cameraClip',
        ),
        isTrue,
      );

      await adapter.stop();
      await controller.stopSession(silent: true);
      await engine.dispose();
    },
  );

  test(
    'adapter should attach audio evidence request for voice events',
    () async {
      final engine = LocalAiEngine();
      final controller = ProctoringController();
      final evidenceService = EvidenceCaptureService();
      final adapter = LocalAiProctoringAdapter(
        localAiEngine: engine,
        proctoringController: controller,
        evidenceCaptureService: evidenceService,
      );

      await controller.startSession(
        level: AssessmentIntegrityLevel.highStakesExam,
        studentId: 'KASU/CSC/001',
      );
      adapter.start();

      await engine.ingest(
        LocalAiEvent(
          type: LocalAiEventType.humanVoiceDetected,
          severity: LocalAiSeverity.high,
          timestamp: DateTime.now(),
          riskPoints: 20,
          studentId: 'KASU/CSC/001',
          sessionId: controller.activeSessionId.value,
          message: 'Human voice detected during the session.',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      final manifests = evidenceService.loadManifests('KASU/CSC/001');
      expect(manifests, hasLength(1));
      expect(
        manifests.first.artifacts.any(
          (artifact) => artifact.kind == 'audioClip',
        ),
        isTrue,
      );

      await adapter.stop();
      await controller.stopSession(silent: true);
      await engine.dispose();
    },
  );
}
