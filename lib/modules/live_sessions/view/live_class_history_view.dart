import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_student_notes_service.dart';
import '../../../data/services/submission_history_service.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class LiveClassHistoryView extends StatefulWidget {
  const LiveClassHistoryView({super.key});

  @override
  State<LiveClassHistoryView> createState() => _LiveClassHistoryViewState();
}

class _LiveClassHistoryViewState extends State<LiveClassHistoryView> {
  final LiveSessionsController controller = Get.find<LiveSessionsController>();
  late List<SubmissionHistoryRecord> attendanceRecords;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    attendanceRecords = SubmissionHistoryService.load().where((record) => record.isLiveClassAttendance).toList();
  }

  Future<void> _refresh() async {
    await controller.loadSessions();
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final completedSessions = controller.sessions.where((session) => session.isCompletedAt(now)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final items = _buildItems(completedSessions);
    final attended = items.where((item) => item.attendance != null).length;
    final notes = items.where((item) => item.hasNotes).length;
    final replay = items.where((item) => item.replayAvailable).length;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _HistoryHeader(
              total: items.length,
              attended: attended,
              notes: notes,
              replay: replay,
              onBack: () => Get.back<void>(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: items.isEmpty
                  ? ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: const [_EmptyHistoryCard()])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) => _HistoryCard(item: items[index]),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  List<_HistoryItem> _buildItems(List<LiveSessionModel> sessions) {
    final items = <_HistoryItem>[];
    final usedReceipts = <String>{};

    for (final session in sessions) {
      final attendance = _attendanceFor(session);
      if (attendance != null) usedReceipts.add(attendance.receiptNumber);
      items.add(_HistoryItem(
        courseCode: session.courseCode,
        title: session.title,
        lecturer: session.lecturerName,
        dateLabel: liveSessionDateTime(session.startTime),
        replayAvailable: session.recordingPolicy != LiveSessionRecordingPolicy.disabled,
        hasNotes: LiveClassStudentNotesService.load(session.id).trim().isNotEmpty,
        attendance: attendance,
        sortTime: session.startTime,
      ));
    }

    for (final record in attendanceRecords) {
      if (usedReceipts.contains(record.receiptNumber)) continue;
      items.add(_HistoryItem(
        courseCode: record.courseCode,
        title: record.title.replaceFirst('Live Class Attendance • ', ''),
        lecturer: 'Course lecturer',
        dateLabel: _formatDate(record.submittedAt),
        replayAvailable: false,
        hasNotes: false,
        attendance: record,
        sortTime: record.submittedAt,
      ));
    }

    items.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return items;
  }

  SubmissionHistoryRecord? _attendanceFor(LiveSessionModel session) {
    final title = session.title.toLowerCase();
    return attendanceRecords.firstWhereOrNull(
      (record) => record.courseCode.toUpperCase() == session.courseCode.toUpperCase() && record.title.toLowerCase().contains(title),
    );
  }
}

class _HistoryItem {
  const _HistoryItem({required this.courseCode, required this.title, required this.lecturer, required this.dateLabel, required this.replayAvailable, required this.hasNotes, required this.attendance, required this.sortTime});
  final String courseCode;
  final String title;
  final String lecturer;
  final String dateLabel;
  final bool replayAvailable;
  final bool hasNotes;
  final SubmissionHistoryRecord? attendance;
  final DateTime sortTime;
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.total, required this.attended, required this.notes, required this.replay, required this.onBack});
  final int total;
  final int attended;
  final int notes;
  final int replay;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [cs.primary, cs.secondary])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Live Class History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21))),
          const Icon(Icons.history_edu_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 12),
        Text('Past live classes, attendance records, saved notes, and replay availability.', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeaderPill(label: '$total classes'),
          _HeaderPill(label: '$attended attended'),
          _HeaderPill(label: '$notes notes saved'),
          _HeaderPill(label: '$replay replay'),
        ]),
      ]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});
  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final attendance = item.attendance;
    final statusColor = attendance == null ? Colors.orange.shade700 : Colors.green.shade700;
    final attendanceLabel = attendance == null ? 'Not recorded' : attendance.scoreLabel;
    final rate = attendance == null ? '0%' : '${attendance.percentage}%';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(18)), child: Icon(Icons.live_tv_outlined, color: cs.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item.courseCode} • ${item.title}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${item.lecturer} • ${item.dateLabel}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w700)),
          ])),
          _StatusChip(label: attendance == null ? 'Missing' : 'Recorded', color: statusColor),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _MiniBadge(text: 'Attendance $attendanceLabel', color: statusColor),
          _MiniBadge(text: 'Rate $rate', color: cs.primary),
          _MiniBadge(text: item.hasNotes ? 'Notes saved' : 'No notes', color: item.hasNotes ? Colors.green.shade700 : Colors.orange.shade700),
          _MiniBadge(text: item.replayAvailable ? 'Replay available' : 'No replay', color: item.replayAvailable ? cs.secondary : Colors.orange.shade700),
        ]),
        if (attendance != null) ...[
          const SizedBox(height: 10),
          _InfoRow(label: 'Receipt', value: attendance.receiptNumber),
          _InfoRow(label: 'Status', value: attendance.status),
        ],
      ]),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(children: [
        Icon(Icons.history_edu_outlined, size: 46, color: cs.primary),
        const SizedBox(height: 12),
        Text('No live class history yet', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 8),
        Text('After attending live classes, your attendance records and saved class notes will appear here.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)));
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: 0.14))), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(constraints: const BoxConstraints(maxWidth: 116), padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)), child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)))]));
}

String _formatDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
