import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../proctoring/controller/proctoring_controller.dart';

class ExamResultView extends StatelessWidget {
  const ExamResultView({super.key});

  @override
  Widget build(BuildContext context) {
    final res = Get.arguments as ExamResult;
    final cs = Theme.of(context).colorScheme;
    final isAssessment = res.sessionType == SessionType.assessment;
    final sessionLabel = isAssessment ? 'Assessment' : 'Examination';
    final receipt = 'KSLAS-${res.endedAt.millisecondsSinceEpoch.toString().substring(5)}';
    final duration = res.endedAt.difference(res.startedAt);
    final proctoring = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : null;
    final isProctored = res.deliveryMode == ExamDeliveryMode.remoteProctored;
    final integrityScore = proctoring?.integrityScore.value;
    final warningCount = proctoring?.violationCount.value ?? 0;
    final clean = !isProctored || (warningCount == 0 && (integrityScore ?? 100) >= 80);
    final status = clean
        ? 'Submitted Successfully'
        : warningCount > 0
            ? 'Submitted - Under Review'
            : 'Submitted - Warning';

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _Hero(
                courseCode: res.courseCode,
                sessionLabel: sessionLabel,
                status: status,
                score: res.pct,
                clean: clean,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _Card(
                    title: 'Submission receipt',
                    icon: Icons.receipt_long_rounded,
                    child: Column(
                      children: [
                        _row('Receipt number', receipt),
                        _row('Course', res.courseCode),
                        _row('Type', sessionLabel),
                        _row('Mode', res.gradingType == GradingType.graded ? 'Graded' : 'Ungraded'),
                        _row('Submitted', _formatDate(res.endedAt)),
                        _row('Time used', '${duration.inMinutes} min ${duration.inSeconds.remainder(60)} sec'),
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
                        _row('Total score', '${res.scoredMarks}/${res.totalMarks}'),
                        _row('Percentage', '${res.pct}%'),
                        _row('Sections submitted', '${res.sectionScores.length}'),
                        if (res.whiteboardEnabled)
                          _row('Whiteboard', res.whiteboardSubmitted ? 'Submitted' : 'Not submitted'),
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
                            'This was a normal session. Camera and microphone proctoring were not active.',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _Card(
                    title: 'Section scores',
                    icon: Icons.list_alt_outlined,
                    child: Column(
                      children: res.sectionScores
                          .map((s) => _sectionRow(context, _label(s.sectionType), '${s.scoredMarks}/${s.totalMarks}'))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Get.offAllNamed('/dashboard'),
                      icon: const Icon(Icons.dashboard_rounded),
                      label: const Text('Return to dashboard'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        if (isAssessment) {
                          Get.offAllNamed(Routes.cbtSetup, arguments: {'courseCode': res.courseCode});
                          return;
                        }
                        Get.offAllNamed(Routes.examSetup);
                      },
                      child: Text('Take another ${sessionLabel.toLowerCase()}'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Keep this receipt number for your record. Final grading may depend on university release policy.',
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
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

  static Widget _sectionRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  String _label(String s) {
    if (s == ExamSectionType.objective) return 'Objective (CBT)';
    if (s == ExamSectionType.fillBlank) return 'Fill in the blank';
    return 'Theory (Essay)';
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.courseCode, required this.sessionLabel, required this.status, required this.score, required this.clean});
  final String courseCode;
  final String sessionLabel;
  final String status;
  final int score;
  final bool clean;

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
            child: Icon(clean ? Icons.verified_rounded : Icons.fact_check_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(courseCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Text('$sessionLabel submitted', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            ]),
          ),
          Text('$score%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 30)),
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
