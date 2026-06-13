import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_student_notes_service.dart';
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

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments ?? {}) as Map;
    sessionId = args['sessionId']?.toString() ?? '';
    if (controller.sessions.isEmpty) {
      controller.loadSessions();
    }
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
                onPlayPause: () => setState(() => playing = !playing),
                onSeek: (value) => setState(() => progress = value),
              ),
              const SizedBox(height: 12),
              _ReplaySummaryGrid(session: session, receipt: receipt, notesSaved: notes.isNotEmpty),
              const SizedBox(height: 12),
              _ReplaySection(title: 'Class agenda timeline', icon: Icons.format_list_bulleted_rounded, children: _agendaTimeline(session)),
              const SizedBox(height: 12),
              _ReplaySection(
                title: 'Class materials',
                icon: Icons.folder_copy_outlined,
                children: session.materials.isEmpty
                    ? const [_ReplayLine(text: 'No replay material has been attached yet.')]
                    : session.materials.map((item) => _ReplayLine(text: '${item.title} — ${item.status.isEmpty ? item.subtitle : item.status}')).toList(),
              ),
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
  const _ReplayPlayerCard({required this.session, required this.replayAvailable, required this.progress, required this.playing, required this.onPlayPause, required this.onSeek});
  final LiveSessionModel session;
  final bool replayAvailable;
  final double progress;
  final bool playing;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;

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
      ]),
    );
  }

  String _progressLabel(int duration, double progress) {
    final current = (duration * progress).round();
    return '${current}m / ${duration}m';
  }
}

class _ReplaySummaryGrid extends StatelessWidget {
  const _ReplaySummaryGrid({required this.session, required this.receipt, required this.notesSaved});
  final LiveSessionModel session;
  final SubmissionHistoryRecord? receipt;
  final bool notesSaved;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 10, runSpacing: 10, children: [
      _ReplayMetric(label: 'Duration', value: liveSessionMinutesLabel(session.durationMinutes), icon: Icons.timer_outlined),
      _ReplayMetric(label: 'Lecturer', value: session.lecturerName, icon: Icons.person_outline_rounded),
      _ReplayMetric(label: 'Attendance', value: receipt?.scoreLabel ?? 'Not recorded', icon: Icons.fact_check_outlined),
      _ReplayMetric(label: 'Notes', value: notesSaved ? 'Saved' : 'No notes', icon: Icons.edit_note_outlined),
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
