import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    attendanceRecords = SubmissionHistoryService.load()
        .where((record) => record.isLiveClassAttendance)
        .toList();
  }

  Future<void> _refresh() async {
    await controller.loadSessions();
    setState(_load);
  }

  Future<void> _openNotes(_HistoryItem item) async {
    final sessionId = item.sessionId;
    if (sessionId == null) {
      Get.snackbar('Notes unavailable', 'This older attendance record is not linked to a live class session.');
      return;
    }

    final notesController = TextEditingController(
      text: LiveClassStudentNotesService.load(sessionId),
    );

    await Get.bottomSheet<void>(
      _LiveClassNotesSheet(
        item: item,
        controller: notesController,
        onCopyNotes: () => _copyNotes(item, notesController.text),
        onCopyStudyDocument: () => _copyStudyDocument(item, notesController.text),
        onSave: () async {
          await LiveClassStudentNotesService.save(
            sessionId: sessionId,
            note: notesController.text,
          );
          Get.back<void>();
          if (!mounted) return;
          setState(_load);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Live class notes saved.')),
          );
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
    notesController.dispose();
    if (mounted) setState(_load);
  }

  Future<void> _copyNotes(_HistoryItem item, String notes) async {
    final text = notes.trim().isEmpty ? _emptyNotesTemplate(item) : notes.trim();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes copied to clipboard.')),
    );
  }

  Future<void> _copyStudyDocument(_HistoryItem item, String notes) async {
    await Clipboard.setData(ClipboardData(text: _studyDocumentText(item, notes)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Study document text copied.')),
    );
  }

  String _emptyNotesTemplate(_HistoryItem item) {
    return 'Live Class Notes\n'
        'Course: ${item.courseCode}\n'
        'Class: ${item.title}\n'
        'Lecturer: ${item.lecturer}\n'
        'Date: ${item.dateLabel}\n\n'
        'My Notes:\n';
  }

  String _studyDocumentText(_HistoryItem item, String notes) {
    final attendance = item.attendance;
    final body = notes.trim().isEmpty ? 'No notes written yet.' : notes.trim();
    return 'LIVE CLASS STUDY NOTES\n\n'
        'Course: ${item.courseCode}\n'
        'Class: ${item.title}\n'
        'Lecturer: ${item.lecturer}\n'
        'Date: ${item.dateLabel}\n'
        'Attendance: ${attendance?.scoreLabel ?? 'Not recorded'}\n'
        'Attendance Rate: ${attendance == null ? '0%' : '${attendance.percentage}%'}\n'
        'Replay: ${item.replayAvailable ? 'Available' : 'Not available'}\n'
        'Receipt: ${attendance?.receiptNumber ?? 'Not available'}\n\n'
        'NOTES\n'
        '$body\n\n'
        'REVISION POINTS\n'
        '- Review this class note before the next lecture.\n'
        '- Convert key explanations into questions.\n'
        '- Mark unclear areas for lecturer follow-up.';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final completedSessions = controller.sessions
        .where((session) => session.isCompletedAt(now))
        .toList()
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
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: const [_EmptyHistoryCard()],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _HistoryCard(
                          item: item,
                          onOpenNotes: item.sessionId == null ? null : () => _openNotes(item),
                        );
                      },
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
      final note = LiveClassStudentNotesService.load(session.id).trim();
      if (attendance != null) usedReceipts.add(attendance.receiptNumber);
      items.add(
        _HistoryItem(
          sessionId: session.id,
          courseCode: session.courseCode,
          title: session.title,
          lecturer: session.lecturerName,
          dateLabel: liveSessionDateTime(session.startTime),
          replayAvailable: session.allowLecturerRecording,
          hasNotes: note.isNotEmpty,
          attendance: attendance,
          sortTime: session.startTime,
        ),
      );
    }

    for (final record in attendanceRecords) {
      if (usedReceipts.contains(record.receiptNumber)) continue;
      items.add(
        _HistoryItem(
          sessionId: null,
          courseCode: record.courseCode,
          title: record.title.replaceFirst('Live Class Attendance • ', ''),
          lecturer: 'Course lecturer',
          dateLabel: _formatDate(record.submittedAt),
          replayAvailable: false,
          hasNotes: false,
          attendance: record,
          sortTime: record.submittedAt,
        ),
      );
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
  const _HistoryItem({
    required this.sessionId,
    required this.courseCode,
    required this.title,
    required this.lecturer,
    required this.dateLabel,
    required this.replayAvailable,
    required this.hasNotes,
    required this.attendance,
    required this.sortTime,
  });

  final String? sessionId;
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
      ),
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
  const _HistoryCard({required this.item, required this.onOpenNotes});
  final _HistoryItem item;
  final VoidCallback? onOpenNotes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final attendance = item.attendance;
    final statusColor = attendance == null ? Colors.orange.shade700 : Colors.green.shade700;
    final attendanceLabel = attendance == null ? 'Not recorded' : attendance.scoreLabel;
    final rate = attendance == null ? '0%' : '${attendance.percentage}%';
    final noteLabel = item.hasNotes ? 'Open notes' : 'Add notes';

    return InkWell(
      onTap: onOpenNotes,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenNotes,
              icon: const Icon(Icons.edit_note_outlined),
              label: Text(onOpenNotes == null ? 'Notes unavailable' : noteLabel),
            ),
          ),
        ]),
      ),
    );
  }
}

class _LiveClassNotesSheet extends StatelessWidget {
  const _LiveClassNotesSheet({
    required this.item,
    required this.controller,
    required this.onCopyNotes,
    required this.onCopyStudyDocument,
    required this.onSave,
  });
  final _HistoryItem item;
  final TextEditingController controller;
  final VoidCallback onCopyNotes;
  final VoidCallback onCopyStudyDocument;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)))),
            const SizedBox(height: 16),
            Row(children: [
              CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(Icons.edit_note_outlined, color: cs.primary)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Live class notes', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 3),
                Text('${item.courseCode} • ${item.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w700)),
              ])),
              IconButton(onPressed: () => Get.back<void>(), icon: const Icon(Icons.close_rounded)),
            ]),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: controller,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Write or review your live class notes...',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(onPressed: onCopyNotes, icon: const Icon(Icons.copy_rounded), label: const Text('Copy notes')),
              OutlinedButton.icon(onPressed: onCopyStudyDocument, icon: const Icon(Icons.description_outlined), label: const Text('Copy study document')),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save_rounded), label: const Text('Save notes'))),
          ]),
        ),
      ),
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
