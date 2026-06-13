import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class LiveSessionsHubView extends StatefulWidget {
  const LiveSessionsHubView({super.key});

  @override
  State<LiveSessionsHubView> createState() => _LiveSessionsHubViewState();
}

class _LiveSessionsHubViewState extends State<LiveSessionsHubView> {
  final LiveSessionsController controller = Get.find<LiveSessionsController>();
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final profile = StudentProfileStorage.load();
    final registeredCourses = profile?.selectedCourses.map((e) => e.trim().toUpperCase()).toSet() ?? const <String>{};

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _LiveClassHero(
              studentName: profile?.fullName ?? 'Student',
              onBack: () => Get.back<void>(),
              onHistory: () => Get.toNamed(Routes.liveClassHistory),
            ),
          ),
          Expanded(
            child: Obx(() {
              final now = DateTime.now();
              final allSessions = controller.sessions
                  .where((session) => registeredCourses.isEmpty || registeredCourses.contains(session.courseCode.trim().toUpperCase()))
                  .toList()
                ..sort((a, b) => _sessionWeight(a, now).compareTo(_sessionWeight(b, now)));
              final visibleSessions = _filterSessions(allSessions, now);

              if (controller.isLoadingSessions.value && allSessions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadSessions(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: [
                    _SummaryStrip(
                      live: allSessions.where((item) => item.isLiveAt(now)).length,
                      upcoming: allSessions.where((item) => item.isUpcomingAt(now)).length,
                      replay: allSessions.where((item) => item.isCompletedAt(now)).length,
                    ),
                    const SizedBox(height: 12),
                    _HistoryShortcutCard(onTap: () => Get.toNamed(Routes.liveClassHistory)),
                    const SizedBox(height: 12),
                    _ControlRoomShortcutCard(onTap: () => Get.toNamed(Routes.liveChiefOverview)),
                    const SizedBox(height: 12),
                    const _ReadinessCard(),
                    const SizedBox(height: 12),
                    _FilterBar(selected: selectedFilter, onChanged: (value) => setState(() => selectedFilter = value)),
                    const SizedBox(height: 12),
                    if (visibleSessions.isEmpty)
                      _EmptyState(filter: selectedFilter)
                    else
                      ...visibleSessions.map((session) => _LiveClassCard(session: session, onJoin: () => _joinSession(session, profile), onDetails: () => _showDetails(session))),
                  ],
                ),
              );
            }),
          ),
        ]),
      ),
    );
  }

  int _sessionWeight(LiveSessionModel session, DateTime now) {
    if (session.isLiveAt(now)) return 0;
    if (session.isUpcomingAt(now)) return 1;
    return 2;
  }

  List<LiveSessionModel> _filterSessions(List<LiveSessionModel> sessions, DateTime now) {
    switch (selectedFilter) {
      case 'Live':
        return sessions.where((item) => item.isLiveAt(now)).toList();
      case 'Today':
        return sessions.where((item) => item.startTime.year == now.year && item.startTime.month == now.month && item.startTime.day == now.day).toList();
      case 'Upcoming':
        return sessions.where((item) => item.isUpcomingAt(now)).toList();
      case 'Replay':
        return sessions.where((item) => item.isCompletedAt(now)).toList();
      default:
        return sessions;
    }
  }

  void _joinSession(LiveSessionModel session, dynamic profile) {
    final now = DateTime.now();
    final route = session.isCompletedAt(now) ? Routes.liveSessionReplay : Routes.liveSessionRoom;
    Get.toNamed(
      route,
      arguments: {
        'sessionId': session.id,
        'role': LiveSessionRole.student,
        'displayName': profile?.fullName ?? 'Student',
        'registrationNumber': profile?.matricNo ?? profile?.email ?? 'student-demo',
      },
    );
  }

  void _showDetails(LiveSessionModel session) {
    Get.bottomSheet<void>(_LiveClassDetailsSheet(session: session), isScrollControlled: true, ignoreSafeArea: false);
  }
}

