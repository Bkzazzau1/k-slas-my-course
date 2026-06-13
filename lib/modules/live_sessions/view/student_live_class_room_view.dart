import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_student_notes_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/submission_history_service.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';
import '../widgets/live_session_video_surface.dart';

enum _StudentRoomPanel { chat, questions, notes, people }

class StudentLiveClassRoomView extends StatefulWidget {
  const StudentLiveClassRoomView({super.key});

  @override
  State<StudentLiveClassRoomView> createState() => _StudentLiveClassRoomViewState();
}

class _StudentLiveClassRoomViewState extends State<StudentLiveClassRoomView> {
  late final LiveSessionsController controller;
  late final String sessionId;
  late final String displayName;
  late final String registrationNumber;

  final chatController = TextEditingController();
  final questionController = TextEditingController();
  final noteController = TextEditingController();

  Timer? refreshTimer;
  _StudentRoomPanel activePanel = _StudentRoomPanel.chat;
  bool handRaised = false;
  bool attendanceSaved = false;
  bool screenShareOn = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<LiveSessionsController>();
    final args = (Get.arguments ?? {}) as Map;
    final profile = StudentProfileStorage.load();
    sessionId = args['sessionId']?.toString() ?? '';
    displayName = args['displayName']?.toString() ?? profile?.fullName ?? 'Student';
    registrationNumber = args['registrationNumber']?.toString() ?? profile?.matricNo ?? profile?.email ?? 'student-demo';
    noteController.text = LiveClassStudentNotesService.load(sessionId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRoom());
    refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (!mounted) return;
      await controller.refreshRoom();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    unawaited(_stopScreenShareSilently());
    unawaited(controller.disconnectMediaRoom());
    chatController.dispose();
    questionController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _openRoom() async {
    if (sessionId.isEmpty) return;
    await controller.openStudentRoom(
      sessionId: sessionId,
      displayName: displayName,
      registrationNumber: registrationNumber,
    );
  }

  Future<void> _sendChat() async {
    final text = chatController.text.trim();
    if (text.isEmpty) return;
    await controller.sendChat(
      senderName: displayName,
      senderRole: LiveSessionRole.student,
      message: text,
      registrationNumber: registrationNumber,
    );
    chatController.clear();
  }

  Future<void> _sendQuestion() async {
    final text = questionController.text.trim();
    if (text.isEmpty) return;
    await controller.askQuestion(
      askedByName: displayName,
      question: text,
      registrationNumber: registrationNumber,
    );
    questionController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question sent to the lecturer.')));
  }

