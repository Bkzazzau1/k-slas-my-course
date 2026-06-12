import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../controller/exam_operations_controller.dart';

class ExamOperationsView extends GetView<ExamOperationsController> {
  const ExamOperationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Obx(
                () => _Header(
                  cs: cs,
                  role: controller.role.value,
                  pendingAlerts: controller.pendingAlertCount,
                  onRoleChanged: controller.switchRole,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.role.value == ExamOpsRole.invigilator) {
                  return _InvigilatorAlerts(
                    cs: cs,
                    alerts: controller.alerts,
                    loading: controller.isLoadingAlerts.value,
                    onRefresh: controller.refreshAlerts,
                    onAcknowledge: controller.acknowledgeAlert,
                  );
                }
                return _OfficerPipeline(
                  cs: cs,
                  exams: controller.exams,
                  onAssign: controller.assignInvigilator,
                  onRelease: controller.releaseExam,
                  onShare: controller.shareWithLecturer,
                  onComment: controller.addLecturerComment,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cs,
    required this.role,
    required this.pendingAlerts,
    required this.onRoleChanged,
  });

  final ColorScheme cs;
  final ExamOpsRole role;
  final int pendingAlerts;
  final ValueChanged<ExamOpsRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.tertiary.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exam Operations',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == ExamOpsRole.officer
                          ? 'Officer release, timetable, and lecturer handoff.'
                          : '$pendingAlerts pending invigilator alert(s).',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ExamOpsRole>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? cs.primary
                      : Colors.white,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                ),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.22)),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: ExamOpsRole.officer,
                  icon: Icon(Icons.admin_panel_settings_outlined, size: 18),
                  label: Text('Exam officer'),
                ),
                ButtonSegment(
                  value: ExamOpsRole.invigilator,
                  icon: Icon(Icons.health_and_safety_outlined, size: 18),
                  label: Text('Invigilator'),
                ),
              ],
              selected: {role},
              onSelectionChanged: (values) => onRoleChanged(values.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficerPipeline extends StatelessWidget {
  const _OfficerPipeline({
    required this.cs,
    required this.exams,
    required this.onAssign,
    required this.onRelease,
    required this.onShare,
    required this.onComment,
  });

  final ColorScheme cs;
  final List<ExamOpsExam> exams;
  final ValueChanged<String> onAssign;
  final ValueChanged<String> onRelease;
  final ValueChanged<String> onShare;
  final void Function(String examId, String comment) onComment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      children: [
        _SummaryStrip(cs: cs, exams: exams),
        const SizedBox(height: 12),
        ...exams.map(
          (exam) => _ExamOpsCard(
            cs: cs,
            exam: exam,
            onAssign: () => onAssign(exam.id),
            onRelease: () => onRelease(exam.id),
            onShare: () => onShare(exam.id),
            onComment: (comment) => onComment(exam.id, comment),
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.cs, required this.exams});

  final ColorScheme cs;
  final List<ExamOpsExam> exams;

  @override
  Widget build(BuildContext context) {
    final released = exams
        .where((e) => e.status == ExamOpsStatus.released)
        .length;
    final handoff = exams
        .where((e) => e.status == ExamOpsStatus.submittedToOfficer)
        .length;
    return Row(
      children: [
        Expanded(
          child: _Metric(cs: cs, label: 'Ready', value: '$released'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(cs: cs, label: 'Handoff', value: '$handoff'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(cs: cs, label: 'Total', value: '${exams.length}'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.cs, required this.label, required this.value});
  final ColorScheme cs;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamOpsCard extends StatefulWidget {
  const _ExamOpsCard({
    required this.cs,
    required this.exam,
    required this.onAssign,
    required this.onRelease,
    required this.onShare,
    required this.onComment,
  });

  final ColorScheme cs;
  final ExamOpsExam exam;
  final VoidCallback onAssign;
  final VoidCallback onRelease;
  final VoidCallback onShare;
  final ValueChanged<String> onComment;

  @override
  State<_ExamOpsCard> createState() => _ExamOpsCardState();
}

class _ExamOpsCardState extends State<_ExamOpsCard> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final exam = widget.exam;
    final status = _statusLabel(exam.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${exam.courseCode} • ${exam.title}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _Pill(text: status.$1, tone: status.$2),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            exam.questionSummary,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(text: exam.deliveryMode, tone: cs.primary),
              _Pill(text: '${exam.durationMinutes} mins', tone: cs.secondary),
              _Pill(text: _fmtDateTime(exam.startsAt), tone: cs.tertiary),
            ],
          ),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.person_outline,
            text: 'Lecturer: ${exam.lecturerName}',
          ),
          _InfoLine(
            icon: Icons.admin_panel_settings_outlined,
            text: 'Exam officer: ${exam.examOfficerName}',
          ),
          _InfoLine(
            icon: Icons.health_and_safety_outlined,
            text: 'Invigilator: ${exam.invigilatorName}',
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              exam.submissionSummary,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if ((exam.lecturerComment ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Lecturer comment: ${exam.lecturerComment}',
              style: TextStyle(
                color: cs.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: exam.status == ExamOpsStatus.officerReview
                    ? widget.onAssign
                    : null,
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('Assign invigilator'),
              ),
              FilledButton.icon(
                onPressed:
                    exam.status == ExamOpsStatus.invigilatorAssigned ||
                        exam.status == ExamOpsStatus.officerReview
                    ? widget.onRelease
                    : null,
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('Release'),
              ),
              OutlinedButton.icon(
                onPressed: exam.status == ExamOpsStatus.submittedToOfficer
                    ? widget.onShare
                    : null,
                icon: const Icon(Icons.forward_to_inbox_outlined),
                label: const Text('Send to lecturer'),
              ),
            ],
          ),
          if (exam.status == ExamOpsStatus.sharedForMarking ||
              exam.status == ExamOpsStatus.marked) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Lecturer comment only',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => widget.onComment(_commentController.text),
                icon: const Icon(Icons.comment_outlined),
                label: const Text('Save comment'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvigilatorAlerts extends StatelessWidget {
  const _InvigilatorAlerts({
    required this.cs,
    required this.alerts,
    required this.loading,
    required this.onRefresh,
    required this.onAcknowledge,
  });

  final ColorScheme cs;
  final List<InvigilatorAlert> alerts;
  final bool loading;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 3),
          if (alerts.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('No invigilator alerts pending.'),
            ),
          ...alerts.map(
            (alert) => _AlertCard(
              cs: cs,
              alert: alert,
              onAcknowledge: () => onAcknowledge(alert.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.cs,
    required this.alert,
    required this.onAcknowledge,
  });

  final ColorScheme cs;
  final InvigilatorAlert alert;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final critical = alert.severity == 'critical';
    final tone = alert.acknowledged
        ? cs.onSurface.withValues(alpha: 0.56)
        : critical
        ? cs.error
        : const Color(0xFFF57C00);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.acknowledged
                    ? Icons.check_circle_outline
                    : Icons.notification_important_outlined,
                color: tone,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alert.studentName} • ${alert.eventType}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Pill(text: alert.severity.toUpperCase(), tone: tone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.74),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Integrity score ${alert.integrityScore} • ${_fmtDateTime(alert.createdAt)}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: alert.acknowledged ? null : onAcknowledge,
              icon: const Icon(Icons.done_all_outlined),
              label: Text(
                alert.acknowledged ? 'Acknowledged' : 'Acknowledge alert',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 17, color: cs.onSurface.withValues(alpha: 0.58)),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

(String, Color) _statusLabel(ExamOpsStatus status) {
  switch (status) {
    case ExamOpsStatus.lecturerSubmitted:
      return ('Lecturer submitted', const Color(0xFF6D4C41));
    case ExamOpsStatus.officerReview:
      return ('Officer review', const Color(0xFFF57C00));
    case ExamOpsStatus.invigilatorAssigned:
      return ('Invigilator assigned', const Color(0xFF1976D2));
    case ExamOpsStatus.released:
      return ('Released', const Color(0xFF2E7D32));
    case ExamOpsStatus.submittedToOfficer:
      return ('Submitted to officer', const Color(0xFF7B1FA2));
    case ExamOpsStatus.sharedForMarking:
      return ('Shared for marking', const Color(0xFF00838F));
    case ExamOpsStatus.marked:
      return ('Marked', const Color(0xFF2E7D32));
  }
}

String _fmtDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