class _LiveClassHero extends StatelessWidget {
  const _LiveClassHero({required this.studentName, required this.onBack, required this.onHistory});
  final String studentName;
  final VoidCallback onBack;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [cs.primary, cs.secondary]), boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 14), color: cs.primary.withValues(alpha: 0.16))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: onBack, icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Live Classes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
          IconButton.filledTonal(onPressed: onHistory, tooltip: 'Live class history', icon: const Icon(Icons.history_edu_outlined)),
          const SizedBox(width: 6),
          const Icon(Icons.live_tv_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 12),
        Text('Welcome, $studentName', style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Join lectures, prepare before class, review materials, and keep attendance up to date.', style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w700, height: 1.30)),
      ]),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.live, required this.upcoming, required this.replay});
  final int live;
  final int upcoming;
  final int replay;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _MetricCard(label: 'Live now', value: '$live', icon: Icons.radio_button_checked_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _MetricCard(label: 'Upcoming', value: '$upcoming', icon: Icons.schedule_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _MetricCard(label: 'Replay', value: '$replay', icon: Icons.replay_rounded)),
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.onSurface.withValues(alpha: 0.07))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: cs.primary, size: 20), const SizedBox(height: 8), Text(value, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 20)), const SizedBox(height: 2), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.62), fontWeight: FontWeight.w800, fontSize: 12))]));
  }
}

class _HistoryShortcutCard extends StatelessWidget {
  const _HistoryShortcutCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.primary.withValues(alpha: 0.10))),
        child: Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(Icons.history_edu_outlined, color: cs.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Live class history', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('View past classes, attendance, notes saved, and replay availability.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700))])),
          Icon(Icons.arrow_forward_ios_rounded, size: 18, color: cs.primary),
        ]),
      ),
    );
  }
}

class _ControlRoomShortcutCard extends StatelessWidget {
  const _ControlRoomShortcutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Chief invigilator control room', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('Monitor live classes, incidents, attendance risks, screen-share requests, and alerts.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700))])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.indigo),
        ]),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.primary.withValues(alpha: 0.10))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(Icons.fact_check_outlined, color: cs.primary)), const SizedBox(width: 10), Expanded(child: Text('Class readiness', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))), _MiniPill(text: 'Student checklist', tone: cs.primary)]), const SizedBox(height: 12), const _CheckLine(text: 'Use a stable network before joining live class.'), const _CheckLine(text: 'Keep microphone muted until the lecturer allows questions.'), const _CheckLine(text: 'Join with your registered student profile for attendance.')])) ;
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Live', 'Today', 'Upcoming', 'Replay'];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: filters.map((filter) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(filter), selected: selected == filter, onSelected: (_) => onChanged(filter)))).toList()));
  }
}

class _LiveClassCard extends StatelessWidget {
  const _LiveClassCard({required this.session, required this.onJoin, required this.onDetails});
  final LiveSessionModel session;
  final VoidCallback onJoin;
  final VoidCallback onDetails;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final status = session.statusLabelAt(now);
    final tone = session.isLiveAt(now) ? Colors.green.shade700 : session.isUpcomingAt(now) ? cs.primary : Colors.orange.shade800;
    final hint = session.isLiveAt(now) ? 'Class is currently active' : session.isUpcomingAt(now) ? _startsInLabel(session.startTime.difference(now).inMinutes) : 'Class ended. Replay may be available.';
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: tone.withValues(alpha: 0.14))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: tone.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)), child: Icon(session.isLiveAt(now) ? Icons.video_camera_front_rounded : Icons.live_tv_outlined, color: tone)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${session.courseCode} • ${session.title}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 5), Text(session.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600, height: 1.30))])), _MiniPill(text: status, tone: tone)]), const SizedBox(height: 12), Wrap(spacing: 8, runSpacing: 8, children: [_MiniPill(text: liveSessionDayTimeRange(session.startTime, session.endTime), tone: cs.primary), _MiniPill(text: session.roomLabel, tone: cs.secondary), _MiniPill(text: liveSessionMinutesLabel(session.durationMinutes), tone: cs.tertiary), _MiniPill(text: session.attendanceEnabled ? 'Attendance active' : 'Attendance off', tone: cs.primary)]), const SizedBox(height: 10), _InfoRow(icon: Icons.person_outline_rounded, text: 'Lecturer: ${session.lecturerName}'), _InfoRow(icon: Icons.timer_outlined, text: hint), const SizedBox(height: 12), Row(children: [Expanded(child: FilledButton.icon(onPressed: onJoin, icon: Icon(session.isCompletedAt(now) ? Icons.replay_rounded : Icons.video_call_outlined), label: Text(session.isCompletedAt(now) ? 'Open replay' : session.isLiveAt(now) ? 'Join now' : 'Open lobby'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: onDetails, icon: const Icon(Icons.info_outline_rounded), label: const Text('Details')))]),]));
  }
  String _startsInLabel(int minutes) {
    if (minutes <= 0) return 'Starting soon';
    if (minutes < 60) return 'Starts in $minutes minutes';
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return remain == 0 ? 'Starts in ${hours}h' : 'Starts in ${hours}h ${remain}m';
  }
}

