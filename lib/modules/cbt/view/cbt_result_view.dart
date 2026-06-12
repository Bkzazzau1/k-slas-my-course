import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/cbt_models.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/submission_history_service.dart';
import '../../proctoring/controller/proctoring_controller.dart';

class CBTResultView extends StatelessWidget {
  const CBTResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final attempt = Get.arguments as CBTAttemptModel;
    final isProctored = attempt.deliveryMode == ExamDeliveryMode.remoteProctored;
    final proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : null;
    final warningCount = proctoring?.violationCount.value ?? 0;
    final integrityScore = proctoring?.integrityScore.value;
    final status = !isProctored || warningCount == 0
        ? 'Submitted Successfully'
        : 'Submitted - Under Review';
    final receipt = 'KSLAS-${attempt.endedAt.millisecondsSinceEpoch.toString().substring(5)}';

    unawaited(SubmissionHistoryService.saveCbtAttempt(
      attempt,
      receiptNumber: receipt,
      status: status,
      integrityScore: integrityScore,
      warningCount: warningCount,
    ));

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Hero(attempt: attempt, status: status),
            const SizedBox(height: 12),
            _Card(
              title: 'Submission receipt',
              icon: Icons.receipt_long_rounded,
              child: Column(
                children: [
                  _row('Receipt number', receipt),
                  _row('Course', attempt.courseCode),
                  _row('Type', attempt.gradingType == GradingType.graded ? 'Graded Assessment' : 'Ungraded Assessment'),
                  _row('Mode', attempt.deliveryMode.label),
                  _row('Submitted', _formatDate(attempt.endedAt)),
                  _row('Status', status),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              title: 'Score summary',
              icon: Icons.analytics_outlined,
              child: Column(
                children: [
                  _row('Score', '${attempt.correct}/${attempt.totalQuestions}'),
                  _row('Percentage', '${attempt.scorePct}%'),
                  _row('Topic', attempt.topic),
                  if (attempt.whiteboardEnabled)
                    _row('Whiteboard', attempt.whiteboardSubmitted ? 'Submitted' : 'Not submitted'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              title: 'Student proctoring summary',
              icon: Icons.security_rounded,
              child: isProctored
                  ? Column(
                      children: [
                        _check('Camera and room scan', proctoring?.examStartupScanCompleted.value == true),
                        _check('Room rotation', proctoring?.scanRotationConfirmed.value == true),
                        _check('Lighting check', (proctoring?.scanLightingScore.value ?? 0) >= (proctoring?.minimumScanLightingScore ?? 1)),
                        _check('Integrity score', (integrityScore ?? 0) >= 70, detail: integrityScore == null ? 'Not available' : '$integrityScore'),
                        _check('Warnings', warningCount == 0, detail: '$warningCount'),
                      ],
                    )
                  : const Text(
                      'This was a normal assessment. Camera and microphone proctoring were not active.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.back(result: attempt),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Return'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep the receipt number for your record. Final release may depend on university policy.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  static Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }

  static Widget _check(String label, bool ok, {String? detail}) {
    final color = ok ? Colors.green : Colors.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          if (detail != null) Text(detail, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.attempt, required this.status});
  final CBTAttemptModel attempt;
  final String status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(Icons.verified_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(attempt.courseCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 4),
              Text('${attempt.correct}/${attempt.totalQuestions} correct', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
            ]),
          ),
          Text('${attempt.scorePct}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      ),
    );
  }
}