  Future<void> _toggleScreenShare() async {
    final next = !screenShareOn;
    try {
      final localParticipant = controller.rtcRoom.value?.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setScreenShareEnabled(next);
      }
      if (!mounted) return;
      setState(() => screenShareOn = next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'Screen sharing started. The lecturer can see your shared screen.'
                : 'Screen sharing stopped.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Screen share could not start: $error')),
      );
    }
  }

  Future<void> _stopScreenShareSilently() async {
    if (!screenShareOn) return;
    try {
      await controller.rtcRoom.value?.localParticipant?.setScreenShareEnabled(false);
    } catch (_) {
      // Ignore cleanup errors while leaving the class.
    }
  }

  Future<void> _saveNotes(String value) {
    return LiveClassStudentNotesService.save(sessionId: sessionId, note: value);
  }

  Future<void> _leaveClass() async {
    await _stopScreenShareSilently();
    await _saveNotes(noteController.text);
    await _saveAttendanceReceipt();
    if (mounted) Get.back<void>();
  }

  Future<void> _saveAttendanceReceipt() async {
    if (attendanceSaved) return;
    final room = controller.room.value;
    if (room == null || room.session.id != sessionId) return;
    final participant = _currentParticipant(room);
    final minutes = participant?.attendanceMinutesAt(DateTime.now()) ?? 0;
    final percent = _attendancePercentage(minutes, room.session.durationMinutes);
    await SubmissionHistoryService.saveLiveClassAttendance(
      session: room.session,
      receiptNumber: _attendanceReceipt(room.session),
      attendanceMinutes: minutes,
      attendancePercentage: percent,
      status: 'Attendance Recorded',
    );
    attendanceSaved = true;
  }

  int _attendancePercentage(int minutes, int durationMinutes) {
    if (durationMinutes <= 0) return 0;
    final pct = ((minutes / durationMinutes) * 100).round();
    if (pct < 0) return 0;
    if (pct > 100) return 100;
    return pct;
  }

  String _attendanceReceipt(LiveSessionModel session) {
    final course = _cleanId(session.courseCode);
    final sessionPart = _cleanId(session.id);
    final student = _cleanId(registrationNumber);
    return 'LIVE-$course-$sessionPart-$student';
  }

  String _cleanId(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '').toUpperCase();
    return cleaned.isEmpty ? 'STUDENT' : cleaned;
  }

  LiveSessionParticipant? _currentParticipant(LiveSessionRoomState room) {
    final id = controller.activeParticipantId.value;
    return room.participants.firstWhereOrNull((item) => item.id == id);
  }

  LiveSessionParticipant? _lecturer(LiveSessionRoomState room) {
    return room.participants.firstWhereOrNull((item) => item.role == LiveSessionRole.lecturer);
  }

  List<LiveSessionParticipant> _participants(LiveSessionRoomState room) {
    final items = [...room.participants];
    items.sort((a, b) {
      final ar = a.role == LiveSessionRole.lecturer ? 0 : 1;
      final br = b.role == LiveSessionRole.lecturer ? 0 : 1;
      if (ar != br) return ar.compareTo(br);
      return a.displayName.compareTo(b.displayName);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(() {
          final room = controller.room.value;
          if (controller.isLoadingRoom.value || room == null || room.session.id != sessionId) {
            return const Center(child: CircularProgressIndicator());
          }
          final participant = _currentParticipant(room);
          final lecturer = _lecturer(room);
          final participants = _participants(room);
          final micOn = participant?.micEnabled ?? false;
          final cameraOn = participant?.cameraEnabled ?? false;
          final isWide = MediaQuery.sizeOf(context).width >= 1000;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: _RoomHeader(
                  room: room,
                  participant: participant,
                  screenShareOn: screenShareOn,
                  onLeave: () => unawaited(_leaveClass()),
                ),
              ),
              Expanded(
                child: isWide
                    ? Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 8, 10),
                              child: _StageAndControls(
                                room: room,
                                lecturer: lecturer,
                                participant: participant,
                                controller: controller,
                                micOn: micOn,
                                cameraOn: cameraOn,
                                screenShareOn: screenShareOn,
                                handRaised: handRaised,
                                onMic: () => controller.toggleMicrophone(!micOn),
                                onCamera: () => controller.toggleCamera(!cameraOn),
                                onScreenShare: _toggleScreenShare,
                                onRaiseHand: () => setState(() => handRaised = !handRaised),
                                onAsk: () => setState(() => activePanel = _StudentRoomPanel.questions),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 16, 10),
                              child: _StudentSidePanel(
                                room: room,
                                participants: participants,
                                activePanel: activePanel,
                                onPanelChanged: (value) => setState(() => activePanel = value),
                                chatController: chatController,
                                questionController: questionController,
                                noteController: noteController,
                                onSendChat: _sendChat,
                                onSendQuestion: _sendQuestion,
                                onSaveNotes: _saveNotes,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          SizedBox(
                            height: 450,
                            child: _StageAndControls(
                              room: room,
                              lecturer: lecturer,
                              participant: participant,
                              controller: controller,
                              micOn: micOn,
                              cameraOn: cameraOn,
                              screenShareOn: screenShareOn,
                              handRaised: handRaised,
                              onMic: () => controller.toggleMicrophone(!micOn),
                              onCamera: () => controller.toggleCamera(!cameraOn),
                              onScreenShare: _toggleScreenShare,
                              onRaiseHand: () => setState(() => handRaised = !handRaised),
                              onAsk: () => setState(() => activePanel = _StudentRoomPanel.questions),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 440,
                            child: _StudentSidePanel(
                              room: room,
                              participants: participants,
                              activePanel: activePanel,
                              onPanelChanged: (value) => setState(() => activePanel = value),
                              chatController: chatController,
                              questionController: questionController,
                              noteController: noteController,
                              onSendChat: _sendChat,
                              onSendQuestion: _sendQuestion,
                              onSaveNotes: _saveNotes,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.room, required this.participant, required this.screenShareOn, required this.onLeave});
  final LiveSessionRoomState room;
  final LiveSessionParticipant? participant;
  final bool screenShareOn;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final attendance = participant?.attendanceMinutesAt(now) ?? 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [cs.primary, cs.secondary])),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${room.session.courseCode} • ${room.session.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          Text(liveSessionDayTimeRange(room.session.startTime, room.session.endTime), style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontWeight: FontWeight.w700)),
        ])),
        if (screenShareOn) ...[
          const _HeaderPill(icon: Icons.screen_share_rounded, label: 'Sharing'),
          const SizedBox(width: 8),
        ],
        _HeaderPill(icon: Icons.groups_rounded, label: '${room.participants.length}'),
        const SizedBox(width: 8),
        _HeaderPill(icon: Icons.timer_outlined, label: '${attendance}m'),
        const SizedBox(width: 8),
        IconButton.filledTonal(onPressed: onLeave, icon: const Icon(Icons.logout_rounded)),
      ]),
    );
  }
}

