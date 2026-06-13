import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_student_notes_service.dart';
import '../../../data/services/submission_history_service.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class LiveClassHistoryWithReplayView extends StatefulWidget {
  const LiveClassHistoryWithReplayView({super.key});

  @override
  State<LiveClassHistoryWithReplayView> createState() => _LiveClassHistoryWithReplayViewState();
}

class _LiveClassHistoryWithReplayViewState extends State<LiveClassHistoryWithReplayView> {
  final controller = Get.find<LiveSessionsController>();

  List<SubmissionHistoryRecord> get records => SubmissionHistoryService.load().where((e) => e.isLiveClassAttendance).toList();

  Future<void> refresh() async {
    await controller.loadSessions();
    setState(() {});
  }

  void openReplay(LiveSessionModel session) {
    if (!session.allowLecturerRecording) {
      Get.snackbar('Replay unavailable', 'This live class was not recorded.');
      return;
    }
    Get.toNamed(Routes.liveSessionReplay, arguments: {'sessionId': session.id});
  }

  Future<void> openNotes(LiveSessionModel session) async {
    final text = TextEditingController(text: LiveClassStudentNotesService.load(session.id));
    await Get.bottomSheet<void>(
      _NotesSheet(
        session: session,
        controller: text,
        onCopy: () async {
          await Clipboard.setData(ClipboardData(text: text.text.trim().isEmpty ? _notesTemplate(session) : text.text.trim()));
          Get.snackbar('Copied', 'Live class notes copied.');
        },
        onSave: () async {
          await LiveClassStudentNotesService.save(sessionId: session.id, note: text.text);
          Get.back<void>();
          if (mounted) setState(() {});
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
    text.dispose();
  }

  String _notesTemplate(LiveSessionModel session) {
    return 'Live Class Notes\nCourse: ${session.courseCode}\nClass: ${session.title}\nLecturer: ${session.lecturerName}\nDate: ${liveSessionDateTime(session.startTime)}\n\nMy Notes:\n';
  }

  SubmissionHistoryRecord? attendanceFor(LiveSessionModel session) {
    final title = session.title.toLowerCase();
    return records.firstWhereOrNull((record) => record.courseCode.toUpperCase() == session.courseCode.toUpperCase() && record.title.toLowerCase().contains(title));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sessions = controller.sessions.where((s) => s.isCompletedAt(now)).toList()..sort((a, b) => b.startTime.compareTo(a.startTime));
    final notesCount = sessions.where((s) => LiveClassStudentNotesService.load(s.id).trim().isNotEmpty).length;
    final replayCount = sessions.where((s) => s.allowLecturerRecording).length;
    final attendedCount = sessions.where((s) => attendanceFor(s) != null).length;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: _Header(total: sessions.length, attended: attendedCount, notes: notesCount, replay: replayCount),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: sessions.isEmpty
                  ? ListView(padding: const EdgeInsets.fromLTRB(16, 20, 16, 24), children: const [_EmptyCard()])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _HistoryReplayCard(
                          session: session,
                          attendance: attendanceFor(session),
                          notesSaved: LiveClassStudentNotesService.load(session.id).trim().isNotEmpty,
                          onReplay: () => openReplay(session),
                          onNotes: () => openNotes(session),
                        );
                      },
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.attended, required this.notes, required this.replay});
  final int total;
  final int attended;
  final int notes;
  final int replay;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [cs.primary, cs.secondary])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: () => Get.back<void>(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Live Class History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21))),
          const Icon(Icons.history_edu_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 12),
        Text('Past classes, attendance, saved notes, and replay access.', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [_Pill('$total classes'), _Pill('$attended attended'), _Pill('$notes notes'), _Pill('$replay replay')]),
      ]),
    );
  }
}

class _HistoryReplayCard extends StatelessWidget {
  const _HistoryReplayCard({required this.session, required this.attendance, required this.notesSaved, required this.onReplay, required this.onNotes});
  final LiveSessionModel session;
  final SubmissionHistoryRecord? attendance;
  final bool notesSaved;
  final VoidCallback onReplay;
  final VoidCallback onNotes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(Icons.live_tv_outlined, color: cs.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${session.courseCode} • ${session.title}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${session.lecturerName} • ${liveSessionDateTime(session.startTime)}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w700)),
          ])),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Badge('Attendance ${attendance?.scoreLabel ?? 'Not recorded'}', attendance == null ? Colors.orange.shade700 : Colors.green.shade700),
          _Badge(session.allowLecturerRecording ? 'Replay available' : 'No replay', session.allowLecturerRecording ? cs.secondary : Colors.orange.shade700),
          _Badge(notesSaved ? 'Notes saved' : 'No notes', notesSaved ? Colors.green.shade700 : Colors.orange.shade700),
        ]),
        if (attendance != null) ...[
          const SizedBox(height: 10),
          _InfoRow('Receipt', attendance!.receiptNumber),
          _InfoRow('Status', attendance!.status),
        ],
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: onNotes, icon: const Icon(Icons.edit_note_outlined), label: Text(notesSaved ? 'Open notes' : 'Add notes'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: session.allowLecturerRecording ? onReplay : null, icon: const Icon(Icons.replay_rounded), label: Text(session.allowLecturerRecording ? 'Open replay' : 'No replay'))),
        ]),
      ]),
    );
  }
}

class _NotesSheet extends StatelessWidget {
  const _NotesSheet({required this.session, required this.controller, required this.onCopy, required this.onSave});
  final LiveSessionModel session;
  final TextEditingController controller;
  final VoidCallback onCopy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.70,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 16),
          Text('${session.courseCode} • ${session.title}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 12),
          Expanded(child: TextField(controller: controller, expands: true, minLines: null, maxLines: null, textAlignVertical: TextAlignVertical.top, decoration: const InputDecoration(hintText: 'Write or review your live class notes...'))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: onCopy, icon: const Icon(Icons.copy_rounded), label: const Text('Copy notes'))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save_rounded), label: const Text('Save notes'))),
          ]),
        ]),
      )),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();
  @override
  Widget build(BuildContext context) => const Center(child: Text('No live class history yet.'));
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(999)), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)));
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)), child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900)))]));
}
