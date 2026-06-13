import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_malpractice_report_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveClassMalpracticeReportOverlay extends StatefulWidget {
  const LiveClassMalpracticeReportOverlay({
    super.key,
    required this.child,
    required this.sessionId,
    required this.reporterName,
    required this.reporterRole,
    required this.enabled,
  });

  final Widget child;
  final String sessionId;
  final String reporterName;
  final String reporterRole;
  final bool enabled;

  @override
  State<LiveClassMalpracticeReportOverlay> createState() =>
      _LiveClassMalpracticeReportOverlayState();
}

class _LiveClassMalpracticeReportOverlayState
    extends State<LiveClassMalpracticeReportOverlay> {
  late final LiveSessionsController _controller;
  Timer? _timer;
  List<LiveClassMalpracticeReport> _reports = const [];

  int get _openCount => _reports.where((item) => item.isOpen || item.isEscalated).length;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();
    _reloadReports();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _reloadReports());
  }

  @override
  void didUpdateWidget(covariant LiveClassMalpracticeReportOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) _reloadReports();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reloadReports() {
    if (!widget.enabled || widget.sessionId.trim().isEmpty) return;
    final reports = LiveClassMalpracticeReportService.loadReports(widget.sessionId);
    if (!mounted) return;
    setState(() => _reports = reports);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 18,
          bottom: 166,
          child: _IncidentFab(count: _openCount, onPressed: _showIncidentSheet),
        ),
      ],
    );
  }

  Future<void> _showIncidentSheet() async {
    await _controller.refreshRoom();
    _reloadReports();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.84;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: _IncidentSheetContent(
                controller: _controller,
                sessionId: widget.sessionId,
                reporterName: widget.reporterName,
                reporterRole: widget.reporterRole,
                reports: _reports,
                onChanged: _reloadReports,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IncidentSheetContent extends StatefulWidget {
  const _IncidentSheetContent({
    required this.controller,
    required this.sessionId,
    required this.reporterName,
    required this.reporterRole,
    required this.reports,
    required this.onChanged,
  });

  final LiveSessionsController controller;
  final String sessionId;
  final String reporterName;
  final String reporterRole;
  final List<LiveClassMalpracticeReport> reports;
  final VoidCallback onChanged;

  @override
  State<_IncidentSheetContent> createState() => _IncidentSheetContentState();
}

class _IncidentSheetContentState extends State<_IncidentSheetContent> {
  final _descriptionController = TextEditingController();
  LiveSessionParticipant? _selectedStudent;
  String _category = LiveClassIncidentCategory.cameraViolation;
  String _severity = LiveClassIncidentSeverity.medium;
  bool _showReports = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final room = widget.controller.room.value;
      final students = (room?.participants ?? const <LiveSessionParticipant>[])
          .where((item) => item.role == LiveSessionRole.student)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      if (_selectedStudent == null && students.isNotEmpty) {
        _selectedStudent = students.first;
      }
      final summary = LiveClassMalpracticeReportService.summary(widget.sessionId);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gpp_maybe_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Malpractice / suspicious behaviour',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, icon: Icon(Icons.add_alert_rounded), label: Text('New')),
                  ButtonSegment(value: true, icon: Icon(Icons.list_alt_rounded), label: Text('Reports')),
                ],
                selected: {_showReports},
                onSelectionChanged: (value) => setState(() => _showReports = value.first),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _IncidentSummary(summary: summary),
          const SizedBox(height: 14),
          Expanded(
            child: _showReports
                ? _ReportsList(
                    sessionId: widget.sessionId,
                    reports: widget.reports,
                    onChanged: widget.onChanged,
                  )
                : _NewReportForm(
                    students: students,
                    selectedStudent: _selectedStudent,
                    category: _category,
                    severity: _severity,
                    descriptionController: _descriptionController,
                    onStudentChanged: (value) => setState(() => _selectedStudent = value),
                    onCategoryChanged: (value) => setState(() => _category = value),
                    onSeverityChanged: (value) => setState(() => _severity = value),
                    onSubmit: _submitReport,
                  ),
          ),
        ],
      );
    });
  }

  Future<void> _submitReport() async {
    final student = _selectedStudent;
    if (student == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student selected for report.')),
      );
      return;
    }
    await LiveClassMalpracticeReportService.createReport(
      sessionId: widget.sessionId,
      participantId: student.id,
      participantName: student.displayName,
      registrationNumber: student.registrationNumber,
      category: _category,
      severity: _severity,
      description: _descriptionController.text,
      reportedBy: widget.reporterName,
      reporterRole: widget.reporterRole,
    );
    _descriptionController.clear();
    widget.onChanged();
    if (!mounted) return;
    setState(() => _showReports = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident report saved.')),
    );
  }
}