class _StageAndControls extends StatelessWidget {
  const _StageAndControls({
    required this.room,
    required this.lecturer,
    required this.participant,
    required this.controller,
    required this.micOn,
    required this.cameraOn,
    required this.screenShareOn,
    required this.handRaised,
    required this.onMic,
    required this.onCamera,
    required this.onScreenShare,
    required this.onRaiseHand,
    required this.onAsk,
  });

  final LiveSessionRoomState room;
  final LiveSessionParticipant? lecturer;
  final LiveSessionParticipant? participant;
  final LiveSessionsController controller;
  final bool micOn;
  final bool cameraOn;
  final bool screenShareOn;
  final bool handRaised;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onScreenShare;
  final VoidCallback onRaiseHand;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallbackLecturer = lecturer ?? LiveSessionParticipant(id: 'lecturer-${room.session.id}', sessionId: room.session.id, role: LiveSessionRole.lecturer, displayName: room.session.lecturerName, cameraEnabled: true, micEnabled: true);
    final self = participant ?? LiveSessionParticipant(id: 'student-preview', sessionId: room.session.id, role: LiveSessionRole.student, displayName: 'You', cameraEnabled: cameraOn, micEnabled: micOn);
    final selfMedia = controller.mediaParticipantFor(self.id);
    final showScreenShare = screenShareOn || liveSessionScreenShareTrackFor(selfMedia) != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(children: [
              Positioned.fill(
                child: showScreenShare
                    ? LiveSessionScreenShareSurface(participant: self, mediaParticipant: selfMedia, borderRadius: BorderRadius.circular(22))
                    : LiveSessionVideoSurface(participant: fallbackLecturer, mediaParticipant: controller.mediaParticipantFor(fallbackLecturer.id), borderRadius: BorderRadius.circular(22)),
              ),
              Positioned(left: 14, top: 14, child: _StagePill(text: showScreenShare ? 'Your screen is shared' : (room.session.isLiveAt(DateTime.now()) ? 'Live class' : room.session.statusLabelAt(DateTime.now())), icon: showScreenShare ? Icons.screen_share_rounded : Icons.radio_button_checked_rounded)),
              Positioned(left: 14, bottom: 14, right: 14, child: Text(showScreenShare ? 'Sharing your screen with lecturer' : room.session.lecturerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
              Positioned(right: 14, bottom: 14, width: 150, height: 96, child: LiveSessionVideoSurface(participant: self, mediaParticipant: selfMedia, borderRadius: BorderRadius.circular(18))),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _ControlButton(icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded, label: micOn ? 'Mute' : 'Unmute', selected: micOn, onTap: onMic),
            _ControlButton(icon: cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded, label: cameraOn ? 'Camera' : 'Camera off', selected: cameraOn, onTap: onCamera),
            _ControlButton(icon: screenShareOn ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded, label: screenShareOn ? 'Stop share' : 'Share screen', selected: screenShareOn, onTap: onScreenShare),
            _ControlButton(icon: Icons.front_hand_rounded, label: handRaised ? 'Lower hand' : 'Raise hand', selected: handRaised, onTap: onRaiseHand),
            _ControlButton(icon: Icons.question_answer_outlined, label: 'Ask', onTap: onAsk),
          ]),
        ),
      ]),
    );
  }
}

