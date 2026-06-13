import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_student_notes_service.dart';
import '../../../data/services/live_replay_learning_tools_service.dart';
import '../../../data/services/submission_history_service.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class LiveClassReplayView extends StatefulWidget {
  const LiveClassReplayView({super.key});

  @override
  State<LiveClassReplayView> createState() => _LiveClassReplayViewState();
}

class _LiveClassReplayViewState extends State<LiveClassReplayView> {
  final LiveSessionsController controller = Get.find<LiveSessionsController>();
  late final String sessionId;
  double progress = 0.18;
  bool playing = false;
  List<LiveReplayBookmark> bookmarks = const [];

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments ?? {}) as Map;
    sessionId = args['sessionId']?.toString() ?? '';
    _reloadBookmarks();
    if (controller.sessions.isEmpty) {
      controller.loadSessions();
    }
  }

  void _reloadBookmarks() {
    bookmarks = LiveReplayLearningToolsService.loadBookmarks(sessionId);
  }

  int _currentMinute(LiveSessionModel session) {
    final raw = (session.durationMinutes * progress).round();
    return raw.clamp(0, session.durationMinutes).toInt();
  }

  void _seekToBookmark(LiveSessionModel session, LiveReplayBookmark bookmark) {
    if (session.durationMinutes <= 0) return;
    setState(() {
      progress = (bookmark.minute / session.durationMinutes).clamp(0.0, 1.0).toDouble();
      playing = true;
    });
    Get.snackbar('Replay moved', 'Jumped to ${bookmark.timeLabel}.');
  }

  Future<void> _addBookmark(LiveSessionModel session) async {
    final minute = _currentMinute(session);
    final titleController = TextEditingController(
      text: 'Moment at ${LiveReplayLearningToolsService.minuteLabel(minute)}',
    );
    final noteController = TextEditingController();

    await Get.bottomSheet<void>(
      _BookmarkSheet(
        session: session,
        minute: minute,
        titleController: titleController,
        noteController: noteController,
        onSave: () async {
          await LiveReplayLearningToolsService.createBookmark(
            sessionId: session.id,
            minute: minute,
            title: titleController.text,
            note: noteController.text,
          );
          Get.back<void>();
          if (!mounted) return;
          setState(_reloadBookmarks);
          Get.snackbar('Bookmark saved', 'Replay moment saved at ${LiveReplayLearningToolsService.minuteLabel(minute)}.');
        },
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );

    titleController.dispose();
    noteController.dispose();
  }

  Future<void> _toggleImportantMoment(LiveSessionModel session) async {
    final minute = _currentMinute(session);
    final existing = bookmarks.firstWhereOrNull(
      (item) => item.minute == minute && item.isImportant,
    );

    if (existing != null) {
      await LiveReplayLearningToolsService.saveBookmark(
        existing.copyWith(isImportant: false),
      );
      if (!mounted) return;
      setState(_reloadBookmarks);
      Get.snackbar('Updated', 'Important mark removed from ${existing.timeLabel}.');
      return;
    }

    await LiveReplayLearningToolsService.createBookmark(
      sessionId: session.id,
      minute: minute,
      title: 'Important point at ${LiveReplayLearningToolsService.minuteLabel(minute)}',
      note: 'Marked during replay revision.',
      isImportant: true,
    );
    if (!mounted) return;
    setState(_reloadBookmarks);
    Get.snackbar('Important moment saved', 'This replay point has been marked for revision.');
  }

  Future<void> _deleteBookmark(LiveReplayBookmark bookmark) async {
    await LiveReplayLearningToolsService.deleteBookmark(
      sessionId: bookmark.sessionId,
      bookmarkId: bookmark.id,
    );
    if (!mounted) return;
    setState(_reloadBookmarks);
    Get.snackbar('Deleted', 'Replay bookmark removed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(() {
          final session = controller.sessions.firstWhereOrNull((item) => item.id == sessionId);
          if (session == null && controller.isLoadingSessions.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (session == null) {
            return _ReplayUnavailable(onBack: () => Get.back<void>());
          }

          final notes = LiveClassStudentNotesService.load(session.id).trim();
          final receipt = _attendanceFor(session);
          final replayAvailable = session.allowLecturerRecording;
          final importantCount = bookmarks.where((item) => item.isImportant).length;
          final revisionQuestions = LiveReplayLearningToolsService.buildQuickRevisionQuestions(
            session: session,
            notes: notes,
            bookmarks: bookmarks,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _ReplayHeader(session: session, onBack: () => Get.back<void>()),
              const SizedBox(height: 12),
              _ReplayPlayerCard(
                session: session,
                replayAvailable: replayAvailable,
                progress: progress,
                playing: playing,
                currentMinute: _currentMinute(session),
                onPlayPause: () => setState(() => playing = !playing),
                onSeek: (value) => setState(() => progress = value),
                onBookmark: replayAvailable ? () => _addBookmark(session) : null,
                onImportant: replayAvailable ? () => _toggleImportantMoment(session) : null,
                onRevision: replayAvailable
                    ? () => Get.snackbar(
                          'Quick revision ready',
                          '${revisionQuestions.length} replay questions generated below.',
                        )
                    : null,
              ),
              const SizedBox(height: 12),
              _ReplaySummaryGrid(
                session: session,
                receipt: receipt,
                notesSaved: notes.isNotEmpty,
                bookmarkCount: bookmarks.length,
                importantCount: importantCount,
              ),
              const SizedBox(height: 12),
              _ReplayLearningToolsCard(
                session: session,
                bookmarks: bookmarks,
                currentMinute: _currentMinute(session),
                onAddBookmark: replayAvailable ? () => _addBookmark(session) : null,
                onMarkImportant: replayAvailable ? () => _toggleImportantMoment(session) : null,
                onSeekBookmark: (bookmark) => _seekToBookmark(session, bookmark),
                onDeleteBookmark: _deleteBookmark,
              ),
              const SizedBox(height: 12),
              _ReplaySection(
                title: 'Class agenda timeline',
                icon: Icons.format_list_bulleted_rounded,
                children: _agendaTimeline(session),
              ),
              const SizedBox(height: 12),
              _ReplaySection(
                title: 'Class materials',
                icon: Icons.folder_copy_outlined,
                children: session.materials.isEmpty
                    ? const [_ReplayLine(text: 'No replay material has been attached yet.')]
                    : session.materials
                          .map((item) => _ReplayLine(text: '${item.title} — ${item.status.isEmpty ? item.subtitle : item.status}'))
                          .toList(),
              ),
              const SizedBox(height: 12),
              _QuickRevisionQuestionsCard(questions: revisionQuestions),
              const SizedBox(height: 12),
              _SavedNotesPreview(session: session, notes: notes),
            ],
          );
        }),
      ),
    );
  }

  List<Widget> _agendaTimeline(LiveSessionModel session) {
    if (session.agenda.isEmpty) {
      return const [_ReplayLine(text: 'No agenda item was published for this class.')];
    }
    return List.generate(session.agenda.length, (index) {
      final offset = index * 10;
      final label = offset == 0 ? '00:00' : '${offset.toString().padLeft(2, '0')}:00';
      return _ReplayLine(text: '$label  ${session.agenda[index]}');
    });
  }

  SubmissionHistoryRecord? _attendanceFor(LiveSessionModel session) {
    final title = session.title.toLowerCase();
    return SubmissionHistoryService.load().firstWhereOrNull(
      (record) => record.isLiveClassAttendance && record.courseCode.toUpperCase() == session.courseCode.toUpperCase() && record.title.toLowerCase().contains(title),
    );
  }
}