class _IncidentFab extends StatelessWidget {
  const _IncidentFab({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          heroTag: 'live-class-malpractice-report-control',
          onPressed: onPressed,
          icon: const Icon(Icons.gpp_maybe_rounded),
          label: const Text('Incidents'),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -8,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Colors.redAccent,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _IncidentSummary extends StatelessWidget {
  const _IncidentSummary({required this.summary});

  final LiveClassIncidentSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryChip(icon: Icons.list_alt_rounded, label: '${summary.total} total'),
        _SummaryChip(icon: Icons.report_problem_rounded, label: '${summary.open} open'),
        _SummaryChip(icon: Icons.priority_high_rounded, label: '${summary.escalated} escalated'),
        _SummaryChip(icon: Icons.done_all_rounded, label: '${summary.resolved} resolved'),
        _SummaryChip(icon: Icons.emergency_rounded, label: '${summary.critical} critical'),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

class _NewReportForm extends StatelessWidget {
  const _NewReportForm({
    required this.students,
    required this.selectedStudent,
    required this.category,
    required this.severity,
    required this.descriptionController,
    required this.onStudentChanged,
    required this.onCategoryChanged,
    required this.onSeverityChanged,
    required this.onSubmit,
  });

  final List<LiveSessionParticipant> students;
  final LiveSessionParticipant? selectedStudent;
  final String category;
  final String severity;
  final TextEditingController descriptionController;
  final ValueChanged<LiveSessionParticipant?> onStudentChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSeverityChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const Center(child: Text('No student participant yet.'));
    }
    return ListView(
      children: [
        DropdownButtonFormField<LiveSessionParticipant>(
          value: selectedStudent,
          items: [
            for (final student in students)
              DropdownMenuItem(
                value: student,
                child: Text(
                  '${student.displayName} • ${student.registrationNumber ?? 'Student'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onStudentChanged,
          decoration: const InputDecoration(
            labelText: 'Student',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: category,
          items: [
            for (final item in LiveClassIncidentCategory.values)
              DropdownMenuItem(value: item, child: Text(LiveClassIncidentCategory.label(item))),
          ],
          onChanged: (value) {
            if (value != null) onCategoryChanged(value);
          },
          decoration: const InputDecoration(
            labelText: 'Incident category',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: severity,
          items: [
            for (final item in LiveClassIncidentSeverity.values)
              DropdownMenuItem(value: item, child: Text(LiveClassIncidentSeverity.label(item))),
          ],
          onChanged: (value) {
            if (value != null) onSeverityChanged(value);
          },
          decoration: const InputDecoration(
            labelText: 'Severity',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          minLines: 4,
          maxLines: 7,
          decoration: const InputDecoration(
            labelText: 'Observation / evidence note',
            hintText: 'Example: Student repeatedly looked away from camera and appeared to receive help from another person.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save incident report'),
          ),
        ),
      ],
    );
  }
}

class _ReportsList extends StatelessWidget {
  const _ReportsList({
    required this.sessionId,
    required this.reports,
    required this.onChanged,
  });

  final String sessionId;
  final List<LiveClassMalpracticeReport> reports;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) return const Center(child: Text('No incident report yet.'));
    return ListView.separated(
      itemCount: reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ReportTile(
        sessionId: sessionId,
        report: reports[index],
        onChanged: onChanged,
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.sessionId,
    required this.report,
    required this.onChanged,
  });

  final String sessionId;
  final LiveClassMalpracticeReport report;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = _severityColor(report.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(_initials(report.participantName))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.participantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(report.registrationNumber ?? 'Student'),
                  ],
                ),
              ),
              Chip(
                label: Text(report.severityLabel),
                backgroundColor: tone.withValues(alpha: 0.16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(report.categoryLabel)),
              Chip(label: Text(report.status.toUpperCase())),
              Chip(label: Text('By ${report.reportedBy}')),
            ],
          ),
          const SizedBox(height: 8),
          Text(report.description, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!report.isEscalated && !report.isResolved && !report.isDismissed)
                OutlinedButton.icon(
                  onPressed: () => _update(context, LiveClassIncidentStatus.escalated),
                  icon: const Icon(Icons.priority_high_rounded),
                  label: const Text('Escalate'),
                ),
              if (!report.isResolved)
                FilledButton.tonalIcon(
                  onPressed: () => _update(context, LiveClassIncidentStatus.resolved),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Resolve'),
                ),
              if (!report.isDismissed)
                TextButton.icon(
                  onPressed: () => _update(context, LiveClassIncidentStatus.dismissed),
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Dismiss'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _update(BuildContext context, String status) async {
    await LiveClassMalpracticeReportService.updateStatus(
      sessionId: sessionId,
      reportId: report.id,
      status: status,
    );
    onChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report marked as $status.')),
      );
    }
  }

  static Color _severityColor(String severity) {
    return switch (severity) {
      LiveClassIncidentSeverity.low => Colors.blueAccent,
      LiveClassIncidentSeverity.medium => Colors.orangeAccent,
      LiveClassIncidentSeverity.high => Colors.deepOrangeAccent,
      LiveClassIncidentSeverity.critical => Colors.redAccent,
      _ => Colors.orangeAccent,
    };
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.substring(0, 1)
        : '';
    return '$first$last'.toUpperCase();
  }
}