class _StudentSidePanel extends StatelessWidget {
  const _StudentSidePanel({required this.room, required this.participants, required this.activePanel, required this.onPanelChanged, required this.chatController, required this.questionController, required this.noteController, required this.onSendChat, required this.onSendQuestion, required this.onSaveNotes});
  final LiveSessionRoomState room;
  final List<LiveSessionParticipant> participants;
  final _StudentRoomPanel activePanel;
  final ValueChanged<_StudentRoomPanel> onPanelChanged;
  final TextEditingController chatController;
  final TextEditingController questionController;
  final TextEditingController noteController;
  final VoidCallback onSendChat;
  final VoidCallback onSendQuestion;
  final ValueChanged<String> onSaveNotes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _PanelChip(label: 'Chat', icon: Icons.chat_outlined, selected: activePanel == _StudentRoomPanel.chat, onTap: () => onPanelChanged(_StudentRoomPanel.chat)),
            _PanelChip(label: 'Q&A', icon: Icons.question_answer_outlined, selected: activePanel == _StudentRoomPanel.questions, onTap: () => onPanelChanged(_StudentRoomPanel.questions)),
            _PanelChip(label: 'Notes', icon: Icons.edit_note_outlined, selected: activePanel == _StudentRoomPanel.notes, onTap: () => onPanelChanged(_StudentRoomPanel.notes)),
            _PanelChip(label: 'People', icon: Icons.groups_outlined, selected: activePanel == _StudentRoomPanel.people, onTap: () => onPanelChanged(_StudentRoomPanel.people)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(child: _panelBody(context)),
      ]),
    );
  }

  Widget _panelBody(BuildContext context) {
    switch (activePanel) {
      case _StudentRoomPanel.questions:
        return _QuestionsPanel(room: room, controller: questionController, onSend: onSendQuestion);
      case _StudentRoomPanel.notes:
        return _NotesPanel(controller: noteController, onChanged: onSaveNotes);
      case _StudentRoomPanel.people:
        return _PeoplePanel(participants: participants);
      case _StudentRoomPanel.chat:
        return _ChatPanel(room: room, controller: chatController, onSend: onSendChat);
    }
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({required this.room, required this.controller, required this.onSend});
  final LiveSessionRoomState room;
  final TextEditingController controller;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: room.chatMessages.isEmpty
              ? const _PanelEmpty(message: 'No chat message yet.')
              : ListView.builder(itemCount: room.chatMessages.length, itemBuilder: (context, index) {
                  final item = room.chatMessages[index];
                  return _MessageBubble(title: item.senderName, body: item.message);
                }),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Type class message'))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send_rounded)),
        ]),
      ]);
}

class _QuestionsPanel extends StatelessWidget {
  const _QuestionsPanel({required this.room, required this.controller, required this.onSend});
  final LiveSessionRoomState room;
  final TextEditingController controller;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
          child: room.questions.isEmpty
              ? const _PanelEmpty(message: 'No student question yet.')
              : ListView.builder(itemCount: room.questions.length, itemBuilder: (context, index) {
                  final item = room.questions[index];
                  return _MessageBubble(title: item.askedByName, body: item.isAnswered ? '${item.question}\n\nAnswer: ${item.answer}' : item.question);
                }),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(controller: controller, minLines: 1, maxLines: 3, decoration: const InputDecoration(hintText: 'Ask lecturer a question'))),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: onSend, icon: const Icon(Icons.send_rounded)),
        ]),
      ]);
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        expands: true,
        minLines: null,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(hintText: 'Write personal notes during the live class...'),
      );
}

class _PeoplePanel extends StatelessWidget {
  const _PeoplePanel({required this.participants});
  final List<LiveSessionParticipant> participants;
  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) return const _PanelEmpty(message: 'No participant yet.');
    return ListView.builder(
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final item = participants[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(child: Icon(item.role == LiveSessionRole.lecturer ? Icons.school_outlined : Icons.person_outline_rounded)),
          title: Text(item.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(item.role == LiveSessionRole.lecturer ? 'Lecturer' : '${item.attendanceMinutesAt(DateTime.now())} attendance minutes'),
          trailing: Icon(item.micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded, size: 18),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.label, required this.onTap, this.selected = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: selected ? cs.primary : cs.surfaceContainerHighest, foregroundColor: selected ? cs.onPrimary : cs.onSurface),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _PanelChip extends StatelessWidget {
  const _PanelChip({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), avatar: Icon(icon, size: 18), selected: selected, onSelected: (_) => onTap()),
      );
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 18), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
      );
}

class _StagePill extends StatelessWidget {
  const _StagePill({required this.text, required this.icon});
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))]),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.62), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(body, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w700, height: 1.30)),
      ]),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  const _PanelEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Text(message, textAlign: TextAlign.center));
}
