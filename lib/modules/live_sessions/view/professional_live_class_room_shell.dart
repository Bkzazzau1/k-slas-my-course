import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../controller/live_class_workspace_controller.dart';
import '../controller/live_sessions_controller.dart';
import '../widgets/live_class_board_canvas.dart';
import '../widgets/live_session_video_surface.dart';

enum _LivePanelMode { floating, minimized, fullscreen }

class ProfessionalLiveClassRoomShell extends StatefulWidget {
  const ProfessionalLiveClassRoomShell({super.key});

  @override
  State<ProfessionalLiveClassRoomShell> createState() =>
      _ProfessionalLiveClassRoomShellState();
}

class _ProfessionalLiveClassRoomShellState
    extends State<ProfessionalLiveClassRoomShell> {
  late final LiveSessionsController _controller;
  late final LiveClassBoardController _boardController;
  late final LiveClassLayoutController _layoutController;
  late final String _sessionId;
  late final String _role;
  late final String _displayName;
  late final String _userId;
  late final String? _registrationNumber;

  final TextEditingController _chatCtrl = TextEditingController();
  final TextEditingController _questionCtrl = TextEditingController();

  Timer? _refreshTimer;
  _LivePanelMode _livePanelMode = _LivePanelMode.floating;
  Offset _livePanelOffset = const Offset(28, 92);
  Size _livePanelSize = const Size(390, 270);

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
        (_isLecturer
            ? (args['lecturerName']?.toString() ?? 'Course lecturer')
            : (profile?.fullName ?? 'Student'));
    _registrationNumber = _isLecturer
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
    _chatCtrl.dispose();
    _questionCtrl.dispose();
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
    if (room != null) _syncWorkspace(room);
  }

  void _syncWorkspace(LiveSessionRoomState room) {
    final pageCount = math.max(1, room.session.materials.length);
    if (_boardController.pageCount != pageCount) {
      _boardController.setPageCount(pageCount);
    }
  }

  LiveSessionParticipant? _currentParticipant(LiveSessionRoomState room) {
    final participantId = _controller.activeParticipantId.value;
    return room.participants.firstWhereOrNull(
      (participant) => participant.id == participantId,
    );
  }

  LiveSessionParticipant? _lecturerParticipant(LiveSessionRoomState room) {
    return room.participants.firstWhereOrNull(
      (participant) => participant.role == LiveSessionRole.lecturer,
    );
  }

  List<LiveSessionParticipant> _sortedParticipants(LiveSessionRoomState room) {
    final participants = [...room.participants];
    participants.sort((a, b) {
      final aRole = a.role == LiveSessionRole.lecturer ? 0 : 1;
      final bRole = b.role == LiveSessionRole.lecturer ? 0 : 1;
      if (aRole != bRole) return aRole.compareTo(bRole);

      final aPresence = a.isPresent ? 0 : 1;
      final bPresence = b.isPresent ? 0 : 1;
      if (aPresence != bPresence) return aPresence.compareTo(bPresence);

      return a.displayName.compareTo(b.displayName);
    });
    return participants;
  }

  LiveClassSessionUiState _sessionStateFor({
    required LiveSessionRoomState room,
    required bool mediaConnecting,
  }) {
    final now = DateTime.now();
    if (room.session.isCompletedAt(now)) return LiveClassSessionUiState.ended;
    if (mediaConnecting) return LiveClassSessionUiState.reconnecting;
    if (_layoutController.isSessionPaused) return LiveClassSessionUiState.paused;
    if (room.session.isLiveAt(now)) return LiveClassSessionUiState.live;
    return LiveClassSessionUiState.initializing;
  }

  Future<void> _toggleStageFullscreen() async {
    _layoutController.toggleFullscreen();
    await _applySystemFullscreen(
      _layoutController.isFullscreen || _livePanelMode == _LivePanelMode.fullscreen,
    );
  }

  Future<void> _setLivePanelMode(_LivePanelMode mode) async {
    setState(() => _livePanelMode = mode);
    await _applySystemFullscreen(
      mode == _LivePanelMode.fullscreen || _layoutController.isFullscreen,
    );
  }

  Future<void> _applySystemFullscreen(bool enabled) {
    return SystemChrome.setEnabledSystemUIMode(
      enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _toggleMic(bool nextValue) async {
    await _controller.toggleMicrophone(nextValue);
  }

  Future<void> _toggleCamera(bool nextValue) async {
    await _controller.toggleCamera(nextValue);
    final room = _controller.room.value;
    if (room != null) _syncWorkspace(room);
  }

  Future<void> _toggleRecording(bool nextValue) async {
    await _controller.toggleRecording(nextValue);
  }

  Future<void> _sendChat() async {
    final message = _chatCtrl.text.trim();
    if (message.isEmpty) return;
    await _controller.sendChat(
      senderName: _displayName,
      senderRole: _role,
      message: message,
      registrationNumber: _registrationNumber,
    );
    _chatCtrl.clear();
  }

  Future<void> _submitQuestion() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty) return;
    await _controller.askQuestion(
      askedByName: _displayName,
      question: question,
      registrationNumber: _registrationNumber,
    );
    _questionCtrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question sent to the lecturer.')),
    );
  }

  void _leaveClassroom() {
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
          final mediaConnecting = _controller.isConnectingMedia.value;
          final mediaRoom = _controller.rtcRoom.value;

          if (loading || room == null || room.session.id != _sessionId) {
            return const Center(child: CircularProgressIndicator());
          }

          _syncWorkspace(room);

          final participant = _currentParticipant(room);
          final lecturer = _lecturerParticipant(room);
          final participants = _sortedParticipants(room);
          final sessionState = _sessionStateFor(
            room: room,
            mediaConnecting: mediaConnecting,
          );
          final recordingOn =
              participant?.recordingEnabled ??
              room.recordings.any((recording) => recording.isActive);
          final cameraOn = participant?.cameraEnabled ?? false;
          final micOn = participant?.micEnabled ?? false;

          return AnimatedBuilder(
            animation: Listenable.merge([_layoutController, _boardController]),
            builder: (context, _) {
              return _buildResponsiveWorkspace(
                context,
                room: room,
                mediaRoom: mediaRoom,
                lecturer: lecturer,
                participants: participants,
                participant: participant,
                sessionState: sessionState,
                micOn: micOn,
                cameraOn: cameraOn,
                recordingOn: recordingOn,
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildResponsiveWorkspace(
    BuildContext context, {
    required LiveSessionRoomState room,
    required lk.Room? mediaRoom,
    required LiveSessionParticipant? lecturer,
    required List<LiveSessionParticipant> participants,
    required LiveSessionParticipant? participant,
    required LiveClassSessionUiState sessionState,
    required bool micOn,
    required bool cameraOn,
    required bool recordingOn,
  }) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 700;
    final isStageFullscreen = _layoutController.isFullscreen;
    final isLiveFullscreen = _livePanelMode == _LivePanelMode.fullscreen;
    final showChrome = !isStageFullscreen && !isLiveFullscreen;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    if (showChrome) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 12 : 20,
                          isMobile ? 10 : 18,
                          isMobile ? 12 : 20,
                          10,
                        ),
                        child: _buildProfessionalHeader(
                          context,
                          room: room,
                          sessionState: sessionState,
                          recordingOn: recordingOn,
                          participants: participants,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isStageFullscreen ? 0 : (isMobile ? 12 : 20),
                          showChrome ? 0 : 0,
                          isStageFullscreen ? 0 : (isMobile ? 12 : 20),
                          showChrome ? 10 : 0,
                        ),
                        child: _buildMainStage(
                          context,
                          room: room,
                          mediaRoom: mediaRoom,
                          lecturer: lecturer,
                          participants: participants,
                          isMobile: isMobile,
                        ),
                      ),
                    ),
                    if (showChrome)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 12 : 20,
                          0,
                          isMobile ? 12 : 20,
                          isMobile ? 10 : 16,
                        ),
                        child: _buildBottomControls(
                          context,
                          room: room,
                          participant: participant,
                          micOn: micOn,
                          cameraOn: cameraOn,
                          recordingOn: recordingOn,
                          isMobile: isMobile,
                        ),
                      ),
                  ],
                ),
              ),
              if (_layoutController.currentMode != LiveClassMode.video ||
                  isLiveFullscreen)
                _buildLivePanelLayer(
                  context,
                  constraints: constraints,
                  mediaRoom: mediaRoom,
                  participants: participants,
                  lecturer: lecturer,
                  isMobile: isMobile,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfessionalHeader(
    BuildContext context, {
    required LiveSessionRoomState room,
    required LiveClassSessionUiState sessionState,
    required bool recordingOn,
    required List<LiveSessionParticipant> participants,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isNarrow = MediaQuery.sizeOf(context).width < 820;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(isNarrow ? 22 : 28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? 16 : 22,
          vertical: isNarrow ? 14 : 18,
        ),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderTitleBlock(room: room),
                  const SizedBox(height: 12),
                  _HeaderStatusRow(
                    sessionState: sessionState,
                    recordingOn: recordingOn,
                    participants: participants,
                    onStageFullscreen: _toggleStageFullscreen,
                    onLeave: _leaveClassroom,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _HeaderTitleBlock(room: room)),
                  const SizedBox(width: 16),
                  _HeaderStatusRow(
                    sessionState: sessionState,
                    recordingOn: recordingOn,
                    participants: participants,
                    onStageFullscreen: _toggleStageFullscreen,
                    onLeave: _leaveClassroom,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMainStage(
    BuildContext context, {
    required LiveSessionRoomState room,
    required lk.Room? mediaRoom,
    required LiveSessionParticipant? lecturer,
    required List<LiveSessionParticipant> participants,
    required bool isMobile,
  }) {
    final cs = Theme.of(context).colorScheme;
    final currentMaterial = room.session.materials.isEmpty
        ? null
        : room.session.materials[(_boardController.currentPage - 1)
              .clamp(0, room.session.materials.length - 1)
              .toInt()];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(_layoutController.isFullscreen ? 0 : 30),
        border: _layoutController.isFullscreen
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_layoutController.isFullscreen ? 12 : (isMobile ? 12 : 16)),
        child: Column(
          children: [
            if (!_layoutController.isFullscreen)
              _buildStageModeBar(context, isMobile: isMobile),
            if (!_layoutController.isFullscreen) const SizedBox(height: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_layoutController.isFullscreen ? 18 : 24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _layoutController.currentMode == LiveClassMode.video
                          ? _VideoGrid(
                              participants: participants,
                              participantResolver: _controller.mediaParticipantFor,
                              dense: isMobile,
                            )
                          : _PresentationWorkspace(
                              material: currentMaterial,
                              room: room,
                              boardController: _boardController,
                              layoutController: _layoutController,
                            ),
                    ),
                    if (_layoutController.currentMode != LiveClassMode.video)
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !_layoutController.canUseBoard,
                          child: LiveClassBoardCanvas(
                            controller: _boardController,
                            isInteractive: _layoutController.canUseBoard,
                          ),
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
                          _StagePill(
                            icon: _layoutController.currentMode.icon,
                            label: _layoutController.currentMode.label,
                          ),
                          if (_layoutController.currentMode != LiveClassMode.video)
                            _StagePill(
                              icon: Icons.bookmark_rounded,
                              label:
                                  'Page ${_boardController.currentPage}/${_boardController.pageCount}',
                            ),
                          if (_layoutController.canUseBoard)
                            _StagePill(
                              icon: _boardController.currentTool.icon,
                              label: _boardController.currentTool.label,
                            ),
                        ],
                      ),
                    ),
                    if (_layoutController.currentMode != LiveClassMode.video)
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: _PageNavigation(controller: _boardController),
                      ),
                    if (_layoutController.isFullscreen)
                      Positioned(
                        right: 14,
                        top: 14,
                        child: IconButton.filledTonal(
                          tooltip: 'Exit full screen',
                          onPressed: _toggleStageFullscreen,
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

  Widget _buildStageModeBar(BuildContext context, {required bool isMobile}) {
    final modes = isMobile
        ? const [
            LiveClassMode.presentation,
            LiveClassMode.hybrid,
            LiveClassMode.video,
          ]
        : const [
            LiveClassMode.presentation,
            LiveClassMode.board,
            LiveClassMode.hybrid,
            LiveClassMode.video,
          ];
    final tools = const [
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
              selected: _layoutController.currentMode == mode,
              label: Text(mode.label),
              avatar: Icon(mode.icon, size: 18),
              onSelected: (_) => _layoutController.setMode(mode),
            ),
            const SizedBox(width: 8),
          ],
          const SizedBox(width: 8),
          for (final tool in tools) ...[
            FilterChip(
              selected: _boardController.currentTool == tool,
              label: Text(tool.label),
              avatar: Icon(tool.icon, size: 18),
              onSelected: _layoutController.canUseBoard
                  ? (_) => _boardController.setTool(tool)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          IconButton.filledTonal(
            tooltip: 'Undo',
            onPressed: _boardController.canUndo ? _boardController.undo : null,
            icon: const Icon(Icons.undo_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Redo',
            onPressed: _boardController.canRedo ? _boardController.redo : null,
            icon: const Icon(Icons.redo_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Full screen stage',
            onPressed: _toggleStageFullscreen,
            icon: const Icon(Icons.fullscreen_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePanelLayer(
    BuildContext context, {
    required BoxConstraints constraints,
    required lk.Room? mediaRoom,
    required List<LiveSessionParticipant> participants,
    required LiveSessionParticipant? lecturer,
    required bool isMobile,
  }) {
    if (_livePanelMode == _LivePanelMode.fullscreen) {
      return Positioned.fill(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 18),
          child: _LivePanelCard(
            mode: _livePanelMode,
            participants: participants,
            lecturer: lecturer,
            participantResolver: _controller.mediaParticipantFor,
            onMinimize: () => _setLivePanelMode(_LivePanelMode.minimized),
            onFullscreen: () => _setLivePanelMode(_LivePanelMode.floating),
            onClose: () => _setLivePanelMode(_LivePanelMode.minimized),
            isMobile: isMobile,
          ),
        ),
      );
    }

    final panelWidth = isMobile
        ? (_livePanelMode == _LivePanelMode.minimized ? 178.0 : constraints.maxWidth * 0.82)
        : _livePanelSize.width.clamp(320.0, constraints.maxWidth * 0.52).toDouble();
    final panelHeight = isMobile
        ? (_livePanelMode == _LivePanelMode.minimized ? 70.0 : 230.0)
        : _livePanelSize.height.clamp(210.0, constraints.maxHeight * 0.72).toDouble();
    final panelSize = Size(panelWidth, panelHeight);
    final offset = _clampPanelOffset(_livePanelOffset, constraints, panelSize);

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      width: panelSize.width,
      height: panelSize.height,
      child: _LivePanelCard(
        mode: _livePanelMode,
        participants: participants,
        lecturer: lecturer,
        participantResolver: _controller.mediaParticipantFor,
        onDrag: (delta) {
          setState(() {
            _livePanelOffset = _clampPanelOffset(
              _livePanelOffset + delta,
              constraints,
              panelSize,
            );
          });
        },
        onResize: isMobile
            ? null
            : (delta) {
                setState(() {
                  final nextWidth = (_livePanelSize.width + delta.dx)
                      .clamp(320.0, constraints.maxWidth * 0.78)
                      .toDouble();
                  final nextHeight = (_livePanelSize.height + delta.dy)
                      .clamp(210.0, constraints.maxHeight * 0.78)
                      .toDouble();
                  _livePanelSize = Size(nextWidth, nextHeight);
                });
              },
        onMinimize: () => _setLivePanelMode(
          _livePanelMode == _LivePanelMode.minimized
              ? _LivePanelMode.floating
              : _LivePanelMode.minimized,
        ),
        onFullscreen: () => _setLivePanelMode(_LivePanelMode.fullscreen),
        onClose: () => _setLivePanelMode(_LivePanelMode.minimized),
        isMobile: isMobile,
      ),
    );
  }

  Offset _clampPanelOffset(
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

  Widget _buildBottomControls(
    BuildContext context, {
    required LiveSessionRoomState room,
    required LiveSessionParticipant? participant,
    required bool micOn,
    required bool cameraOn,
    required bool recordingOn,
    required bool isMobile,
  }) {
    final participantId = participant?.id ?? _userId;
    final handRaised = _layoutController.raisedHands.contains(participantId);
    final compact = MediaQuery.sizeOf(context).width < 860;

    final primaryActions = <Widget>[
      _ClassControlButton(
        icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
        label: micOn ? 'Mute' : 'Unmute',
        selected: micOn,
        onPressed: () => _toggleMic(!micOn),
        compact: compact,
      ),
      _ClassControlButton(
        icon: cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
        label: cameraOn ? 'Camera' : 'Camera off',
        selected: cameraOn,
        onPressed: () => _toggleCamera(!cameraOn),
        compact: compact,
      ),
      _ClassControlButton(
        icon: Icons.chat_rounded,
        label: 'Chat',
        onPressed: () => _showChatSheet(room),
        compact: compact,
      ),
      _ClassControlButton(
        icon: Icons.groups_rounded,
        label: 'People',
        onPressed: () => _showPeopleSheet(room),
        compact: compact,
      ),
    ];

    final moreActions = <_ControlSheetAction>[
      _ControlSheetAction(
        icon: handRaised ? Icons.back_hand_rounded : Icons.front_hand_rounded,
        label: handRaised ? 'Lower hand' : 'Raise hand',
        onPressed: () {
          _layoutController.setRaisedHand(participantId, !handRaised);
        },
      ),
      _ControlSheetAction(
        icon: Icons.question_answer_rounded,
        label: 'Ask question',
        onPressed: () => _showQuestionSheet(),
      ),
      _ControlSheetAction(
        icon: Icons.folder_open_rounded,
        label: 'Class resources',
        onPressed: () => _showResourcesSheet(room),
      ),
      if (_isLecturer)
        _ControlSheetAction(
          icon: recordingOn
              ? Icons.stop_circle_rounded
              : Icons.fiber_manual_record_rounded,
          label: recordingOn ? 'Stop recording' : 'Record class',
          onPressed: () => _toggleRecording(!recordingOn),
        ),
      if (_isLecturer)
        _ControlSheetAction(
          icon: _layoutController.isSessionPaused
              ? Icons.play_arrow_rounded
              : Icons.pause_rounded,
          label: _layoutController.isSessionPaused ? 'Resume class' : 'Pause class',
          onPressed: _layoutController.toggleSessionPaused,
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
              for (final action in primaryActions) ...[
                action,
                const SizedBox(width: 8),
              ],
              _ClassControlButton(
                icon: _livePanelMode == _LivePanelMode.fullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                label: 'Class full',
                selected: _livePanelMode == _LivePanelMode.fullscreen,
                onPressed: () => _setLivePanelMode(
                  _livePanelMode == _LivePanelMode.fullscreen
                      ? _LivePanelMode.floating
                      : _LivePanelMode.fullscreen,
                ),
                compact: compact,
              ),
              const SizedBox(width: 8),
              _MoreClassControlsButton(actions: moreActions),
              const SizedBox(width: 8),
              _ClassControlButton(
                icon: Icons.exit_to_app_rounded,
                label: isMobile ? 'Exit' : (_isLecturer ? 'End class' : 'Leave'),
                danger: true,
                onPressed: _leaveClassroom,
                compact: compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChatSheet(LiveSessionRoomState room) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
              top: 8,
            ),
            child: SizedBox(
              height: math.min(MediaQuery.sizeOf(context).height * 0.72, 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Class chat',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: room.chatMessages.isEmpty
                        ? const Center(child: Text('No messages yet.'))
                        : ListView.separated(
                            itemCount: room.chatMessages.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = room.chatMessages[index];
                              return ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                tileColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                title: Text(item.senderName),
                                subtitle: Text(item.message),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Write a class message...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) async {
                            await _sendChat();
                            if (mounted) Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
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
        final participants = _sortedParticipants(room);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participants',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(_initials(participant.displayName)),
                        ),
                        title: Text(participant.displayName),
                        subtitle: Text(
                          participant.role == LiveSessionRole.lecturer
                              ? 'Lecturer'
                              : (participant.registrationNumber ?? 'Student'),
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            Icon(
                              participant.micEnabled
                                  ? Icons.mic_rounded
                                  : Icons.mic_off_rounded,
                              size: 18,
                            ),
                            Icon(
                              participant.cameraEnabled
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showQuestionSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 18,
              right: 18,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask the lecturer',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _questionCtrl,
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
                      await _submitQuestion();
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

  Future<void> _showResourcesSheet(LiveSessionRoomState room) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class resources',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (room.session.materials.isEmpty)
                  const ListTile(title: Text('No resources uploaded yet.'))
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: room.session.materials.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = room.session.materials[index];
                        return ListTile(
                          leading: const Icon(Icons.picture_as_pdf_rounded),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          trailing: Text(item.status),
                          onTap: () {
                            _boardController.setPage(index + 1);
                            Navigator.of(context).pop();
                          },
                        );
                      },
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
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

class _HeaderTitleBlock extends StatelessWidget {
  const _HeaderTitleBlock({required this.room});

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
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            _StatusPill(
              icon: Icons.school_rounded,
              label: room.session.courseCode,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${room.session.courseTitle} · ${room.session.lecturerName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _HeaderStatusRow extends StatelessWidget {
  const _HeaderStatusRow({
    required this.sessionState,
    required this.recordingOn,
    required this.participants,
    required this.onStageFullscreen,
    required this.onLeave,
  });

  final LiveClassSessionUiState sessionState;
  final bool recordingOn;
  final List<LiveSessionParticipant> participants;
  final VoidCallback onStageFullscreen;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _StatusPill(
          icon: Icons.podcasts_rounded,
          label: sessionState.label,
          tone: _sessionColor(sessionState),
        ),
        _StatusPill(
          icon: Icons.groups_rounded,
          label: '${participants.length} in class',
        ),
        _StatusPill(
          icon: recordingOn
              ? Icons.fiber_manual_record_rounded
              : Icons.stop_circle_outlined,
          label: recordingOn ? 'Recording' : 'Not recording',
          tone: recordingOn ? Colors.redAccent : null,
        ),
        IconButton.filledTonal(
          tooltip: 'Full screen stage',
          onPressed: onStageFullscreen,
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

  Color _sessionColor(LiveClassSessionUiState state) {
    switch (state) {
      case LiveClassSessionUiState.live:
        return Colors.greenAccent;
      case LiveClassSessionUiState.paused:
        return Colors.orangeAccent;
      case LiveClassSessionUiState.reconnecting:
        return Colors.amberAccent;
      case LiveClassSessionUiState.ended:
        return Colors.redAccent;
      case LiveClassSessionUiState.initializing:
        return Colors.lightBlueAccent;
    }
  }
}

class _PresentationWorkspace extends StatelessWidget {
  const _PresentationWorkspace({
    required this.material,
    required this.room,
    required this.boardController,
    required this.layoutController,
  });

  final LiveSessionMaterial? material;
  final LiveSessionRoomState room;
  final LiveClassBoardController boardController;
  final LiveClassLayoutController layoutController;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showBoard =
        layoutController.currentMode == LiveClassMode.board ||
        layoutController.selectedContentSource == LiveClassContentSource.whiteboard;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest.withValues(alpha: 0.72),
            cs.surface.withValues(alpha: 0.94),
          ],
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: showBoard
              ? _BoardEmptyState(key: const ValueKey('board'))
              : _MaterialCard(
                  key: ValueKey(material?.title ?? 'empty'),
                  material: material,
                  room: room,
                ),
        ),
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({super.key, required this.material, required this.room});

  final LiveSessionMaterial? material;
  final LiveSessionRoomState room;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: 0.92,
      heightFactor: 0.78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.40)),
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
                  _StagePill(
                    icon: Icons.picture_as_pdf_rounded,
                    label: material == null ? 'No slide' : 'Slides / PDF',
                  ),
                  _StagePill(
                    icon: Icons.bookmark_border_rounded,
                    label: room.session.roomLabel,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                material?.title ?? room.session.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                material?.subtitle ?? room.session.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              Text(
                'Use the floating class panel for lecturer video, students, and full-screen live teaching.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardEmptyState extends StatelessWidget {
  const _BoardEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FractionallySizedBox(
      widthFactor: 0.92,
      heightFactor: 0.78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.draw_rounded, size: 54, color: cs.primary),
              const SizedBox(height: 12),
              Text(
                'Whiteboard ready',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Use pen, highlighter, eraser, and pointer from the toolbar.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePanelCard extends StatelessWidget {
  const _LivePanelCard({
    required this.mode,
    required this.participants,
    required this.lecturer,
    required this.participantResolver,
    required this.onMinimize,
    required this.onFullscreen,
    required this.onClose,
    required this.isMobile,
    this.onDrag,
    this.onResize,
  });

  final _LivePanelMode mode;
  final List<LiveSessionParticipant> participants;
  final LiveSessionParticipant? lecturer;
  final lk.Participant? Function(String participantId) participantResolver;
  final ValueChanged<Offset>? onDrag;
  final ValueChanged<Offset>? onResize;
  final VoidCallback onMinimize;
  final VoidCallback onFullscreen;
  final VoidCallback onClose;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final minimized = mode == _LivePanelMode.minimized;
    final fullscreen = mode == _LivePanelMode.fullscreen;

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
                            tooltip: fullscreen ? 'Exit full screen' : 'Full screen class',
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
                                dense: isMobile,
                              )
                            : _FocusedVideoPanel(
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

class _FocusedVideoPanel extends StatelessWidget {
  const _FocusedVideoPanel({
    required this.lecturer,
    required this.participants,
    required this.participantResolver,
  });

  final LiveSessionParticipant? lecturer;
  final List<LiveSessionParticipant> participants;
  final lk.Participant? Function(String participantId) participantResolver;

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
          height: 54,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _VideoNameChip(participant: main),
              for (final participant in others) _VideoNameChip(participant: participant),
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
    required this.dense,
  });

  final List<LiveSessionParticipant> participants;
  final lk.Participant? Function(String participantId) participantResolver;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(child: Text('Waiting for participants...'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = participants.length;
        final columns = dense
            ? 1
            : count <= 2
                ? count
                : count <= 4
                    ? 2
                    : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(6),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns.clamp(1, 3),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: dense ? 1.35 : 16 / 10,
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
                  child: _VideoNameChip(participant: participant),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _VideoNameChip extends StatelessWidget {
  const _VideoNameChip({required this.participant});

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
          Flexible(
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

class _PageNavigation extends StatelessWidget {
  const _PageNavigation({required this.controller});

  final LiveClassBoardController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label, this.tone});

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

class _StagePill extends StatelessWidget {
  const _StagePill({required this.icon, required this.label});

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

class _ClassControlButton extends StatelessWidget {
  const _ClassControlButton({
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
    final background = danger
        ? Colors.redAccent
        : selected
            ? cs.primary
            : cs.surfaceContainerHighest.withValues(alpha: 0.86);
    final foreground = danger || selected ? Colors.white : cs.onSurface;

    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: 12,
        ),
      ),
      icon: Icon(icon, size: 19),
      label: Text(compact ? '' : label),
    );
  }
}

class _MoreClassControlsButton extends StatelessWidget {
  const _MoreClassControlsButton({required this.actions});

  final List<_ControlSheetAction> actions;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        await showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SafeArea(
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
            );
          },
        );
      },
      icon: const Icon(Icons.more_horiz_rounded),
      label: const Text('More'),
    );
  }
}

class _ControlSheetAction {
  const _ControlSheetAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}
