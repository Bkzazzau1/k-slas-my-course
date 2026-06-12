import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/live_session_models.dart';
import '../../live_sessions/controller/live_sessions_controller.dart';
import '../../live_sessions/live_session_utils.dart';

class LiveClassTab extends StatelessWidget {
  const LiveClassTab({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LiveSessionsController>();

    return Obx(() {
      final sessions = controller.sessionsForCourse(course.code);
      final primary = controller.primarySessionForCourse(course.code);

      if (sessions.isEmpty && !controller.isLoadingSessions.value) {
        controller.loadSessions(courseCode: course.code);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        children: [
          _Header(course: course),
          const SizedBox(height: 12),
          if (primary == null)
            _EmptyState(course: course)
          else ...[
            _SummaryCard(course: course, session: primary),
            const SizedBox(height: 12),
            _InfoShell(
              title: 'Live room controls',
              subtitle:
                  'This session now tracks camera visibility, registration-number identity, attendance minutes, recording permissions, chat, and Q&A.',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FlagBadge(
                    label: primary.studentCameraRequired
                        ? 'Student camera required'
                        : 'Camera optional',
                  ),
                  _FlagBadge(
                    label: primary.captureRegistrationNumber
                        ? 'Registration captured'
                        : 'Registration optional',
                  ),
                  _FlagBadge(
                    label: primary.attendanceEnabled
                        ? 'Attendance tracked'
                        : 'Attendance off',
                  ),
                  _FlagBadge(
                    label: primary.allowLecturerRecording
                        ? 'Lecturer can record'
                        : 'Lecturer recording off',
                  ),
                  _FlagBadge(
                    label: primary.allowStudentRecording
                        ? 'Students can record'
                        : 'Student recording off',
                  ),
                  _FlagBadge(
                    label: primary.chatEnabled ? 'Chat enabled' : 'Chat locked',
                  ),
                  _FlagBadge(
                    label: primary.questionsEnabled
                        ? 'Q&A enabled'
                        : 'Q&A locked',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoShell(
              title: 'Session agenda',
              subtitle:
                  'Students see this as the session flow when they open the live room.',
              child: Column(
                children: [
                  for (
                    int index = 0;
                    index < primary.agenda.length;
                    index++
                  ) ...[
                    _AgendaRow(number: index + 1, text: primary.agenda[index]),
                    if (index != primary.agenda.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoShell(
              title: 'Class materials',
              subtitle:
                  'These are the lecturer-shared materials for the selected live session.',
              child: primary.materials.isEmpty
                  ? const _EmptyLabel(label: 'No material attached yet.')
                  : Column(
                      children: [
                        for (
                          int index = 0;
                          index < primary.materials.length;
                          index++
                        ) ...[
                          _MaterialRow(item: primary.materials[index]),
                          if (index != primary.materials.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            _InfoShell(
              title: 'Upcoming and replay',
              subtitle:
                  'The student course tab now follows the lecturer portal schedule instead of hard-coded lesson cards.',
              child: Column(
                children: [
                  for (int index = 0; index < sessions.length; index++) ...[
                    _SessionRow(course: course, session: sessions[index]),
                    if (index != sessions.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live sessions',
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Join ${course.code} live rooms, track attendance by registration number, and keep chat, Q&A, and recordings in one place.',
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.70),
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.course, required this.session});

  final CourseModel course;
  final LiveSessionModel session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final status = session.statusLabelAt(now);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.18),
            cs.secondary.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.description,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.74),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                label: status,
                color: status == 'Live now' ? cs.secondary : cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaPill(
                text: liveSessionDayTimeRange(
                  session.startTime,
                  session.endTime,
                ),
              ),
              _MetaPill(text: session.roomLabel),
              _MetaPill(text: session.lecturerName),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(
                    Routes.liveSessionRoom,
                    arguments: {
                      'sessionId': session.id,
                      'role': LiveSessionRole.student,
                    },
                  ),
                  icon: const Icon(Icons.videocam_outlined),
                  label: Text(
                    status == 'Replay' ? 'Open room' : 'Join session',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(Routes.timetable),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Full timetable'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'This session is demo-ready for the school and targets the Go live-session API for production sync.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.68),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoShell extends StatelessWidget {
  const _InfoShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$number',
            style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.item});

  final LiveSessionMaterial item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.folder_open_outlined, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _FlagBadge(label: item.status),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.course, required this.session});

  final CourseModel course;
  final LiveSessionModel session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = session.statusLabelAt(DateTime.now());
    final color = status == 'Live now' ? cs.secondary : cs.primary;

    return InkWell(
      onTap: () => Get.toNamed(
        Routes.liveSessionRoom,
        arguments: {'sessionId': session.id, 'role': LiveSessionRole.student},
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${liveSessionShortDate(session.startTime)} • ${liveSessionDayTimeRange(session.startTime, session.endTime)}',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _StatusBadge(label: status, color: color),
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.78),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No live session configured',
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The lecturer has not published a live session for ${course.code} yet. This app will show it automatically after the separate lecturer portal creates it.',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLabel extends StatelessWidget {
  const _EmptyLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.72),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