class _ReplayHeader extends StatelessWidget {
  const _ReplayHeader({required this.session, required this.onBack});
  final LiveSessionModel session;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [cs.primary, cs.secondary])),
      child: Row(children: [
        IconButton.filledTonal(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Live Class Replay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 21)),
          const SizedBox(height: 5),
          Text('${session.courseCode} • ${session.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(liveSessionDayTimeRange(session.startTime, session.endTime), style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w700)),
        ])),
        const Icon(Icons.replay_circle_filled_rounded, color: Colors.white, size: 30),
      ]),
    );
  }
}

class _ReplayPlayerCard extends StatelessWidget {
  const _ReplayPlayerCard({
    required this.session,
    required this.replayAvailable,
    required this.progress,
    required this.playing,
    required this.currentMinute,
    required this.onPlayPause,
    required this.onSeek,
    required this.onBookmark,
    required this.onImportant,
    required this.onRevision,
  });

  final LiveSessionModel session;
  final bool replayAvailable;
  final double progress;
  final bool playing;
  final int currentMinute;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback? onBookmark;
  final VoidCallback? onImportant;
  final VoidCallback? onRevision;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: [Colors.black, cs.primary.withValues(alpha: 0.72)])),
            child: Center(
              child: replayAvailable
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 76),
                      const SizedBox(height: 10),
                      const Text('Replay preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                      const SizedBox(height: 6),
                      Text('Recorded lecture playback will stream here when backend media storage is connected.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w700)),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.videocam_off_outlined, color: Colors.white, size: 64),
                      const SizedBox(height: 10),
                      const Text('Replay not available', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                      const SizedBox(height: 6),
                      Text('This class was not marked for lecturer recording.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          IconButton.filled(onPressed: replayAvailable ? onPlayPause : null, icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded)),
          Expanded(child: Slider(value: progress.clamp(0.0, 1.0).toDouble(), onChanged: replayAvailable ? onSeek : null)),
          Text(_progressLabel(session.durationMinutes, progress), style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _ReplayActionChip(
            icon: Icons.bookmark_add_outlined,
            label: 'Bookmark ${LiveReplayLearningToolsService.minuteLabel(currentMinute)}',
            onPressed: onBookmark,
          ),
          _ReplayActionChip(
            icon: Icons.star_border_rounded,
            label: 'Mark important',
            onPressed: onImportant,
          ),
          _ReplayActionChip(
            icon: Icons.quiz_outlined,
            label: 'Quick questions',
            onPressed: onRevision,
          ),
        ]),
      ]),
    );
  }

  String _progressLabel(int duration, double progress) {
    final current = (duration * progress).round();
    return '${current}m / ${duration}m';
  }
}

