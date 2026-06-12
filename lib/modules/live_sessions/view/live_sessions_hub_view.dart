import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_session_runtime_mode_service.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class LiveSessionsHubView extends GetView<LiveSessionsController> {
  const LiveSessionsHubView({super.key});

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
              child: _Header(
                cs: cs,
                onSchedule: () => _openScheduleSheet(context),
              ),
            ),
            Expanded(
              child: Obx(() {
                final sessions = controller.sessions.toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime));
                if (controller.isLoadingSessions.value && sessions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: () => controller.loadSessions(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    children: [
                      _StatusStrip(cs: cs, controller: controller),
                      const SizedBox(height: 12),
                      ...sessions.map(
                        (session) => _LiveSessionCard(
                          cs: cs,
                          session: session,
                          onStudentJoin: () => Get.toNamed(
                            Routes.liveSessionRoom,
                            arguments: {
                              'sessionId': session.id,
                              'role': LiveSessionRole.student,
                              'displayName': 'Zainab Ibrahim',
                              'registrationNumber': 'KASU/CS/23/001',
                            },
                          ),
                          onLecturerOpen: () => Get.toNamed(
                            Routes.liveSessionRoom,
                            arguments: {
                              'sessionId': session.id,
                              'role': LiveSessionRole.lecturer,
                              'lecturerName': session.lecturerName,
                            },
                          ),
                          onAttendance: () => _openAttendanceSheet(session),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openScheduleSheet(BuildContext context) {
    Get.bottomSheet<void>(
      _ScheduleLiveSessionSheet(controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  Future<void> _openAttendanceSheet(LiveSessionModel session) async {
    final room = await controller.gatewayRoomPreview(session.id);
    Get.bottomSheet<void>(
      _AttendanceSheet(session: session, room: room),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cs, required this.onSchedule});

  final ColorScheme cs;
  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.78),
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
      child: Row(
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
                  'Live Sessions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Schedule classes, join rooms, and review attendance.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: cs.primary,
            ),
            onPressed: onSchedule,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Schedule'),
          ),
        ],
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.cs, required this.controller});

  final ColorScheme cs;
  final LiveSessionsController controller;

  @override
  Widget build(BuildContext context) {
    final live = controller.sessions
        .where((session) => session.isLiveAt(DateTime.now()))
        .length;
    final upcoming = controller.sessions
        .where((session) => session.isUpcomingAt(DateTime.now()))
        .length;
    return Row(
      children: [
        Expanded(
          child: _Metric(cs: cs, label: 'Live', value: '$live'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(cs: cs, label: 'Upcoming', value: '$upcoming'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            cs: cs,
            label: 'Mode',
            value: controller.currentRuntimeMode.label,
          ),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
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

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({
    required this.cs,
    required this.session,
    required this.onStudentJoin,
    required this.onLecturerOpen,
    required this.onAttendance,
  });

  final ColorScheme cs;
  final LiveSessionModel session;
  final VoidCallback onStudentJoin;
  final VoidCallback onLecturerOpen;
  final VoidCallback onAttendance;

  @override
  Widget build(BuildContext context) {
    final status = session.statusLabelAt(DateTime.now());
    final tone = status == 'Live now'
        ? cs.secondary
        : status == 'Upcoming'
        ? cs.primary
        : cs.tertiary;
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
                  '${session.courseCode} • ${session.title}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              _Pill(text: status, tone: tone),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.description,
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
              _Pill(
                text: liveSessionDayTimeRange(
                  session.startTime,
                  session.endTime,
                ),
                tone: cs.primary,
              ),
              _Pill(text: session.roomLabel, tone: cs.secondary),
              _Pill(text: '${session.durationMinutes} mins', tone: cs.tertiary),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Lecturer: ${session.lecturerName}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                text: session.attendanceEnabled
                    ? 'Attendance on'
                    : 'Attendance off',
                tone: cs.primary,
              ),
              _Pill(
                text: session.chatEnabled ? 'Chat' : 'Chat locked',
                tone: cs.secondary,
              ),
              _Pill(
                text: session.questionsEnabled ? 'Q&A' : 'Q&A locked',
                tone: cs.tertiary,
              ),
              _Pill(
                text: session.allowLecturerRecording
                    ? 'Recording ready'
                    : 'No recording',
                tone: cs.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStudentJoin,
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Student join'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onLecturerOpen,
                  icon: const Icon(Icons.co_present_outlined),
                  label: const Text('Lecturer'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAttendance,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Attendance snapshot'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleLiveSessionSheet extends StatefulWidget {
  const _ScheduleLiveSessionSheet({required this.controller});

  final LiveSessionsController controller;

  @override
  State<_ScheduleLiveSessionSheet> createState() =>
      _ScheduleLiveSessionSheetState();
}

class _ScheduleLiveSessionSheetState extends State<_ScheduleLiveSessionSheet> {
  final _courseController = TextEditingController(text: 'CSC 305');
  final _courseTitleController = TextEditingController(text: 'Data Structures');
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lecturerController = TextEditingController(text: 'Dr. Musa Ibrahim');
  final _roomController = TextEditingController(text: 'Virtual Room A');
  final _agendaController = TextEditingController(
    text: 'Attendance and welcome\nTopic walkthrough\nStudent Q&A',
  );
  final _materialsController = TextEditingController(
    text: 'Lecture slides, Ready now\nProblem sheet, During class',
  );
  int _startsInHours = 2;
  int _durationMinutes = 75;
  bool _studentCameraRequired = true;
  bool _attendanceEnabled = true;
  bool _chatEnabled = true;
  bool _questionsEnabled = true;
  bool _saving = false;

  @override
  void dispose() {
    _courseController.dispose();
    _courseTitleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _lecturerController.dispose();
    _roomController.dispose();
    _agendaController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final course = _courseController.text.trim().toUpperCase();
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (course.isEmpty || title.isEmpty || description.isEmpty) {
      Get.snackbar(
        'Missing details',
        'Course, title, and description are required.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() => _saving = true);
    final start = DateTime.now().add(Duration(hours: _startsInHours));
    final session = LiveSessionModel(
      id: 'live-demo-${DateTime.now().microsecondsSinceEpoch}',
      courseCode: course,
      courseTitle: _courseTitleController.text.trim().isEmpty
          ? course
          : _courseTitleController.text.trim(),
      title: title,
      description: description,
      lecturerName: _lecturerController.text.trim().isEmpty
          ? 'Course lecturer'
          : _lecturerController.text.trim(),
      roomLabel: _roomController.text.trim().isEmpty
          ? 'Virtual Room'
          : _roomController.text.trim(),
      startTime: start,
      endTime: start.add(Duration(minutes: _durationMinutes)),
      agenda: _agendaController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
      materials: _materialsController.text
          .split('\n')
          .map(_materialFromLine)
          .whereType<LiveSessionMaterial>()
          .toList(),
      studentCameraRequired: _studentCameraRequired,
      captureRegistrationNumber: true,
      allowLecturerRecording: true,
      allowStudentRecording: false,
      attendanceEnabled: _attendanceEnabled,
      chatEnabled: _chatEnabled,
      questionsEnabled: _questionsEnabled,
    );
    await widget.controller.saveSession(session);
    if (mounted) {
      setState(() => _saving = false);
    }
    Get.back<void>();
    Get.snackbar(
      'Live class scheduled',
      'The new session is ready for student join and attendance tracking.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  LiveSessionMaterial? _materialFromLine(String line) {
    final cleaned = line.trim();
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split(',');
    return LiveSessionMaterial(
      title: parts.first.trim(),
      subtitle: parts.length > 1 ? parts[1].trim() : 'Shared class material',
      status: parts.length > 2 ? parts[2].trim() : 'Ready',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Schedule live class',
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(
                  labelText: 'Course code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _courseTitleController,
                decoration: const InputDecoration(
                  labelText: 'Course title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Class title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lecturerController,
                decoration: const InputDecoration(
                  labelText: 'Lecturer',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _roomController,
                decoration: const InputDecoration(
                  labelText: 'Room label',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Starts in $_startsInHours hour(s)',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Slider(
                min: 0,
                max: 48,
                divisions: 48,
                value: _startsInHours.toDouble(),
                label: '$_startsInHours',
                onChanged: (value) =>
                    setState(() => _startsInHours = value.round()),
              ),
              Text(
                'Duration $_durationMinutes minutes',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Slider(
                min: 30,
                max: 180,
                divisions: 10,
                value: _durationMinutes.toDouble(),
                label: '$_durationMinutes',
                onChanged: (value) =>
                    setState(() => _durationMinutes = value.round()),
              ),
              TextFormField(
                controller: _agendaController,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Agenda',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _materialsController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Materials',
                  hintText: 'Title, subtitle, status',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _studentCameraRequired,
                onChanged: (value) =>
                    setState(() => _studentCameraRequired = value),
                title: const Text('Require student camera'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _attendanceEnabled,
                onChanged: (value) =>
                    setState(() => _attendanceEnabled = value),
                title: const Text('Track attendance'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _chatEnabled,
                onChanged: (value) => setState(() => _chatEnabled = value),
                title: const Text('Enable chat'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _questionsEnabled,
                onChanged: (value) => setState(() => _questionsEnabled = value),
                title: const Text('Enable Q&A'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Icon(Icons.event_available_outlined),
                  label: Text(_saving ? 'Saving...' : 'Schedule class'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceSheet extends StatelessWidget {
  const _AttendanceSheet({required this.session, required this.room});

  final LiveSessionModel session;
  final LiveSessionRoomState room;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final students = room.participants
        .where((item) => item.role == LiveSessionRole.student)
        .toList();
    final present = students.where((item) => item.isPresent).length;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Attendance • ${session.courseCode}',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$present/${students.length} students present',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.70),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final participant = students[index];
                  final minutes = participant.attendanceMinutesAt(
                    DateTime.now(),
                  );
                  return ListTile(
                    tileColor: cs.onSurface.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: Icon(
                      participant.isPresent
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      color: participant.isPresent ? cs.primary : cs.error,
                    ),
                    title: Text(participant.displayName),
                    subtitle: Text(
                      '${participant.registrationNumber ?? 'No registration'} • $minutes minute(s)',
                    ),
                    trailing: Text(
                      participant.isPresent ? 'Present' : 'Away',
                      style: TextStyle(
                        color: participant.isPresent ? cs.primary : cs.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
