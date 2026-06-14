import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class LiveChiefOverviewView extends GetView<LiveSessionsController> {
  const LiveChiefOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(() {
          final now = DateTime.now();
          final sessions = controller.sessions.toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final live = sessions.where((item) => item.isLiveAt(now)).toList();
          final upcoming = sessions
              .where((item) => item.isUpcomingAt(now))
              .toList();
          final completed = sessions
              .where((item) => item.isCompletedAt(now))
              .toList();

          return RefreshIndicator(
            onRefresh: controller.loadSessions,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              children: [
                _Header(onBack: () => Get.back<void>()),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricCard(
                      label: 'Live now',
                      value: '${live.length}',
                      icon: Icons.live_tv_outlined,
                      color: cs.primary,
                    ),
                    _MetricCard(
                      label: 'Upcoming',
                      value: '${upcoming.length}',
                      icon: Icons.schedule_outlined,
                      color: cs.tertiary,
                    ),
                    _MetricCard(
                      label: 'Replay ready',
                      value: '${completed.length}',
                      icon: Icons.replay_outlined,
                      color: cs.secondary,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (controller.isLoadingSessions.value && sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (sessions.isEmpty)
                  const _EmptyControlRoom()
                else ...[
                  _SectionTitle(
                    title: 'Active supervision',
                    count: live.length,
                  ),
                  if (live.isEmpty)
                    const _QuietState(
                      message: 'No live class is running right now.',
                    )
                  else
                    ...live.map(
                      (session) => _SessionOversightCard(
                        session: session,
                        now: now,
                        urgent: true,
                      ),
                    ),
                  const SizedBox(height: 12),
                  _SectionTitle(
                    title: 'Upcoming rooms',
                    count: upcoming.length,
                  ),
                  if (upcoming.isEmpty)
                    const _QuietState(message: 'No upcoming rooms are queued.')
                  else
                    ...upcoming
                        .take(5)
                        .map(
                          (session) =>
                              _SessionOversightCard(session: session, now: now),
                        ),
                  const SizedBox(height: 12),
                  _SectionTitle(
                    title: 'Recently completed',
                    count: completed.length,
                  ),
                  if (completed.isEmpty)
                    const _QuietState(
                      message: 'No completed sessions are available yet.',
                    )
                  else
                    ...completed.reversed
                        .take(5)
                        .map(
                          (session) =>
                              _SessionOversightCard(session: session, now: now),
                        ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chief invigilator control room',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monitor live classes, attendance risk, incidents, and room readiness.',
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          _Pill(text: '$count', color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}

class _SessionOversightCard extends StatelessWidget {
  const _SessionOversightCard({
    required this.session,
    required this.now,
    this.urgent = false,
  });

  final LiveSessionModel session;
  final DateTime now;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = urgent
        ? cs.error
        : session.isCompletedAt(now)
        ? cs.secondary
        : cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: tone.withValues(alpha: 0.10),
                child: Icon(Icons.video_camera_front_outlined, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.courseCode} - ${session.title}',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.lecturerName,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.68),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _Pill(text: session.statusLabelAt(now), color: tone),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                text: liveSessionDayTimeRange(
                  session.startTime,
                  session.endTime,
                ),
                color: cs.primary,
              ),
              _Pill(text: session.roomLabel, color: cs.tertiary),
              _Pill(
                text: session.attendanceEnabled
                    ? 'Attendance on'
                    : 'Attendance off',
                color: cs.secondary,
              ),
              _Pill(
                text: session.studentCameraRequired
                    ? 'Camera required'
                    : 'Camera optional',
                color: cs.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuietState extends StatelessWidget {
  const _QuietState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(message, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _EmptyControlRoom extends StatelessWidget {
  const _EmptyControlRoom();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text('No live sessions are available for supervision.'),
      ),
    );
  }
}