class _ReplayActionChip extends StatelessWidget {
  const _ReplayActionChip({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
  }
}

class _ReplaySummaryGrid extends StatelessWidget {
  const _ReplaySummaryGrid({required this.session, required this.receipt, required this.notesSaved, required this.bookmarkCount, required this.importantCount});
  final LiveSessionModel session;
  final SubmissionHistoryRecord? receipt;
  final bool notesSaved;
  final int bookmarkCount;
  final int importantCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _ReplayMetric(label: 'Duration', value: liveSessionMinutesLabel(session.durationMinutes), icon: Icons.timer_outlined),
      _ReplayMetric(label: 'Lecturer', value: session.lecturerName, icon: Icons.person_outline_rounded),
      _ReplayMetric(label: 'Attendance', value: receipt?.scoreLabel ?? 'Not recorded', icon: Icons.fact_check_outlined),
      _ReplayMetric(label: 'Notes', value: notesSaved ? 'Saved' : 'No notes', icon: Icons.edit_note_outlined),
      _ReplayMetric(label: 'Bookmarks', value: '$bookmarkCount saved', icon: Icons.bookmark_outline_rounded),
      _ReplayMetric(label: 'Important', value: '$importantCount marked', icon: Icons.star_border_rounded),
    ]);
  }
}

class _ReplayMetric extends StatelessWidget {
  const _ReplayMetric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: cs.primary),
        const SizedBox(height: 9),
        Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.62), fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 3),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _ReplayLearningToolsCard extends StatelessWidget {
  const _ReplayLearningToolsCard({
    required this.session,
    required this.bookmarks,
    required this.currentMinute,
    required this.onAddBookmark,
    required this.onMarkImportant,
    required this.onSeekBookmark,
    required this.onDeleteBookmark,
  });

  final LiveSessionModel session;
  final List<LiveReplayBookmark> bookmarks;
  final int currentMinute;
  final VoidCallback? onAddBookmark;
  final VoidCallback? onMarkImportant;
  final ValueChanged<LiveReplayBookmark> onSeekBookmark;
  final Future<void> Function(LiveReplayBookmark bookmark) onDeleteBookmark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.school_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Replay learning tools', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 8),
        Text('Save exact replay moments, mark high-value points, and return to them during revision.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700, height: 1.30)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: onAddBookmark, icon: const Icon(Icons.bookmark_add_outlined), label: Text('Bookmark ${LiveReplayLearningToolsService.minuteLabel(currentMinute)}')),
          OutlinedButton.icon(onPressed: onMarkImportant, icon: const Icon(Icons.star_border_rounded), label: const Text('Mark important')),
        ]),
        const SizedBox(height: 12),
        if (bookmarks.isEmpty)
          _ReplayLine(text: 'No bookmarks yet. Move the replay slider to a key point and save the moment.')
        else
          ...bookmarks.map(
            (bookmark) => _BookmarkTile(
              bookmark: bookmark,
              onTap: () => onSeekBookmark(bookmark),
              onDelete: () => onDeleteBookmark(bookmark),
            ),
          ),
      ]),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark, required this.onTap, required this.onDelete});
  final LiveReplayBookmark bookmark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.primary.withValues(alpha: 0.10))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(radius: 18, backgroundColor: cs.primary.withValues(alpha: 0.12), child: Icon(bookmark.isImportant ? Icons.star_rounded : Icons.bookmark_rounded, color: cs.primary, size: 19)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(bookmark.timeLabel, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
              if (bookmark.isImportant) ...[
                const SizedBox(width: 7),
                _SmallTag(text: 'Important', color: Colors.orange.shade700),
              ],
            ]),
            const SizedBox(height: 3),
            Text(bookmark.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
            if (bookmark.note.trim().isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(bookmark.note, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w700)),
            ],
          ])),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      ),
    );
  }
}