class _LiveClassDetailsSheet extends StatelessWidget {
  const _LiveClassDetailsSheet({required this.session});
  final LiveSessionModel session;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 18), decoration: BoxDecoration(color: cs.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))), child: SafeArea(top: false, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)))), const SizedBox(height: 16), Text('${session.courseCode} • ${session.title}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 20)), const SizedBox(height: 6), Text(liveSessionDateTime(session.startTime), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)), const SizedBox(height: 12), _DetailBlock(title: 'Class agenda', icon: Icons.format_list_bulleted_rounded, items: session.agenda), const SizedBox(height: 12), _DetailBlock(title: 'Class materials', icon: Icons.folder_copy_outlined, items: session.materials.isEmpty ? ['No class material has been attached yet.'] : session.materials.map((item) => '${item.title} — ${item.status.isEmpty ? item.subtitle : item.status}').toList()), const SizedBox(height: 12), _DetailBlock(title: 'Student rules', icon: Icons.rule_folder_outlined, items: [session.chatEnabled ? 'Class chat is enabled for learning interaction.' : 'Class chat is locked for this session.', session.questionsEnabled ? 'Q&A is enabled for student questions.' : 'Q&A is locked for this session.', session.attendanceEnabled ? 'Attendance is active for this live class.' : 'Attendance is not active for this class.'])]))));
  }
}

class _DetailBlock extends StatelessWidget {
  const _DetailBlock({required this.title, required this.icon, required this.items});
  final String title;
  final IconData icon;
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.035), borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: cs.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)))]), const SizedBox(height: 10), ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 18), const SizedBox(width: 8), Expanded(child: Text(item, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.74), fontWeight: FontWeight.w700, height: 1.30)))])))]));
  }
}

class _CheckLine extends StatelessWidget { const _CheckLine({required this.text}); final String text; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_circle_outline_rounded, size: 18, color: cs.primary), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700, height: 1.30)))])); } }
class _InfoRow extends StatelessWidget { const _InfoRow({required this.icon, required this.text}); final IconData icon; final String text; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(icon, size: 17, color: cs.onSurface.withValues(alpha: 0.55)), const SizedBox(width: 7), Expanded(child: Text(text, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700)))])); } }
class _MiniPill extends StatelessWidget { const _MiniPill({required this.text, required this.tone}); final String text; final Color tone; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: tone.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999), border: Border.all(color: tone.withValues(alpha: 0.14))), child: Text(text, style: TextStyle(color: tone, fontWeight: FontWeight.w900, fontSize: 11))); }
class _EmptyState extends StatelessWidget { const _EmptyState({required this.filter}); final String filter; @override Widget build(BuildContext context) { final cs = Theme.of(context).colorScheme; return Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))), child: Column(children: [Icon(Icons.live_tv_outlined, size: 44, color: cs.primary), const SizedBox(height: 10), Text('No $filter live class', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 7), Text('Live classes published for your registered courses will appear here.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600, height: 1.30))])); } }
