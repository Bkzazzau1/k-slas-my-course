import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../controller/live_class_workspace_controller.dart';
import '../controller/live_sessions_controller.dart';
import '../widgets/live_class_board_canvas.dart';
import '../widgets/live_session_video_surface.dart';

enum _FloatingClassMode { floating, minimized, fullscreen }

class LiveClassroomProfessionalShell extends StatefulWidget {
  const LiveClassroomProfessionalShell({super.key});

  @override
  State<LiveClassroomProfessionalShell> createState() =>
      _LiveClassroomProfessionalShellState();
}

class _LiveClassroomProfessionalShellState
    extends State<LiveClassroomProfessionalShell> {
  late final LiveSessionsController _controller;
  late final LiveClassBoardController _boardController;
  late final LiveClassLayoutController _layoutController;
  late final String _sessionId;
  late final String _role;
  late final String _displayName;
  late final String _userId;
  late final String? _registrationNumber;

  final TextEditingController _chatController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  Timer? _refreshTimer;

  _FloatingClassMode _classMode = _FloatingClassMode.floating;
  Offset _panelOffset = const Offset(24, 88);
  Size _panelSize = const Size(380, 260);

  bool get _isLecturer => _role == LiveSessionRole.lecturer;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();

    final args = (Get.arguments ?? {}) as Map;
    final profile = StudentProfileStorage.load();
    _sessionId = args['sessionId']?.toString() ?? '';
    _role = args['role']?.toString() ?? LiveSessionRole.student;
    _displayName =
        args['displayName']?.toString() ??
        (_role == LiveSessionRole.lecturer
            ? (args['lecturerName']?.toString() ?? 'Course lecturer')
            : (profile?.fullName ?? 'Student'));
    _registrationNumber = _role == LiveSessionRole.lecturer
        ? null
        : args['registrationNumber']?.toString() ??
              profile?.matricNo ??
              'KASU/CS/23/001';
    _userId = _registrationNumber ?? 'lecturer-${_sessionId.toLowerCase()}';

    _boardController = LiveClassBoardController(
      sessionId: _sessionId,
      userId: _userId,
    );
    _layoutController = LiveClassLayoutController(role: _role);

    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_openRoom()));
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      await _controller.refreshRoom();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    unawaited(_controller.disconnectMediaRoom());
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    _chatController.dispose();
    _questionController.dispose();
    _boardController.dispose();
    _layoutController.dispose();
    super.dispose();
  }

  Future<void> _openRoom() async {
    if (_sessionId.isEmpty) return;
    if (_isLecturer) {
      await _controller.openLecturerRoom(
        sessionId: _sessionId,
        lecturerName: _displayName,
      );
    } else {
      await _controller.openStudentRoom(
        sessionId: _sessionId,
        displayName: _displayName,
        registrationNumber: _registrationNumber ?? _userId,
      );
    }
    final room = _controller.room.value;
    if (room != null) _syncPages(room);
  }

  void _syncPages(LiveSessionRoomState room) {
    final pageCount = math.max(1, room.session.materials.length);
    if (_boardController.pageCount != pageCount) {
      _boardController.setPageCount(pageCount);
    }
  }

  List<LiveSessionParticipant> _sortedParticipants(LiveSessionRoomState room) {
    final items = [...room.participants];
    items.sort((a, b) {
      final aRank = a.role == LiveSessionRole.lecturer ? 0 : 1;
      final bRank = b.role == LiveSessionRole.lecturer ? 0 : 1;
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.displayName.compareTo(b.displayName);
    });
    return items;
  }

  LiveSessionParticipant? _currentParticipant(LiveSessionRoomState room) {
    final id = _controller.activeParticipantId.value;
    return room.participants.firstWhereOrNull((item) => item.id == id);
  }

  LiveSessionParticipant? _lecturer(LiveSessionRoomState room) {
    return room.participants.firstWhereOrNull(
      (item) => item.role == LiveSessionRole.lecturer,
    );
  }

  Future<void> _setClassMode(_FloatingClassMode mode) async {
    setState(() => _classMode = mode);
    await _setSystemFullscreen(
      mode == _FloatingClassMode.fullscreen || _layoutController.isFullscreen,
    );
  }

  Future<void> _toggleWorkspaceFullscreen() async {
    _layoutController.toggleFullscreen();
    await _setSystemFullscreen(
      _layoutController.isFullscreen || _classMode == _FloatingClassMode.fullscreen,
    );
  }

  Future<void> _setSystemFullscreen(bool value) {
    return SystemChrome.setEnabledSystemUIMode(
      value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _sendChat() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    await _controller.sendChat(
      senderName: _displayName,
      senderRole: _role,
      message: text,
      registrationNumber: _registrationNumber,
    );
    _chatController.clear();
  }

  Future<void> _sendQuestion() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;
    await _controller.askQuestion(
      askedByName: _displayName,
      question: text,
      registrationNumber: _registrationNumber,
    );
    _questionController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question sent to the lecturer.')),
    );
  }

  void _leaveClass() {
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: false,
        child: Obx(() {
          final room = _controller.room.value;
          final loading = _controller.isLoadingRoom.value;
          if (loading || room == null || room.session.id != _sessionId) {
            return const Center(child: CircularProgressIndicator());
          }

          _syncPages(room);
          final participants = _sortedParticipants(room);
          final lecturer = _lecturer(room);
          final currentParticipant = _currentParticipant(room);
          final micOn = currentParticipant?.micEnabled ?? false;
          final cameraOn = currentParticipant?.cameraEnabled ?? false;
          final recordingOn =
              currentParticipant?.recordingEnabled ??
              room.recordings.any((item) => item.isActive);

          return AnimatedBuilder(
            animation: Listenable.merge([_layoutController, _boardController]),
            builder: (context, _) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 720;
                  final liveFullscreen = _classMode == _FloatingClassMode.fullscreen;
                  final hideChrome = _layoutController.isFullscreen || liveFullscreen;

                  return SafeArea(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            children: [
                              if (!hideChrome)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    isMobile ? 12 : 20,
                                    isMobile ? 10 : 18,
                                    isMobile ? 12 : 20,
                                    10,
                                  ),
                                  child: _ClassHeader(
                                    room: room,
                                    participants: participants,
                                    recordingOn: recordingOn,
                                    isConnecting:
                                        _controller.isConnectingMedia.value,
                                    onFullscreen: _toggleWorkspaceFullscreen,
                                    onLeave: _leaveClass,
                                  ),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    hideChrome ? 0 : (isMobile ? 12 : 20),
                                    0,
                                    hideChrome ? 0 : (isMobile ? 12 : 20),
                                    hideChrome ? 0 : 10,
                                  ),
                                  child: _WorkspaceStage(
                                    room: room,
                                    participants: participants,
                                    boardController: _boardController,
                                    layoutController: _layoutController,
                                    participantResolver:
                                        _controller.mediaParticipantFor,
                                    onFullscreen: _toggleWorkspaceFullscreen,
                                  ),
                                ),
                              ),
                              if (!hideChrome)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    isMobile ? 12 : 20,
                                    0,
                                    isMobile ? 12 : 20,
                                    isMobile ? 10 : 16,
                                  ),
                                  child: _ClassControlBar(
                                    micOn: micOn,
                                    cameraOn: cameraOn,
                                    recordingOn: recordingOn,
                                    isLecturer: _isLecturer,
                                    onMic: () =>
                                        _controller.toggleMicrophone(!micOn),
                                    onCamera: () =>
                                        _controller.toggleCamera(!cameraOn),
                                    onChat: () => _showChatSheet(room),
                                    onPeople: () => _showPeopleSheet(room),
                                    onQuestion: _showQuestionSheet,
                                    onRecord: () => _controller.toggleRecording(
                                      !recordingOn,
                                    ),
                                    onClassFullscreen: () => _setClassMode(
                                      _FloatingClassMode.fullscreen,
                                    ),
                                    onLeave: _leaveClass,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_layoutController.currentMode != LiveClassMode.video ||
                            liveFullscreen)
                          _floatingClassPanel(
                            constraints: constraints,
                            isMobile: isMobile,
                            participants: participants,
                            lecturer: lecturer,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }

  Widget _floatingClassPanel({
    required BoxConstraints constraints,
    required bool isMobile,
    required List<LiveSessionParticipant> participants,
    required LiveSessionParticipant? lecturer,
  }) {
    if (_classMode == _FloatingClassMode.fullscreen) {
      return Positioned.fill(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 18),
          child: _LiveClassPanel(
            mode: _classMode,
            participants: participants,
            lecturer: lecturer,
            participantResolver: _controller.mediaParticipantFor,
            onMinimize: () => _setClassMode(_FloatingClassMode.minimized),
            onFullscreen: () => _setClassMode(_FloatingClassMode.floating),
          ),
        ),
      );
    }

    final width = isMobile
        ? (_classMode == _FloatingClassMode.minimized
              ? 172.0
              : constraints.maxWidth * 0.82)
        : _panelSize.width.clamp(320.0, constraints.maxWidth * 0.58).toDouble();
    final height = isMobile
        ? (_classMode == _FloatingClassMode.minimized ? 70.0 : 225.0)
        : _panelSize.height.clamp(210.0, constraints.maxHeight * 0.72).toDouble();
    final panelSize = Size(width, height);
    final offset = _clampOffset(_panelOffset, constraints, panelSize);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: width,
      height: height,
      child: _LiveClassPanel(
        mode: _classMode,
        participants: participants,
        lecturer: lecturer,
        participantResolver: _controller.mediaParticipantFor,
        onDrag: (delta) {
          setState(() {
            _panelOffset = _clampOffset(
              _panelOffset + delta,
              constraints,
              panelSize,
            );
          });
        },
        onResize: isMobile
            ? null
            : (delta) {
                setState(() {
                  _panelSize = Size(
                    (_panelSize.width + delta.dx)
                        .clamp(320.0, constraints.maxWidth * 0.80)
                        .toDouble(),
                    (_panelSize.height + delta.dy)
                        .clamp(210.0, constraints.maxHeight * 0.80)
                        .toDouble(),
                  );
                });
              },
        onMinimize: () => _setClassMode(
          _classMode == _FloatingClassMode.minimized
              ? _FloatingClassMode.floating
              : _FloatingClassMode.minimized,
        ),
        onFullscreen: () => _setClassMode(_FloatingClassMode.fullscreen),
      ),
    );
  }

  Offset _clampOffset(
    Offset value,
    BoxConstraints constraints,
    Size panelSize,
  ) {
    final maxX = math.max(8.0, constraints.maxWidth - panelSize.width - 8);
    final maxY = math.max(8.0, constraints.maxHeight - panelSize.height - 8);
    return Offset(
      value.dx.clamp(8.0, maxX).toDouble(),
      value.dy.clamp(8.0, maxY).toDouble(),
    );
  }

  Future<void> _showChatSheet(LiveSessionRoomState room) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.70;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              8,
              18,
              MediaQuery.viewInsetsOf(context).bottom + 18,
            ),
            child: SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class chat',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: room.chatMessages.isEmpty
                        ? const Center(child: Text('No messages yet.'))
                        : ListView.separated(
                            itemCount: room.chatMessages.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = room.chatMessages[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                tileColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.40),
                                title: Text(item.senderName),
                                subtitle: Text(item.message),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: const InputDecoration(
                            hintText: 'Write a message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          await _sendChat();
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPeopleSheet(LiveSessionRoomState room) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final people = _sortedParticipants(room);
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            itemCount: people.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Participants',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }
              final item = people[index - 1];
              return ListTile(
                leading: CircleAvatar(child: Text(_initials(item.displayName))),
                title: Text(item.displayName),
                subtitle: Text(
                  item.role == LiveSessionRole.lecturer
                      ? 'Lecturer'
                      : (item.registrationNumber ?? 'Student'),
                ),
                trailing: Wrap(
                  spacing: 6,
                  children: [
                    Icon(
                      item.micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                    ),
                    Icon(
                      item.cameraEnabled
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showQuestionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              8,
              18,
              MediaQuery.viewInsetsOf(context).bottom + 18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask the lecturer',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _questionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your question...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await _sendQuestion();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Send question'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.substring(0, 1)
        : '';
    return '$first$last'.toUpperCase();
  }
}

class _ClassHeader extends StatelessWidget {
  const _ClassHeader({
    required this.room,
    required this.participants,
    required this.recordingOn,
    required this.isConnecting,
    required this.onFullscreen,
    required this.onLeave,
  });

  final LiveSessionRoomState room;
  final List<LiveSessionParticipant> participants;
  final bool recordingOn;
  final bool isConnecting;
  final VoidCallback onFullscreen;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final narrow = MediaQuery.sizeOf(context).width < 820;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClassTitle(room: room),
                  const SizedBox(height: 12),
                  _ClassHeaderActions(
                    participants: participants,
                    recordingOn: recordingOn,
                    isConnecting: isConnecting,
                    onFullscreen: onFullscreen,
                    onLeave: onLeave,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _ClassTitle(room: room)),
                  const SizedBox(width: 16),
                  _ClassHeaderActions(
                    participants: participants,
                    recordingOn: recordingOn,
                    isConnecting: isConnecting,
                    onFullscreen: onFullscreen,
                    onLeave: onLeave,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ClassTitle extends StatelessWidget {
  const _ClassTitle({required this.room});

  final LiveSessionRoomState room;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                room.session.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _Pill(icon: Icons.school_rounded, label: room.session.courseCode),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${room.session.courseTitle} · ${room.session.lecturerName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ClassHeaderActions extends StatelessWidget {
  const _ClassHeaderActions({
    required this.participants,
    required this.recordingOn,
    required this.isConnecting,
    required this.onFullscreen,
    required this.onLeave,
  });

  final List<LiveSessionParticipant> participants;
  final bool recordingOn;
  final bool isConnecting;
  final VoidCallback onFullscreen;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(
          icon: isConnecting ? Icons.sync_rounded : Icons.podcasts_rounded,
          label: isConnecting ? 'Connecting' : 'Classroom',
          tone: isConnecting ? Colors.amberAccent : Colors.greenAccent,
        ),
        _Pill(icon: Icons.groups_rounded, label: '${participants.length} joined'),
        _Pill(
          icon: recordingOn
              ? Icons.fiber_manual_record_rounded
              : Icons.stop_circle_outlined,
          label: recordingOn ? 'Recording' : 'Not recording',
          tone: recordingOn ? Colors.redAccent : null,
        ),
        IconButton.filledTonal(
          tooltip: 'Full screen workspace',
          onPressed: onFullscreen,
          icon: const Icon(Icons.fullscreen_rounded),
        ),
        IconButton.filled(
          tooltip: 'Leave class',
          onPressed: onLeave,
          style: IconButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.exit_to_app_rounded),
        ),
      ],
    );
  }
}

class _WorkspaceStage extends StatelessWidget {
  const _WorkspaceStage({
    required this.room,
    required this.participants,
    required this.boardController,
    required this.layoutController,
    required this.participantResolver,
    required this.onFullscreen,
  });

  final LiveSessionRoomState room;
  final List<LiveSessionParticipant> participants;
  final LiveClassBoardController boardController;
  final LiveClassLayoutController layoutController;
  final LiveSessionMediaParticipantResolver participantResolver;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fullscreen = layoutController.isFullscreen;
    final material = room.session.materials.isEmpty
        ? null
        : room.session.materials[(boardController.currentPage - 1)
              .clamp(0, room.session.materials.length - 1)
              .toInt()];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(fullscreen ? 0 : 30),
        border: fullscreen
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(fullscreen ? 10 : 16),
        child: Column(
          children: [
            if (!fullscreen) ...[
              _WorkspaceToolbar(
                layoutController: layoutController,
                boardController: boardController,
                onFullscreen: onFullscreen,
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(fullscreen ? 18 : 24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: layoutController.currentMode == LiveClassMode.video
                          ? _VideoGrid(
                              participants: participants,
                              participantResolver: participantResolver,
                            )
                          : _SlideSurface(room: room, material: material),
                    ),
                    if (layoutController.currentMode == LiveClassMode.board ||
                        layoutController.currentMode == LiveClassMode.hybrid)
                      Positioned.fill(
                        child: LiveClassBoardCanvas(
                          controller: boardController,
                          isInteractive: layoutController.canUseBoard,
                        ),
                      ),
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _DarkPill(
                            icon: layoutController.currentMode.icon,
                            label: layoutController.currentMode.label,
                          ),
                          if (layoutController.currentMode != LiveClassMode.video)
                            _DarkPill(
                              icon: Icons.bookmark_rounded,
                              label:
                                  'Page ${boardController.currentPage}/${boardController.pageCount}',
                            ),
                          if (layoutController.canUseBoard)
                            _DarkPill(
                              icon: boardController.currentTool.icon,
                              label: boardController.currentTool.label,
                            ),
                        ],
                      ),
                    ),
                    if (layoutController.currentMode != LiveClassMode.video)
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: _PageControls(controller: boardController),
                      ),
                    if (fullscreen)
                      Positioned(
                        right: 14,
                        top: 14,
                        child: IconButton.filledTonal(
                          tooltip: 'Exit full screen',
                          onPressed: onFullscreen,
                          icon: const Icon(Icons.fullscreen_exit_rounded),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef LiveSessionMediaParticipantResolver = dynamic Function(String participantId);

class _WorkspaceToolbar extends StatelessWidget {
  const _WorkspaceToolbar({
    required this.layoutController,
    required this.boardController,
    required this.onFullscreen,
  });

  final LiveClassLayoutController layoutController;
  final LiveClassBoardController boardController;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    const modes = [
      LiveClassMode.presentation,
      LiveClassMode.board,
      LiveClassMode.hybrid,
      LiveClassMode.video,
    ];
    const tools = [
      LiveClassBoardTool.pen,
      LiveClassBoardTool.highlighter,
      LiveClassBoardTool.eraser,
      LiveClassBoardTool.pointer,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mode in modes) ...[
            ChoiceChip(
              selected: layoutController.currentMode == mode,
              avatar: Icon(mode.icon, size: 18),
              label: Text(mode.label),
              onSelected: (_) => layoutController.setMode(mode),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 8),
          for (final tool in tools) ...[
            FilterChip(
              selected: boardController.currentTool == tool,
              avatar: Icon(tool.icon, size: 18),
              label: Text(tool.label),
              onSelected: layoutController.canUseBoard
                  ? (_) => boardController.setTool(tool)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: boardController.canUndo ? boardController.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Redo',
            onPressed: boardController.canRedo ? boardController.redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Full screen workspace',
            onPressed: onFullscreen,
            icon: const Icon(Icons.fullscreen_rounded),
          ),
        ],
      ),
    );
  }
}

class _SlideSurface extends StatelessWidget {
  const _SlideSurface({required this.room, required this.material});

  final LiveSessionRoomState room;
  final LiveSessionMaterial? material;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.72),
            cs.surface.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.92,
          heightFactor: 0.78,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _Pill(
                        icon: Icons.picture_as_pdf_rounded,
                        label: material == null ? 'No slide' : 'Slides / PDF',
                      ),
                      _Pill(icon: Icons.room_rounded, label: room.session.roomLabel),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    material?.title ?? room.session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    material?.subtitle ?? room.session.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Drag the live class panel, resize it on desktop, or make it full screen when teaching.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveClassPanel extends StatelessWidget {
  const _LiveClassPanel({
    required this.mode,
    required this.participants,
    required this.lecturer,
    required this.participantResolver,
    required this.onMinimize,
    required this.onFullscreen,
    this.onDrag,
    this.onResize,
  });

  final _FloatingClassMode mode;
  final List<LiveSessionParticipant> participants;
  final LiveSessionParticipant? lecturer;
  final LiveSessionMediaParticipantResolver participantResolver;
  final VoidCallback onMinimize;
  final VoidCallback onFullscreen;
  final ValueChanged<Offset>? onDrag;
  final ValueChanged<Offset>? onResize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final minimized = mode == _FloatingClassMode.minimized;
    final fullscreen = mode == _FloatingClassMode.fullscreen;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(fullscreen ? 28 : 24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(fullscreen ? 28 : 24),
          child: Stack(
            children: [
              Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: onDrag == null
                        ? null
                        : (details) => onDrag!(details.delta),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
                      child: Row(
                        children: [
                          Icon(
                            fullscreen
                                ? Icons.fullscreen_rounded
                                : Icons.picture_in_picture_alt_rounded,
                            size: 20,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              minimized ? 'Live class' : 'Live class stage',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          IconButton(
                            tooltip: minimized ? 'Expand' : 'Minimize',
                            onPressed: onMinimize,
                            icon: Icon(
                              minimized
                                  ? Icons.open_in_full_rounded
                                  : Icons.remove_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: fullscreen
                                ? 'Exit full screen'
                                : 'Full screen class',
                            onPressed: onFullscreen,
                            icon: Icon(
                              fullscreen
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!minimized)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: fullscreen
                            ? _VideoGrid(
                                participants: participants,
                                participantResolver: participantResolver,
                              )
                            : _FocusedVideo(
                                lecturer: lecturer,
                                participants: participants,
                                participantResolver: participantResolver,
                              ),
                      ),
                    ),
                ],
              ),
              if (onResize != null && !minimized && !fullscreen)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) => onResize!(details.delta),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 22,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedVideo extends StatelessWidget {
  const _FocusedVideo({
    required this.lecturer,
    required this.participants,
    required this.participantResolver,
  });

  final LiveSessionParticipant? lecturer;
  final List<LiveSessionParticipant> participants;
  final LiveSessionMediaParticipantResolver participantResolver;

  @override
  Widget build(BuildContext context) {
    final main = lecturer ?? (participants.isEmpty ? null : participants.first);
    if (main == null) {
      return const Center(child: Text('Waiting for participants...'));
    }
    final others = participants.where((item) => item.id != main.id).take(4);

    return Column(
      children: [
        Expanded(
          child: LiveSessionVideoSurface(
            participant: main,
            mediaParticipant: participantResolver(main.id),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _NameChip(participant: main),
              for (final item in others) _NameChip(participant: item),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoGrid extends StatelessWidget {
  const _VideoGrid({
    required this.participants,
    required this.participantResolver,
  });

  final List<LiveSessionParticipant> participants;
  final LiveSessionMediaParticipantResolver participantResolver;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(child: Text('Waiting for participants...'));
    }
    final width = MediaQuery.sizeOf(context).width;
    final count = participants.length;
    final columns = width < 720
        ? 1
        : count <= 2
            ? count
            : count <= 4
                ? 2
                : 3;

    return GridView.builder(
      padding: const EdgeInsets.all(6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: width < 720 ? 1.35 : 16 / 10,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return Stack(
          children: [
            Positioned.fill(
              child: LiveSessionVideoSurface(
                participant: participant,
                mediaParticipant: participantResolver(participant.id),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: _NameChip(participant: participant),
            ),
          ],
        );
      },
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({required this.participant});

  final LiveSessionParticipant participant;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            participant.role == LiveSessionRole.lecturer
                ? Icons.school_rounded
                : Icons.person_rounded,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              participant.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassControlBar extends StatelessWidget {
  const _ClassControlBar({
    required this.micOn,
    required this.cameraOn,
    required this.recordingOn,
    required this.isLecturer,
    required this.onMic,
    required this.onCamera,
    required this.onChat,
    required this.onPeople,
    required this.onQuestion,
    required this.onRecord,
    required this.onClassFullscreen,
    required this.onLeave,
  });

  final bool micOn;
  final bool cameraOn;
  final bool recordingOn;
  final bool isLecturer;
  final VoidCallback onMic;
  final VoidCallback onCamera;
  final VoidCallback onChat;
  final VoidCallback onPeople;
  final VoidCallback onQuestion;
  final VoidCallback onRecord;
  final VoidCallback onClassFullscreen;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final children = <Widget>[
      _ControlButton(
        icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
        label: micOn ? 'Mute' : 'Unmute',
        selected: micOn,
        compact: compact,
        onPressed: onMic,
      ),
      _ControlButton(
        icon: cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
        label: cameraOn ? 'Camera' : 'Camera off',
        selected: cameraOn,
        compact: compact,
        onPressed: onCamera,
      ),
      _ControlButton(
        icon: Icons.chat_rounded,
        label: 'Chat',
        compact: compact,
        onPressed: onChat,
      ),
      _ControlButton(
        icon: Icons.groups_rounded,
        label: 'People',
        compact: compact,
        onPressed: onPeople,
      ),
      _ControlButton(
        icon: Icons.fullscreen_rounded,
        label: 'Class full',
        compact: compact,
        onPressed: onClassFullscreen,
      ),
      _MoreButton(
        actions: [
          _MenuAction(Icons.question_answer_rounded, 'Ask question', onQuestion),
          if (isLecturer)
            _MenuAction(
              recordingOn
                  ? Icons.stop_circle_rounded
                  : Icons.fiber_manual_record_rounded,
              recordingOn ? 'Stop recording' : 'Record class',
              onRecord,
            ),
        ],
      ),
      _ControlButton(
        icon: Icons.exit_to_app_rounded,
        label: isLecturer ? 'End class' : 'Leave',
        danger: true,
        compact: compact,
        onPressed: onLeave,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final child in children) ...[child, const SizedBox(width: 8)],
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.danger = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
  final bool danger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = danger
        ? Colors.redAccent
        : selected
            ? cs.primary
            : cs.surfaceContainerHighest.withValues(alpha: 0.86);
    final fg = danger || selected ? Colors.white : cs.onSurface;

    if (compact) {
      return IconButton.filledTonal(
        tooltip: label,
        onPressed: onPressed,
        style: IconButton.styleFrom(backgroundColor: bg, foregroundColor: fg),
        icon: Icon(icon),
      );
    }

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg),
      icon: Icon(icon, size: 19),
      label: Text(label),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.actions});

  final List<_MenuAction> actions;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final action in actions)
                  ListTile(
                    leading: Icon(action.icon),
                    title: Text(action.label),
                    onTap: () {
                      Navigator.of(context).pop();
                      action.onPressed();
                    },
                  ),
              ],
            ),
          ),
        );
      },
      icon: const Icon(Icons.more_horiz_rounded),
      label: const Text('More'),
    );
  }
}

class _MenuAction {
  const _MenuAction(this.icon, this.label, this.onPressed);
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class _PageControls extends StatelessWidget {
  const _PageControls({required this.controller});

  final LiveClassBoardController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Previous page',
              color: Colors.white,
              onPressed: controller.currentPage > 1 ? controller.previousPage : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              'Page ${controller.currentPage}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              tooltip: 'Next page',
              color: Colors.white,
              onPressed: controller.currentPage < controller.pageCount
                  ? controller.nextPage
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