class _QuickRevisionQuestionsCard extends StatelessWidget {
  const _QuickRevisionQuestionsCard({required this.questions});
  final List<LiveReplayRevisionQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.quiz_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Quick revision questions from replay', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
          _SmallTag(text: '${questions.length} items', color: cs.secondary),
        ]),
        const SizedBox(height: 8),
        Text('Generated from the replay agenda, class materials, saved notes, and important moments.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700, height: 1.30)),
        const SizedBox(height: 10),
        ...questions.map((item) => _RevisionQuestionTile(question: item)),
      ]),
    );
  }
}

class _RevisionQuestionTile extends StatelessWidget {
  const _RevisionQuestionTile({required this.question});
  final LiveReplayRevisionQuestion question;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.035), borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(Icons.help_outline_rounded, color: cs.primary),
        title: Text(question.question, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
        subtitle: Text('${question.sourceLabel} • ${question.timeLabel}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.58), fontWeight: FontWeight.w700)),
        children: [
          Align(alignment: Alignment.centerLeft, child: Text(question.answerGuide, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700, height: 1.35))),
        ],
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _ReplaySection extends StatelessWidget {
  const _ReplaySection({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: cs.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)))]),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }
}

class _ReplayLine extends StatelessWidget {
  const _ReplayLine({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.74), fontWeight: FontWeight.w700, height: 1.30))),
      ]),
    );
  }
}

class _SavedNotesPreview extends StatelessWidget {
  const _SavedNotesPreview({required this.session, required this.notes});
  final LiveSessionModel session;
  final String notes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.edit_note_outlined, color: cs.primary), const SizedBox(width: 10), Expanded(child: Text('Saved class notes', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)))]),
        const SizedBox(height: 10),
        Text(notes.isEmpty ? 'No notes were saved for this class yet.' : notes, maxLines: 8, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.74), fontWeight: FontWeight.w700, height: 1.35)),
      ]),
    );
  }
}

class _BookmarkSheet extends StatelessWidget {
  const _BookmarkSheet({
    required this.session,
    required this.minute,
    required this.titleController,
    required this.noteController,
    required this.onSave,
  });

  final LiveSessionModel session;
  final int minute;
  final TextEditingController titleController;
  final TextEditingController noteController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: MediaQuery.viewInsetsOf(context).bottom + 16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)))),
        const SizedBox(height: 16),
        Text('Add replay bookmark', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 4),
        Text('${session.courseCode} • ${LiveReplayLearningToolsService.minuteLabel(minute)}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.64), fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        TextField(controller: titleController, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Moment title', hintText: 'Example: Lecturer explained database indexing')),
        const SizedBox(height: 10),
        TextField(controller: noteController, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Short note', hintText: 'Why should you return to this moment?')),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => Get.back<void>(), icon: const Icon(Icons.close_rounded), label: const Text('Cancel'))),
          const SizedBox(width: 10),
          Expanded(child: FilledButton.icon(onPressed: () => onSave(), icon: const Icon(Icons.save_rounded), label: const Text('Save bookmark'))),
        ]),
      ])),
    );
  }
}

class _ReplayUnavailable extends StatelessWidget {
  const _ReplayUnavailable({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.replay_circle_filled_outlined, color: cs.primary, size: 48),
          const SizedBox(height: 10),
          Text('Replay not found', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text('The selected live class could not be found locally. Pull to refresh Live Sessions and try again.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded), label: const Text('Back')),
        ]),
      ),
    );
  }
}
