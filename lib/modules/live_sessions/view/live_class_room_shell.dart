import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/live_session_runtime_mode_service.dart';
import '../controller/live_class_workspace_controller.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';
import '../widgets/live_class_board_canvas.dart';
import '../widgets/live_session_video_surface.dart';

class LiveClassRoomShell extends StatefulWidget {
  const LiveClassRoomShell({super.key});

  @override
  State<LiveClassRoomShell> createState() => _LiveClassRoomShellState();
}

class _LiveClassRoomShellState extends State<LiveClassRoomShell> {
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
  final TextEditingController _aiCtrl = TextEditingController();

  Timer? _refreshTimer;

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _openRoom());
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _controller.refreshRoom();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    unawaited(_controller.disconnectMediaRoom());
    _chatCtrl.dispose();
    _questionCtrl.dispose();
    _aiCtrl.dispose();
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
    if (room != null) {
      _syncWorkspace(room);
    }
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

  LiveSessionParticipant? _selectedPresenter(
    LiveSessionRoomState room,
    List<LiveSessionParticipant> participants,
  ) {
    final selectedId =
        _layoutController.activePresenterId ??
        _layoutController.selectedParticipantId;
    if (selectedId != null) {
      return participants.firstWhereOrNull((item) => item.id == selectedId);
    }
    return _lecturerParticipant(room);
  }

  Future<void> _toggleCamera(bool nextValue) async {
    await _controller.toggleCamera(nextValue);
    final room = _controller.room.value;
    if (room != null) {
      _syncWorkspace(room);
    }
  }

  Future<void> _toggleMic(bool nextValue) async {
    await _controller.toggleMicrophone(nextValue);
  }

  Future<void> _toggleRecording(bool nextValue) async {
    await _controller.toggleRecording(nextValue);
  }

  Future<void> _sendChat() async {
    if (_chatCtrl.text.trim().isEmpty) return;
    await _controller.sendChat(
      senderName: _displayName,
      senderRole: _role,
      message: _chatCtrl.text.trim(),
      registrationNumber: _registrationNumber,
    );
    _chatCtrl.clear();
  }

  Future<void> _submitQuestion() async {
    if (_questionCtrl.text.trim().isEmpty) return;
    await _controller.askQuestion(
      askedByName: _displayName,
      question: _questionCtrl.text.trim(),
      registrationNumber: _registrationNumber,
    );
    _questionCtrl.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question sent to the lecturer.')),
      );
    }
  }

  Future<void> _answerQuestion(LiveSessionQuestion question) async {
    final controller = TextEditingController();
    final answer = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Answer question'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Type the lecturer response',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    if (answer == null || answer.isEmpty) return;
    await _controller.answerQuestion(
      questionId: question.id,
      answeredByName: _displayName,
      answer: answer,
    );
  }

  void _handleRealtimeEvent(LiveClassRealtimeEvent event) {
    _boardController.handleRealtimeEvent(event);
    _layoutController.handleRealtimeEvent(event);
  }

  Future<void> _toggleFullscreen() async {
    _layoutController.toggleFullscreen();
    if (_layoutController.isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _leaveClassroom() {
    if (_layoutController.isFullscreen) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    Get.back<void>();
  }

  void _showActionNotice(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRuntimeModeChange(LiveSessionRuntimeMode mode) async {
    await _controller.setRuntimeMode(mode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mode == LiveSessionRuntimeMode.demo
              ? 'Demo mode is active for the school showcase.'
              : 'Production mode selected. The classroom will use the Go stack when configured.',
        ),
      ),
    );
  }

  LiveClassSessionUiState _sessionStateFor({
    required LiveSessionRoomState room,
    required bool mediaConnecting,
  }) {
    final now = DateTime.now();
    if (room.session.isCompletedAt(now)) {
      return LiveClassSessionUiState.ended;
    }
    if (mediaConnecting) {
      return LiveClassSessionUiState.reconnecting;
    }
    if (_layoutController.isSessionPaused) {
      return LiveClassSessionUiState.paused;
    }
    if (room.session.isLiveAt(now)) {
      return LiveClassSessionUiState.live;
    }
    return LiveClassSessionUiState.initializing;
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (_layoutController.canUseBoard)
          const SingleActivator(LogicalKeyboardKey.keyP): () {
            _boardController.setTool(LiveClassBoardTool.pen);
          },
        if (_layoutController.canUseBoard)
          const SingleActivator(LogicalKeyboardKey.keyH): () {
            _boardController.setTool(LiveClassBoardTool.highlighter);
          },
        if (_layoutController.canUseBoard)
          const SingleActivator(LogicalKeyboardKey.keyE): () {
            _boardController.setTool(LiveClassBoardTool.eraser);
          },
        if (_layoutController.canUseBoard)
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
            _boardController.undo();
          },
        if (_layoutController.canUseBoard)
          const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
            _boardController.redo();
          },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: LuxuryScaffold(
            safeArea: false,
            child: Obx(() {
              final room = _controller.room.value;
              final loading = _controller.isLoadingRoom.value;
              final mediaConnecting = _controller.isConnectingMedia.value;
              final mediaError = _controller.mediaError.value;
              final mediaRoom = _controller.rtcRoom.value;

              if (loading || room == null || room.session.id != _sessionId) {
                return const Center(child: CircularProgressIndicator());
              }

              _syncWorkspace(room);

              final participant = _currentParticipant(room);
              final lecturer = _lecturerParticipant(room);
              final participants = _sortedParticipants(room);
              final presenter = _selectedPresenter(room, participants);
              final sessionState = _sessionStateFor(
                room: room,
                mediaConnecting: mediaConnecting,
              );
              final recordingOn =
                  participant?.recordingEnabled ??
                  room.recordings.any((recording) => recording.isActive);
              final cameraOn = participant?.cameraEnabled ?? false;
              final micOn = participant?.micEnabled ?? false;
              final isCompact = MediaQuery.sizeOf(context).width < 1180;

              return _buildWorkspace(
                context,
                room: room,
                mediaRoom: mediaRoom,
                participant: participant,
                lecturer: lecturer,
                presenter: presenter,
                participants: participants,
                sessionState: sessionState,
                recordingOn: recordingOn,
                cameraOn: cameraOn,
                micOn: micOn,
                mediaError: mediaError,
                mediaConnecting: mediaConnecting,
                isCompact: isCompact,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace(
    BuildContext context, {
    required LiveSessionRoomState room,
    required lk.Room? mediaRoom,
    required LiveSessionParticipant? participant,
    required LiveSessionParticipant? lecturer,
    required LiveSessionParticipant? presenter,
    required List<LiveSessionParticipant> participants,
    required LiveClassSessionUiState sessionState,
    required bool recordingOn,
    required bool cameraOn,
    required bool micOn,
    required String? mediaError,
    required bool mediaConnecting,
    required bool isCompact,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_layoutController, _boardController]),
      builder: (context, _) {
        final warnings = _buildWarnings(
          context,
          room: room,
          mediaError: mediaError,
          mediaConnecting: mediaConnecting,
        );

        if (isCompact) {
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _buildHeader(
                  context,
                  room: room,
                  participant: participant,
                  sessionState: sessionState,
                  recordingOn: recordingOn,
                  mediaError: mediaError,
                ),
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final warning in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: warning,
                    ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: _buildStage(
                    context,
                    room: room,
                    mediaRoom: mediaRoom,
                    lecturer: lecturer,
                    presenter: presenter,
                    participants: participants,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: _layoutController.isInteractionPanelOpen ? 360 : 72,
                  child: _LiveClassInteractionPanel(
                    room: room,
                    participants: participants,
                    layoutController: _layoutController,
                    boardController: _boardController,
                    chatController: _chatCtrl,
                    questionController: _questionCtrl,
                    aiController: _aiCtrl,
                    currentParticipantId: participant?.id ?? _userId,
                    currentParticipantName: _displayName,
                    onSendChat: _sendChat,
                    onSubmitQuestion: _submitQuestion,
                    onAnswerQuestion: _answerQuestion,
                    onLaunchAssessment: _isLecturer
                        ? (type) =>
                              _layoutController.launchAssessment(type: type)
                        : null,
                    onSaveBoard: () => _showActionNotice(
                      'Board export is ready for the Go backend integration path.',
                    ),
                    onShowResults: () => _showAssessmentResults(context),
                    compact: true,
                    isLecturer: _isLecturer,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomToolbar(
                  context,
                  room: room,
                  participant: participant,
                  micOn: micOn,
                  cameraOn: cameraOn,
                  recordingOn: recordingOn,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildHeader(
                  context,
                  room: room,
                  participant: participant,
                  sessionState: sessionState,
                  recordingOn: recordingOn,
                  mediaError: mediaError,
                ),
              ),
            ),
            if (warnings.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: warnings
                      .map(
                        (warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: warning,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: isCompact
                    ? Column(
                        children: [
                          Expanded(
                            child: _buildStage(
                              context,
                              room: room,
                              mediaRoom: mediaRoom,
                              lecturer: lecturer,
                              presenter: presenter,
                              participants: participants,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: _layoutController.isInteractionPanelOpen
                                ? 360
                                : 72,
                            child: _LiveClassInteractionPanel(
                              room: room,
                              participants: participants,
                              layoutController: _layoutController,
                              boardController: _boardController,
                              chatController: _chatCtrl,
                              questionController: _questionCtrl,
                              aiController: _aiCtrl,
                              currentParticipantId: participant?.id ?? _userId,
                              currentParticipantName: _displayName,
                              onSendChat: _sendChat,
                              onSubmitQuestion: _submitQuestion,
                              onAnswerQuestion: _answerQuestion,
                              onLaunchAssessment: _isLecturer
                                  ? (type) => _layoutController
                                        .launchAssessment(type: type)
                                  : null,
                              onSaveBoard: () => _showActionNotice(
                                'Board export is ready for the Go backend integration path.',
                              ),
                              onShowResults: () =>
                                  _showAssessmentResults(context),
                              compact: true,
                              isLecturer: _isLecturer,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 10,
                            child: _buildStage(
                              context,
                              room: room,
                              mediaRoom: mediaRoom,
                              lecturer: lecturer,
                              presenter: presenter,
                              participants: participants,
                            ),
                          ),
                          if (!_layoutController.isFullscreen) ...[
                            const SizedBox(width: 12),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: _layoutController.isInteractionPanelOpen
                                  ? 340
                                  : 72,
                              child: _LiveClassInteractionPanel(
                                room: room,
                                participants: participants,
                                layoutController: _layoutController,
                                boardController: _boardController,
                                chatController: _chatCtrl,
                                questionController: _questionCtrl,
                                aiController: _aiCtrl,
                                currentParticipantId:
                                    participant?.id ?? _userId,
                                currentParticipantName: _displayName,
                                onSendChat: _sendChat,
                                onSubmitQuestion: _submitQuestion,
                                onAnswerQuestion: _answerQuestion,
                                onLaunchAssessment: _isLecturer
                                    ? (type) => _layoutController
                                          .launchAssessment(type: type)
                                    : null,
                                onSaveBoard: () => _showActionNotice(
                                  'Board export is ready for the Go backend integration path.',
                                ),
                                onShowResults: () =>
                                    _showAssessmentResults(context),
                                compact: false,
                                isLecturer: _isLecturer,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            if (!_layoutController.isFullscreen)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildBottomToolbar(
                    context,
                    room: room,
                    participant: participant,
                    micOn: micOn,
                    cameraOn: cameraOn,
                    recordingOn: recordingOn,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required LiveSessionRoomState room,
    required LiveSessionParticipant? participant,
    required LiveClassSessionUiState sessionState,
    required bool recordingOn,
    required String? mediaError,
  }) {
    final cs = Theme.of(context).colorScheme;
    final network = _networkMeta(mediaError: mediaError);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 720;
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isNarrow
                            ? constraints.maxWidth
                            : (constraints.maxWidth * 0.42).clamp(220, 460),
                      ),
                      child: Text(
                        room.session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    _StageBadge(
                      label: room.session.courseCode,
                      icon: Icons.school_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${room.session.courseTitle} · ${room.session.lecturerName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            );
            final statusActions = Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: isNarrow ? WrapAlignment.start : WrapAlignment.end,
              children: [
                _MetricPill(
                  icon: Icons.broadcast_on_personal_rounded,
                  label: sessionState.label,
                  color: _sessionStateColor(sessionState),
                ),
                _MetricPill(
                  icon: Icons.timer_rounded,
                  label: _sessionTimerLabel(room.session),
                ),
                _MetricPill(
                  icon: network.icon,
                  label: network.label,
                  color: network.color,
                ),
                _MetricPill(
                  icon: recordingOn
                      ? Icons.fiber_manual_record_rounded
                      : Icons.stop_circle_outlined,
                  label: recordingOn ? 'Recording' : 'Not recording',
                  color: recordingOn ? Colors.redAccent : null,
                ),
                _MetricPill(
                  icon:
                      _controller.currentRuntimeMode ==
                          LiveSessionRuntimeMode.demo
                      ? Icons.slideshow_rounded
                      : Icons.cloud_sync_rounded,
                  label: _controller.currentRuntimeMode.label,
                  color:
                      _controller.currentRuntimeMode ==
                          LiveSessionRuntimeMode.demo
                      ? Colors.lightBlueAccent
                      : Colors.tealAccent,
                ),
                if (_controller.isDemoMode)
                  _MetricPill(
                    icon: Icons.slideshow_rounded,
                    label: 'Demo ready',
                    color: Colors.lightBlueAccent,
                  ),
                _MetricPill(
                  icon: Icons.cloud_done_rounded,
                  label: _controller.backendProviderLabel,
                  color: Colors.tealAccent,
                ),
                _MetricPill(
                  icon: Icons.router_rounded,
                  label: _controller.mediaProviderLabel,
                  color: Colors.amberAccent,
                ),
                IconButton.filledTonal(
                  tooltip: 'Class settings',
                  onPressed: _showSettingsSheet,
                  icon: const Icon(Icons.settings_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: 'Demo stack',
                  onPressed: _showDemoStackSheet,
                  icon: const Icon(Icons.dns_rounded),
                ),
                IconButton.filled(
                  tooltip: 'Leave class',
                  onPressed: _leaveClassroom,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.exit_to_app_rounded),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 14),
                  statusActions,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: statusActions),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildWarnings(
    BuildContext context, {
    required LiveSessionRoomState room,
    required String? mediaError,
    required bool mediaConnecting,
  }) {
    final warnings = <Widget>[];
    if (_controller.isDemoMode) {
      warnings.add(
        _WarningBanner(
          icon: Icons.smart_display_rounded,
          tone: Colors.lightBlueAccent,
          title: 'School demo mode',
          message:
              '${_controller.demoModeNotice} Backend: ${_controller.backendProviderLabel}. Media target: ${_controller.mediaProviderLabel}.',
          actionLabel: 'View demo stack',
          onAction: _showDemoStackSheet,
        ),
      );
    }
    if (mediaError != null && mediaError.isNotEmpty) {
      warnings.add(
        _WarningBanner(
          icon: Icons.wifi_off_rounded,
          tone: Colors.orange,
          title: 'Network or media issue',
          message: mediaError,
          actionLabel: 'Use stage fallback',
          onAction: () => _layoutController.setContentSource(
            LiveClassContentSource.whiteboard,
          ),
        ),
      );
    } else if (mediaConnecting) {
      warnings.add(
        _WarningBanner(
          icon: Icons.sync_problem_rounded,
          tone: Colors.amber,
          title: 'Session reconnecting',
          message:
              'The classroom is stabilizing the live stream. Annotation and chat remain available.',
          actionLabel: 'Stay on board',
          onAction: () => _layoutController.setContentSource(
            LiveClassContentSource.whiteboard,
          ),
        ),
      );
    }

    if (!_isLecturer &&
        _layoutController.boardAccessRequested &&
        !_layoutController.studentBoardAccessGranted) {
      warnings.add(
        _WarningBanner(
          icon: Icons.draw_rounded,
          tone: Colors.blueAccent,
          title: 'Board access requested',
          message:
              'Your request is waiting for lecturer approval. Chat and quiz tools remain available.',
          actionLabel: 'View participants',
          onAction: () =>
              _layoutController.setActivePanel(LiveClassPanelTab.participants),
        ),
      );
    }

    if (!room.session.isLiveAt(DateTime.now()) &&
        !room.session.isCompletedAt(DateTime.now())) {
      warnings.add(
        _WarningBanner(
          icon: Icons.schedule_rounded,
          tone: Colors.teal,
          title: 'Session preparing',
          message:
              'The room is ready before the lecturer starts. You can still review materials and prepare notes.',
          actionLabel: 'Open resources',
          onAction: () =>
              _layoutController.setActivePanel(LiveClassPanelTab.resources),
        ),
      );
    }

    return warnings;
  }

  Widget _buildStage(
    BuildContext context, {
    required LiveSessionRoomState room,
    required lk.Room? mediaRoom,
    required LiveSessionParticipant? lecturer,
    required LiveSessionParticipant? presenter,
    required List<LiveSessionParticipant> participants,
  }) {
    final cs = Theme.of(context).colorScheme;
    final currentMaterial = room.session.materials.isEmpty
        ? null
        : room.session.materials[(_boardController.currentPage - 1)
              .clamp(0, room.session.materials.length - 1)
              .toInt()];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactStage =
              constraints.maxWidth < 520 || constraints.maxHeight < 430;
          return Padding(
            padding: EdgeInsets.all(compactStage ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStageToolbar(context, compact: compactStage),
                SizedBox(height: compactStage ? 8 : 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _StageBackground(
                            layoutController: _layoutController,
                            boardController: _boardController,
                            currentMaterial: currentMaterial,
                            room: room,
                            mediaRoom: mediaRoom,
                            lecturer: lecturer,
                            presenter: presenter,
                            participantResolver:
                                _controller.mediaParticipantFor,
                          ),
                        ),
                        Positioned.fill(
                          child: LiveClassBoardCanvas(
                            controller: _boardController,
                            isInteractive: _layoutController.canUseBoard,
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StageBadge(
                                label: _boardController.currentTool.label,
                                icon: _boardController.currentTool.icon,
                                color: Colors.lightBlueAccent,
                              ),
                              if (!compactStage)
                                _StageBadge(
                                  label:
                                      'Page ${_boardController.currentPage}/${_boardController.pageCount} · ${_boardController.currentAnnotationCount} annotations',
                                  icon: Icons.note_alt_rounded,
                                  color: Colors.tealAccent,
                                ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _PageControls(
                            boardController: _boardController,
                            onSave: () => _showActionNotice(
                              'Annotation snapshot ready for export and lecture notes.',
                            ),
                          ),
                        ),
                        if (_layoutController.isAssessmentVisible &&
                            _layoutController.activeAssessment != null)
                          Positioned.fill(
                            child: _AssessmentOverlay(
                              assessment: _layoutController.activeAssessment!,
                              isLecturer: _isLecturer,
                              participantId: presenter?.id ?? _userId,
                              onClose: _layoutController.closeAssessment,
                              onSubmit: (response) {
                                _layoutController.submitAssessmentResponse(
                                  participantId: presenter?.id ?? _userId,
                                  response: response,
                                );
                              },
                              onShowResults: () =>
                                  _showAssessmentResults(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!compactStage) ...[
                  const SizedBox(height: 12),
                  _buildStageFooter(context, room, participants),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStageToolbar(BuildContext context, {bool compact = false}) {
    final visibleModes = compact
        ? const [
            LiveClassMode.video,
            LiveClassMode.presentation,
            LiveClassMode.hybrid,
          ]
        : LiveClassMode.values;
    final foldedModes = LiveClassMode.values
        .where((mode) => !visibleModes.contains(mode))
        .toList(growable: false);
    final modeChips = visibleModes
        .map(
          (mode) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(mode.label),
              avatar: Icon(mode.icon, size: 18),
              selected: _layoutController.currentMode == mode,
              onSelected: (_) => _layoutController.setMode(mode),
            ),
          ),
        )
        .toList(growable: false);
    final visibleTools = compact
        ? const [
            LiveClassBoardTool.pen,
            LiveClassBoardTool.highlighter,
            LiveClassBoardTool.eraser,
          ]
        : LiveClassBoardTool.values;
    final foldedTools = LiveClassBoardTool.values
        .where((tool) => !visibleTools.contains(tool))
        .toList(growable: false);
    final toolChips = <Widget>[
      for (final tool in visibleTools)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(tool.label),
            avatar: Icon(tool.icon, size: 18),
            selected: _boardController.currentTool == tool,
            onSelected: _layoutController.canUseBoard
                ? (_) => _boardController.setTool(tool)
                : null,
          ),
        ),
      if (foldedTools.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: PopupMenuButton<LiveClassBoardTool>(
            tooltip: 'More board tools',
            onSelected: _layoutController.canUseBoard
                ? _boardController.setTool
                : null,
            itemBuilder: (context) => [
              for (final tool in foldedTools)
                PopupMenuItem(
                  value: tool,
                  child: ListTile(
                    leading: Icon(tool.icon),
                    title: Text(tool.label),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
            child: _ToolbarMenuPill(
              icon: Icons.more_horiz_rounded,
              label: 'Tools',
              selected: foldedTools.contains(_boardController.currentTool),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _MiniToolbarButton(
          icon: Icons.undo_rounded,
          tooltip: 'Undo',
          onPressed: _boardController.canUndo ? _boardController.undo : null,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _MiniToolbarButton(
          icon: Icons.redo_rounded,
          tooltip: 'Redo',
          onPressed: _boardController.canRedo ? _boardController.redo : null,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _MiniToolbarButton(
          icon: Icons.layers_clear_rounded,
          tooltip: 'Clear page',
          onPressed: _layoutController.canUseBoard
              ? _boardController.clearCurrentPage
              : null,
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _MiniToolbarButton(
          icon: Icons.bookmark_added_rounded,
          tooltip: 'Save board',
          onPressed: () => _showActionNotice(
            'Board state saved for export, notes, and Go backend sync.',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _MiniToolbarButton(
          icon: Icons.camera_alt_rounded,
          tooltip: 'Save screenshot',
          onPressed: () => _showActionNotice(
            'Screenshot action is visible and ready for Go media capture.',
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _MiniToolbarButton(
          icon: Icons.article_rounded,
          tooltip: 'Generate lecture note',
          onPressed: () => _showActionNotice(
            'Lecture note generation entry point is ready for AI integration.',
          ),
        ),
      ),
      _MiniToolbarButton(
        icon: Icons.push_pin_rounded,
        tooltip: 'Pin explanation',
        onPressed: () => _showActionNotice(
          'Important explanation pinned to the class timeline.',
        ),
      ),
    ];

    if (compact) {
      return SizedBox(
        height: 92,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...modeChips,
                    if (foldedModes.isNotEmpty)
                      PopupMenuButton<LiveClassMode>(
                        tooltip: 'More modes',
                        onSelected: _layoutController.setMode,
                        itemBuilder: (context) => [
                          for (final mode in foldedModes)
                            PopupMenuItem(
                              value: mode,
                              child: ListTile(
                                leading: Icon(mode.icon),
                                title: Text(mode.label),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                        child: _ToolbarMenuPill(
                          icon: Icons.more_horiz_rounded,
                          label: 'Modes',
                          selected: foldedModes.contains(
                            _layoutController.currentMode,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: toolChips),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 10,
      spacing: 10,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: modeChips),
        Wrap(spacing: 8, runSpacing: 8, children: toolChips),
      ],
    );
  }

  Widget _buildStageFooter(
    BuildContext context,
    LiveSessionRoomState room,
    List<LiveSessionParticipant> participants,
  ) {
    final cs = Theme.of(context).colorScheme;
    final reactions = _layoutController.reactions.entries.take(3).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StageBadge(
                    label: '${participants.length} participants',
                    icon: Icons.groups_rounded,
                  ),
                  _StageBadge(
                    label: '${_layoutController.raisedHands.length} hands up',
                    icon: Icons.front_hand_rounded,
                    color: Colors.orangeAccent,
                  ),
                  _StageBadge(
                    label: '${room.questions.length} questions',
                    icon: Icons.question_answer_rounded,
                    color: Colors.lightGreenAccent,
                  ),
                  _StageBadge(
                    label:
                        '${room.recordings.where((recording) => recording.isActive).length} active recordings',
                    icon: Icons.fiber_manual_record_rounded,
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ),
            if (reactions.isNotEmpty)
              Wrap(
                spacing: 8,
                children: reactions
                    .map(
                      (entry) => _StageBadge(
                        label: entry.value,
                        icon: Icons.favorite_rounded,
                        color: Colors.pinkAccent,
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomToolbar(
    BuildContext context, {
    required LiveSessionRoomState room,
    required LiveSessionParticipant? participant,
    required bool micOn,
    required bool cameraOn,
    required bool recordingOn,
  }) {
    final actions = <Widget>[
      _ControlButton(
        icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
        label: micOn ? 'Mute' : 'Unmute',
        selected: micOn,
        onTap: () => _toggleMic(!micOn),
      ),
      _ControlButton(
        icon: cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
        label: cameraOn ? 'Camera on' : 'Camera off',
        selected: cameraOn,
        onTap: () => _toggleCamera(!cameraOn),
      ),
    ];
    final foldedActions = <_FoldedControlAction>[];

    if (_isLecturer) {
      actions.addAll([
        _ControlButton(
          icon: Icons.screen_share_rounded,
          label: 'Share',
          selected: _layoutController.isScreenSharingActive,
          onTap: _layoutController.toggleScreenShare,
        ),
        _ControlButton(
          icon: Icons.dashboard_outlined,
          label: 'Board',
          selected:
              _layoutController.selectedContentSource ==
              LiveClassContentSource.whiteboard,
          onTap: () => _layoutController.setContentSource(
            LiveClassContentSource.whiteboard,
          ),
        ),
      ]);
      foldedActions.addAll([
        _FoldedControlAction(
          icon: Icons.quiz_rounded,
          label: 'Quiz',
          selected: _layoutController.isAssessmentVisible,
          onTap: () => _layoutController.launchAssessment(
            type: LiveClassAssessmentType.quiz,
          ),
        ),
        _FoldedControlAction(
          icon: Icons.poll_rounded,
          label: 'Poll',
          onTap: () => _layoutController.launchAssessment(
            type: LiveClassAssessmentType.poll,
          ),
        ),
        _FoldedControlAction(
          icon: recordingOn
              ? Icons.stop_circle_rounded
              : Icons.fiber_manual_record_rounded,
          label: recordingOn ? 'Stop rec' : 'Record',
          selected: recordingOn,
          onTap: () => _toggleRecording(!recordingOn),
        ),
      ]);
    } else {
      final participantId = participant?.id ?? _userId;
      final isRaised = _layoutController.raisedHands.contains(participantId);
      actions.addAll([
        _ControlButton(
          icon: Icons.front_hand_rounded,
          label: isRaised ? 'Lower hand' : 'Raise hand',
          selected: isRaised,
          onTap: () {
            final nextValue = !isRaised;
            _layoutController.setRaisedHand(participantId, nextValue);
            _handleRealtimeEvent(
              LiveClassRealtimeEvent(
                type: LiveClassRealtimeEventType.handRaised,
                payload: {'participantId': participantId, 'raised': nextValue},
              ),
            );
          },
        ),
        _ControlButton(
          icon: Icons.question_answer_rounded,
          label: 'Ask',
          onTap: _showQuestionDialog,
        ),
      ]);
      foldedActions.addAll([
        _FoldedControlAction(
          icon: Icons.draw_rounded,
          label: _layoutController.studentBoardAccessGranted
              ? 'Board ready'
              : 'Request board',
          selected: _layoutController.studentBoardAccessGranted,
          onTap: _layoutController.studentBoardAccessGranted
              ? () => _layoutController.setContentSource(
                  LiveClassContentSource.whiteboard,
                )
              : _layoutController.requestBoardAccess,
        ),
        _FoldedControlAction(
          icon: Icons.emoji_emotions_rounded,
          label: 'React',
          onTap: () => _showReactionPicker(participantId),
        ),
        _FoldedControlAction(
          icon: Icons.quiz_rounded,
          label: 'Answer',
          selected: _layoutController.isAssessmentVisible,
          onTap: () => _layoutController.setActivePanel(LiveClassPanelTab.quiz),
        ),
      ]);
    }

    actions.addAll([
      _ControlButton(
        icon: Icons.chat_rounded,
        label: 'Chat',
        selected: _layoutController.activePanel == LiveClassPanelTab.chat,
        onTap: () => _layoutController.setActivePanel(LiveClassPanelTab.chat),
      ),
    ]);
    foldedActions.add(
      _FoldedControlAction(
        icon: Icons.groups_rounded,
        label: 'People',
        selected:
            _layoutController.activePanel == LiveClassPanelTab.participants,
        onTap: () =>
            _layoutController.setActivePanel(LiveClassPanelTab.participants),
      ),
    );
    if (foldedActions.isNotEmpty) {
      actions.add(_MoreControlsButton(actions: foldedActions));
    }
    actions.addAll([
      _ControlButton(
        icon: _layoutController.isFullscreen
            ? Icons.fullscreen_exit_rounded
            : Icons.fullscreen_rounded,
        label: 'Fullscreen',
        selected: _layoutController.isFullscreen,
        onTap: _toggleFullscreen,
      ),
      _ControlButton(
        icon: _isLecturer
            ? (_layoutController.isSessionPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded)
            : Icons.logout_rounded,
        label: _isLecturer
            ? (_layoutController.isSessionPaused ? 'Resume' : 'Pause')
            : 'Leave',
        onTap: _isLecturer
            ? _layoutController.toggleSessionPaused
            : _leaveClassroom,
      ),
      _ControlButton(
        icon: _isLecturer ? Icons.stop_rounded : Icons.exit_to_app_rounded,
        label: _isLecturer ? 'End class' : 'Exit',
        danger: true,
        onTap: _leaveClassroom,
      ),
    ]);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: actions
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: action,
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _showQuestionDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ask question'),
          content: TextField(
            controller: _questionCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Type your question for the lecturer',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                await _submitQuestion();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showReactionPicker(String participantId) async {
    final reaction = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final reactions = ['Understood', 'Need help', 'Great pace'];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: reactions
                .map(
                  (item) => ListTile(
                    title: Text(item),
                    onTap: () => Navigator.of(context).pop(item),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );
    if (reaction == null || reaction.isEmpty) return;
    _layoutController.addReaction(participantId, reaction);
  }

  void _showAssessmentResults(BuildContext context) {
    final assessment = _layoutController.activeAssessment;
    if (assessment == null) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        final tally = assessment.tally().entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return AlertDialog(
          title: Text('${assessment.title} results'),
          content: SizedBox(
            width: 380,
            child: assessment.type == LiveClassAssessmentType.shortAnswer
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: assessment.responses.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text('• ${entry.value}'),
                          ),
                        )
                        .toList(growable: false),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: tally
                        .map(
                          (entry) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.bar_chart_rounded),
                            title: Text(entry.key),
                            trailing: Text('${entry.value}'),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Classroom settings',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final selectedMode = _controller.currentRuntimeMode;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Environment',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<LiveSessionRuntimeMode>(
                        segments: const [
                          ButtonSegment<LiveSessionRuntimeMode>(
                            value: LiveSessionRuntimeMode.demo,
                            label: Text('Demo'),
                            icon: Icon(Icons.slideshow_rounded),
                          ),
                          ButtonSegment<LiveSessionRuntimeMode>(
                            value: LiveSessionRuntimeMode.production,
                            label: Text('Production'),
                            icon: Icon(Icons.cloud_sync_rounded),
                          ),
                        ],
                        selected: {selectedMode},
                        onSelectionChanged: (selection) {
                          final nextMode = selection.first;
                          unawaited(_handleRuntimeModeChange(nextMode));
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        selectedMode == LiveSessionRuntimeMode.demo
                            ? 'Use seeded demo data and presentation-safe media fallback.'
                            : 'Target the Go live-class backend and Go media gateway.',
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_done_rounded),
                  title: Text(_controller.backendProviderLabel),
                  subtitle: const Text(
                    'Preferred production target for room state, attendance, quiz, chat, and annotation events.',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.router_rounded),
                  title: Text(_controller.mediaProviderLabel),
                  subtitle: Text(
                    _controller.mediaConfigurationNotice ??
                        'Live classroom video is configured for the Go media gateway.',
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LiveClassBoardBackground.values
                      .map(
                        (background) => ChoiceChip(
                          label: Text(background.label),
                          selected: _boardController.background == background,
                          onSelected: (_) =>
                              _boardController.setBackground(background),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Interaction panel open'),
                  value: _layoutController.isInteractionPanelOpen,
                  onChanged: (value) =>
                      _layoutController.toggleInteractionPanel(value),
                ),
                SwitchListTile(
                  title: const Text('Pin AI assistant area'),
                  value: _layoutController.isAIAssistantPinned,
                  onChanged: (_) => _layoutController.toggleAIAssistantPinned(),
                ),
                if (_controller.isDemoMode)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.slideshow_rounded),
                    title: const Text('Demo mode active'),
                    subtitle: Text(
                      _controller.demoModeNotice ??
                          'The workspace is presentation-ready with seeded demo data.',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDemoStackSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo stack',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  _controller.demoModeNotice ??
                      'Production mode is configured for the Go live-class stack.',
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final selectedMode = _controller.currentRuntimeMode;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Runtime mode',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<LiveSessionRuntimeMode>(
                        segments: const [
                          ButtonSegment<LiveSessionRuntimeMode>(
                            value: LiveSessionRuntimeMode.demo,
                            label: Text('Demo'),
                            icon: Icon(Icons.slideshow_rounded),
                          ),
                          ButtonSegment<LiveSessionRuntimeMode>(
                            value: LiveSessionRuntimeMode.production,
                            label: Text('Production'),
                            icon: Icon(Icons.cloud_sync_rounded),
                          ),
                        ],
                        selected: {selectedMode},
                        onSelectionChanged: (selection) {
                          final nextMode = selection.first;
                          unawaited(_handleRuntimeModeChange(nextMode));
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_done_rounded),
                  title: Text(_controller.backendProviderLabel),
                  subtitle: const Text(
                    'Room state, attendance, chat, Q&A, polls, and annotation event endpoints.',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.router_rounded),
                  title: Text(_controller.mediaProviderLabel),
                  subtitle: Text(
                    _controller.mediaConfigurationNotice ??
                        'Live classroom video is configured for the Go media gateway.',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'API contract',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _controller.backendContract.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _controller.backendContract[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item.method} ${item.path}'),
                        subtitle: Text(item.description),
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

  Color _sessionStateColor(LiveClassSessionUiState state) {
    switch (state) {
      case LiveClassSessionUiState.initializing:
        return Colors.amber;
      case LiveClassSessionUiState.live:
        return Colors.greenAccent;
      case LiveClassSessionUiState.paused:
        return Colors.orangeAccent;
      case LiveClassSessionUiState.reconnecting:
        return Colors.deepOrangeAccent;
      case LiveClassSessionUiState.ended:
        return Colors.redAccent;
    }
  }

  _NetworkMeta _networkMeta({required String? mediaError}) {
    if (mediaError != null && mediaError.isNotEmpty) {
      return const _NetworkMeta(
        label: 'Delayed',
        icon: Icons.wifi_off_rounded,
        color: Colors.orangeAccent,
      );
    }
    if (_controller.isConnectingMedia.value) {
      return const _NetworkMeta(
        label: 'Syncing',
        icon: Icons.sync_rounded,
        color: Colors.amber,
      );
    }
    if (_controller.rtcRoom.value != null) {
      return const _NetworkMeta(
        label: 'Strong',
        icon: Icons.network_wifi_rounded,
        color: Colors.greenAccent,
      );
    }
    if (_controller.isDemoMode) {
      return const _NetworkMeta(
        label: 'Demo',
        icon: Icons.slideshow_rounded,
        color: Colors.lightBlueAccent,
      );
    }
    return const _NetworkMeta(
      label: 'Fallback',
      icon: Icons.network_check_rounded,
      color: Colors.lightBlueAccent,
    );
  }

  String _sessionTimerLabel(LiveSessionModel session) {
    final now = DateTime.now();
    if (session.isLiveAt(now)) {
      final elapsed = now.difference(session.startTime).inMinutes;
      return '${liveSessionMinutesLabel(elapsed)} elapsed';
    }
    if (session.isUpcomingAt(now)) {
      final startIn = session.startTime.difference(now).inMinutes;
      return 'Starts in ${liveSessionMinutesLabel(startIn)}';
    }
    return 'Ended ${liveSessionShortDate(session.endTime)}';
  }
}

class _StageBackground extends StatelessWidget {
  const _StageBackground({
    required this.layoutController,
    required this.boardController,
    required this.currentMaterial,
    required this.room,
    required this.mediaRoom,
    required this.lecturer,
    required this.presenter,
    required this.participantResolver,
  });

  final LiveClassLayoutController layoutController;
  final LiveClassBoardController boardController;
  final LiveSessionMaterial? currentMaterial;
  final LiveSessionRoomState room;
  final lk.Room? mediaRoom;
  final LiveSessionParticipant? lecturer;
  final LiveSessionParticipant? presenter;
  final lk.Participant? Function(String participantId) participantResolver;

  @override
  Widget build(BuildContext context) {
    switch (layoutController.selectedContentSource) {
      case LiveClassContentSource.lecturerCamera:
        return _buildVideoSurface(context, lecturer ?? presenter);
      case LiveClassContentSource.slides:
        return _buildPresentationSurface(context, overlayVideo: false);
      case LiveClassContentSource.screenShare:
        return _buildScreenShareSurface(context);
      case LiveClassContentSource.whiteboard:
        return _buildWhiteboardSurface(context);
      case LiveClassContentSource.mixed:
        return _buildHybridSurface(context);
    }
  }

  Widget _buildVideoSurface(
    BuildContext context,
    LiveSessionParticipant? participant,
  ) {
    final active = participant;
    if (active == null) {
      return _FallbackSurface(
        title: 'Camera stage',
        subtitle: 'Lecturer video will appear here when the stream is active.',
        icon: Icons.ondemand_video_rounded,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LiveSessionVideoSurface(
          participant: active,
          mediaParticipant: participantResolver(active.id),
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _buildWhiteboardSurface(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _boardGradient()),
      child: CustomPaint(
        painter: _BoardBackdropPainter(background: boardController.background),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sticky_note_2_rounded, size: 52),
              const SizedBox(height: 12),
              Text(
                boardController.background.label,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manual writing and live annotation render on this stage.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresentationSurface(
    BuildContext context, {
    required bool overlayVideo,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: _boardGradient()),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const _StageBadge(
                            label: 'Slides / PDF',
                            icon: Icons.library_books_rounded,
                            color: Colors.blueAccent,
                          ),
                          _StageBadge(
                            label:
                                'Page ${boardController.currentPage}/${boardController.pageCount}',
                            icon: Icons.bookmark_border_rounded,
                            color: Colors.indigoAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        currentMaterial?.title ?? room.session.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentMaterial?.subtitle ?? room.session.description,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.black54),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: room.session.materials
                            .take(3)
                            .map(
                              (material) => Container(
                                width: 220,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.blueGrey.shade100,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      material.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      material.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      material.status,
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (overlayVideo && lecturer != null)
            Positioned(
              right: 18,
              top: 18,
              width: 220,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LiveSessionVideoSurface(
                  participant: lecturer!,
                  mediaParticipant: participantResolver(lecturer!.id),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreenShareSurface(BuildContext context) {
    final screenParticipant = presenter ?? lecturer;
    final mediaParticipant = screenParticipant == null
        ? null
        : participantResolver(screenParticipant.id);
    final track = liveSessionScreenShareTrackFor(mediaParticipant);

    if (track == null) {
      return _FallbackSurface(
        title: 'Shared screen',
        subtitle:
            'Screen share is ready. When the presenter starts sharing, it will appear here with annotations on top.',
        icon: Icons.screen_share_rounded,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.contain),
          Positioned(
            left: 18,
            top: 18,
            child: _StageBadge(
              label:
                  'Presenter: ${screenParticipant?.displayName ?? 'Live share'}',
              icon: Icons.present_to_all_rounded,
              color: Colors.lightBlueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHybridSurface(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildPresentationSurface(context, overlayVideo: false),
        ),
        Container(width: 1, color: Colors.white.withValues(alpha: 0.08)),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Expanded(child: _buildVideoSurface(context, lecturer)),
                const SizedBox(height: 14),
                Expanded(child: _buildScreenShareSurface(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Gradient _boardGradient() {
    switch (boardController.background) {
      case LiveClassBoardBackground.blank:
        return const LinearGradient(
          colors: [Color(0xFFF6F7FB), Color(0xFFE3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LiveClassBoardBackground.dark:
        return const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LiveClassBoardBackground.grid:
        return const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFDDEAF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LiveClassBoardBackground.presentationOverlay:
        return const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color tone;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: tone),
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onAction,
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Icon(icon, color: tone),
                const SizedBox(width: 12),
                Expanded(child: copy),
                const SizedBox(width: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: activeColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: activeColor),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: activeColor)),
          ],
        ),
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label, required this.icon, this.color});

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: chipColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: chipColor)),
          ],
        ),
      ),
    );
  }
}

class _MiniToolbarButton extends StatelessWidget {
  const _MiniToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
    );
  }
}

class _ToolbarMenuPill extends StatelessWidget {
  const _ToolbarMenuPill({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? cs.primary.withValues(alpha: 0.22)
            : cs.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: selected ? cs.primary : cs.onSurface),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final background = danger
        ? Colors.redAccent
        : selected
        ? cs.primary
        : cs.surfaceContainerHighest.withValues(alpha: 0.62);
    final foreground = danger || selected ? Colors.white : cs.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FoldedControlAction {
  const _FoldedControlAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
}

class _MoreControlsButton extends StatelessWidget {
  const _MoreControlsButton({required this.actions});

  final List<_FoldedControlAction> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<int>(
      tooltip: 'More controls',
      onSelected: (index) => actions[index].onTap(),
      itemBuilder: (context) => [
        for (var index = 0; index < actions.length; index++)
          PopupMenuItem(
            value: index,
            child: Row(
              children: [
                Icon(
                  actions[index].icon,
                  color: actions[index].selected ? cs.primary : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(actions[index].label)),
                if (actions[index].selected)
                  Icon(Icons.check_rounded, color: cs.primary),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz_rounded, color: cs.onSurface),
            const SizedBox(height: 6),
            Text(
              'More',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageControls extends StatelessWidget {
  const _PageControls({required this.boardController, required this.onSave});

  final LiveClassBoardController boardController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: boardController.currentPage > 1
                  ? boardController.previousPage
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
            ),
            Text(
              'Page ${boardController.currentPage}',
              style: const TextStyle(color: Colors.white),
            ),
            IconButton(
              onPressed: boardController.currentPage < boardController.pageCount
                  ? boardController.nextPage
                  : null,
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => boardController.adjustZoom(0.15),
              icon: const Icon(Icons.zoom_in_rounded, color: Colors.white),
            ),
            IconButton(
              onPressed: () => boardController.adjustZoom(-0.15),
              icon: const Icon(Icons.zoom_out_rounded, color: Colors.white),
            ),
            IconButton(
              onPressed: boardController.resetViewport,
              icon: const Icon(
                Icons.center_focus_strong_rounded,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: onSave,
              icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackSurface extends StatelessWidget {
  const _FallbackSurface({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF111827)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: Colors.white70),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardBackdropPainter extends CustomPainter {
  const _BoardBackdropPainter({required this.background});

  final LiveClassBoardBackground background;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = background == LiveClassBoardBackground.dark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    if (background == LiveClassBoardBackground.grid) {
      for (double x = 0; x < size.width; x += 36) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
      }
      for (double y = 0; y < size.height; y += 36) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
    }

    if (background == LiveClassBoardBackground.presentationOverlay) {
      final guidePaint = Paint()
        ..color = Colors.indigo.withValues(alpha: 0.10)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.08,
            size.height * 0.10,
            size.width * 0.84,
            size.height * 0.80,
          ),
          const Radius.circular(28),
        ),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BoardBackdropPainter oldDelegate) {
    return oldDelegate.background != background;
  }
}

class _AssessmentOverlay extends StatefulWidget {
  const _AssessmentOverlay({
    required this.assessment,
    required this.isLecturer,
    required this.participantId,
    required this.onClose,
    required this.onSubmit,
    required this.onShowResults,
  });

  final LiveClassAssessmentState assessment;
  final bool isLecturer;
  final String participantId;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmit;
  final VoidCallback onShowResults;

  @override
  State<_AssessmentOverlay> createState() => _AssessmentOverlayState();
}

class _AssessmentOverlayState extends State<_AssessmentOverlay> {
  final TextEditingController _responseCtrl = TextEditingController();

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assessment = widget.assessment;
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.56),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      assessment.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(assessment.prompt),
              const SizedBox(height: 16),
              if (assessment.type == LiveClassAssessmentType.shortAnswer)
                TextField(
                  controller: _responseCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: assessment.shortAnswerHint,
                  ),
                )
              else
                Column(
                  children: assessment.options
                      .map(
                        (option) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.radio_button_checked_rounded,
                          ),
                          title: Text(option.label),
                          onTap: widget.isLecturer
                              ? null
                              : () => widget.onSubmit(option.label),
                        ),
                      )
                      .toList(growable: false),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!widget.isLecturer &&
                      assessment.type == LiveClassAssessmentType.shortAnswer)
                    FilledButton(
                      onPressed: () =>
                          widget.onSubmit(_responseCtrl.text.trim()),
                      child: const Text('Submit response'),
                    ),
                  if (widget.isLecturer)
                    FilledButton.tonal(
                      onPressed: widget.onShowResults,
                      child: const Text('View results'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveClassInteractionPanel extends StatelessWidget {
  const _LiveClassInteractionPanel({
    required this.room,
    required this.participants,
    required this.layoutController,
    required this.boardController,
    required this.chatController,
    required this.questionController,
    required this.aiController,
    required this.currentParticipantId,
    required this.currentParticipantName,
    required this.onSendChat,
    required this.onSubmitQuestion,
    required this.onAnswerQuestion,
    required this.onLaunchAssessment,
    required this.onSaveBoard,
    required this.onShowResults,
    required this.compact,
    required this.isLecturer,
  });

  final LiveSessionRoomState room;
  final List<LiveSessionParticipant> participants;
  final LiveClassLayoutController layoutController;
  final LiveClassBoardController boardController;
  final TextEditingController chatController;
  final TextEditingController questionController;
  final TextEditingController aiController;
  final String currentParticipantId;
  final String currentParticipantName;
  final Future<void> Function() onSendChat;
  final Future<void> Function() onSubmitQuestion;
  final Future<void> Function(LiveSessionQuestion question) onAnswerQuestion;
  final ValueChanged<LiveClassAssessmentType>? onLaunchAssessment;
  final VoidCallback onSaveBoard;
  final VoidCallback onShowResults;
  final bool compact;
  final bool isLecturer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOpen = layoutController.isInteractionPanelOpen;

    if (compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 68,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: layoutController.toggleInteractionPanel,
                    tooltip: isOpen ? 'Hide panel' : 'Show panel',
                    icon: Icon(
                      isOpen
                          ? Icons.keyboard_double_arrow_down_rounded
                          : Icons.keyboard_double_arrow_up_rounded,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                      child: Row(
                        children: LiveClassPanelTab.values
                            .map(
                              (tab) => Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(tab.label),
                                  avatar: Icon(tab.icon, size: 18),
                                  selected: layoutController.activePanel == tab,
                                  onSelected: (_) {
                                    layoutController.setActivePanel(tab);
                                    if (!layoutController
                                        .isInteractionPanelOpen) {
                                      layoutController.toggleInteractionPanel();
                                    }
                                  },
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isOpen)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: _PanelContent(
                    room: room,
                    participants: participants,
                    layoutController: layoutController,
                    boardController: boardController,
                    chatController: chatController,
                    questionController: questionController,
                    aiController: aiController,
                    currentParticipantId: currentParticipantId,
                    currentParticipantName: currentParticipantName,
                    onSendChat: onSendChat,
                    onSubmitQuestion: onSubmitQuestion,
                    onAnswerQuestion: onAnswerQuestion,
                    onLaunchAssessment: onLaunchAssessment,
                    onSaveBoard: onSaveBoard,
                    onShowResults: onShowResults,
                    isLecturer: isLecturer,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? double.infinity : 84,
            child: compact
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: LiveClassPanelTab.values
                          .map(
                            (tab) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(tab.label),
                                avatar: Icon(tab.icon, size: 18),
                                selected: layoutController.activePanel == tab,
                                onSelected: (_) =>
                                    layoutController.setActivePanel(tab),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  )
                : Column(
                    children: [
                      const SizedBox(height: 12),
                      IconButton.filledTonal(
                        onPressed: layoutController.toggleInteractionPanel,
                        icon: Icon(
                          isOpen
                              ? Icons.keyboard_double_arrow_right_rounded
                              : Icons.keyboard_double_arrow_left_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final tab in LiveClassPanelTab.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: IconButton.filledTonal(
                            onPressed: () =>
                                layoutController.setActivePanel(tab),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  layoutController.activePanel == tab
                                  ? cs.primary.withValues(alpha: 0.20)
                                  : null,
                            ),
                            icon: Icon(tab.icon),
                            tooltip: tab.label,
                          ),
                        ),
                    ],
                  ),
          ),
          if (isOpen || compact)
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(compact ? 10 : 0, 16, 16, 16),
                child: _PanelContent(
                  room: room,
                  participants: participants,
                  layoutController: layoutController,
                  boardController: boardController,
                  chatController: chatController,
                  questionController: questionController,
                  aiController: aiController,
                  currentParticipantId: currentParticipantId,
                  currentParticipantName: currentParticipantName,
                  onSendChat: onSendChat,
                  onSubmitQuestion: onSubmitQuestion,
                  onAnswerQuestion: onAnswerQuestion,
                  onLaunchAssessment: onLaunchAssessment,
                  onSaveBoard: onSaveBoard,
                  onShowResults: onShowResults,
                  isLecturer: isLecturer,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.room,
    required this.participants,
    required this.layoutController,
    required this.boardController,
    required this.chatController,
    required this.questionController,
    required this.aiController,
    required this.currentParticipantId,
    required this.currentParticipantName,
    required this.onSendChat,
    required this.onSubmitQuestion,
    required this.onAnswerQuestion,
    required this.onLaunchAssessment,
    required this.onSaveBoard,
    required this.onShowResults,
    required this.isLecturer,
  });

  final LiveSessionRoomState room;
  final List<LiveSessionParticipant> participants;
  final LiveClassLayoutController layoutController;
  final LiveClassBoardController boardController;
  final TextEditingController chatController;
  final TextEditingController questionController;
  final TextEditingController aiController;
  final String currentParticipantId;
  final String currentParticipantName;
  final Future<void> Function() onSendChat;
  final Future<void> Function() onSubmitQuestion;
  final Future<void> Function(LiveSessionQuestion question) onAnswerQuestion;
  final ValueChanged<LiveClassAssessmentType>? onLaunchAssessment;
  final VoidCallback onSaveBoard;
  final VoidCallback onShowResults;
  final bool isLecturer;

  @override
  Widget build(BuildContext context) {
    switch (layoutController.activePanel) {
      case LiveClassPanelTab.chat:
        return _ChatPanel(
          room: room,
          chatController: chatController,
          onSend: onSendChat,
        );
      case LiveClassPanelTab.participants:
        return _ParticipantsPanel(
          participants: participants,
          layoutController: layoutController,
          isLecturer: isLecturer,
        );
      case LiveClassPanelTab.hands:
        return _RaisedHandsPanel(
          participants: participants,
          raisedHands: layoutController.raisedHands,
        );
      case LiveClassPanelTab.ai:
        return _AIAssistantPanel(
          aiController: aiController,
          boardController: boardController,
        );
      case LiveClassPanelTab.resources:
        return _ResourcesPanel(
          room: room,
          boardController: boardController,
          onSaveBoard: onSaveBoard,
        );
      case LiveClassPanelTab.quiz:
        return _QuizPanel(
          room: room,
          questionController: questionController,
          onSubmitQuestion: onSubmitQuestion,
          onAnswerQuestion: onAnswerQuestion,
          activeAssessment: layoutController.activeAssessment,
          onLaunchAssessment: onLaunchAssessment,
          onShowResults: onShowResults,
          isLecturer: isLecturer,
        );
    }
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.room,
    required this.chatController,
    required this.onSend,
  });

  final LiveSessionRoomState room;
  final TextEditingController chatController;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Class chat', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: room.chatMessages.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final message = room.chatMessages[index];
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(message.senderName),
                subtitle: Text(message.message),
                trailing: Text(
                  liveSessionDateTime(message.sentAt).split('·').last.trim(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: chatController,
                decoration: const InputDecoration(
                  hintText: 'Share a message with the class',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: onSend, child: const Text('Send')),
          ],
        ),
      ],
    );
  }
}

class _ParticipantsPanel extends StatelessWidget {
  const _ParticipantsPanel({
    required this.participants,
    required this.layoutController,
    required this.isLecturer,
  });

  final List<LiveSessionParticipant> participants;
  final LiveClassLayoutController layoutController;
  final bool isLecturer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Participants', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: participants.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final participant = participants[index];
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: CircleAvatar(
                  child: Text(
                    participant.displayName.characters.first.toUpperCase(),
                  ),
                ),
                title: Text(participant.displayName),
                subtitle: Text(
                  '${participant.role == LiveSessionRole.lecturer ? 'Lecturer' : 'Student'} · ${participant.isPresent ? 'Present' : 'Away'}',
                ),
                trailing:
                    isLecturer && participant.role != LiveSessionRole.lecturer
                    ? FilledButton.tonal(
                        onPressed: () {
                          layoutController.setStudentBoardAccess(true);
                          layoutController.selectParticipant(participant.id);
                        },
                        child: const Text('Board'),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RaisedHandsPanel extends StatelessWidget {
  const _RaisedHandsPanel({
    required this.participants,
    required this.raisedHands,
  });

  final List<LiveSessionParticipant> participants;
  final Set<String> raisedHands;

  @override
  Widget build(BuildContext context) {
    final raised = participants
        .where((participant) => raisedHands.contains(participant.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Raised hands', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (raised.isEmpty)
          const Expanded(
            child: Center(child: Text('No raised hands at the moment.')),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: raised.length,
              itemBuilder: (context, index) {
                final participant = raised[index];
                return ListTile(
                  leading: const Icon(Icons.front_hand_rounded),
                  title: Text(participant.displayName),
                  subtitle: Text(
                    participant.registrationNumber ?? participant.role,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AIAssistantPanel extends StatelessWidget {
  const _AIAssistantPanel({
    required this.aiController,
    required this.boardController,
  });

  final TextEditingController aiController;
  final LiveClassBoardController boardController;

  @override
  Widget build(BuildContext context) {
    final cards = <({String title, String body})>[
      (
        title: 'Lecture summary',
        body: 'Reserve this card for post-class recap and topic summary.',
      ),
      (
        title: 'Explain current topic',
        body:
            'Trigger a simpler explanation of what is on the board right now.',
      ),
      (
        title: 'Generated notes',
        body:
            'Build Go-backend-ready notes from saved annotations and pinned moments.',
      ),
      (
        title: 'Translated explanation',
        body:
            'Use this slot for multilingual support without leaving the class.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI assistant', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: aiController,
          decoration: const InputDecoration(
            hintText: 'Ask AI about the current topic',
            suffixIcon: Icon(Icons.auto_awesome_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StageBadge(
              label:
                  '${boardController.currentAnnotationCount} board notes on this page',
              icon: Icons.note_alt_rounded,
              color: Colors.lightBlueAccent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(card.title),
                subtitle: Text(card.body),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResourcesPanel extends StatelessWidget {
  const _ResourcesPanel({
    required this.room,
    required this.boardController,
    required this.onSaveBoard,
  });

  final LiveSessionRoomState room;
  final LiveClassBoardController boardController;
  final VoidCallback onSaveBoard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Class resources', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: onSaveBoard,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save board'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export annotation'),
            ),
            FilledButton.tonalIcon(
              onPressed: () {},
              icon: const Icon(Icons.book_rounded),
              label: const Text('Class notes'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: room.session.materials.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final material = room.session.materials[index];
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(material.title),
                subtitle: Text(material.subtitle),
                trailing: Text(material.status),
                onTap: () => boardController.setPage(index + 1),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuizPanel extends StatelessWidget {
  const _QuizPanel({
    required this.room,
    required this.questionController,
    required this.onSubmitQuestion,
    required this.onAnswerQuestion,
    required this.activeAssessment,
    required this.onLaunchAssessment,
    required this.onShowResults,
    required this.isLecturer,
  });

  final LiveSessionRoomState room;
  final TextEditingController questionController;
  final Future<void> Function() onSubmitQuestion;
  final Future<void> Function(LiveSessionQuestion question) onAnswerQuestion;
  final LiveClassAssessmentState? activeAssessment;
  final ValueChanged<LiveClassAssessmentType>? onLaunchAssessment;
  final VoidCallback onShowResults;
  final bool isLecturer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactPanel = constraints.maxHeight < 330;
        final title = Text(
          'Quiz and questions',
          style: compactPanel
              ? Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
              : Theme.of(context).textTheme.titleLarge,
        );
        final composer = isLecturer
            ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: () =>
                        onLaunchAssessment?.call(LiveClassAssessmentType.quiz),
                    child: const Text('Launch quiz'),
                  ),
                  FilledButton.tonal(
                    onPressed: () =>
                        onLaunchAssessment?.call(LiveClassAssessmentType.poll),
                    child: const Text('Launch poll'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => onLaunchAssessment?.call(
                      LiveClassAssessmentType.shortAnswer,
                    ),
                    child: const Text('Short answer'),
                  ),
                  if (activeAssessment != null)
                    FilledButton(
                      onPressed: onShowResults,
                      child: const Text('Results'),
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: questionController,
                    maxLines: compactPanel ? 2 : 3,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question without leaving the class page',
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: onSubmitQuestion,
                    child: const Text('Submit question'),
                  ),
                ],
              );
        final activeTile = activeAssessment == null
            ? null
            : ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.quiz_rounded),
                title: Text(activeAssessment!.title),
                subtitle: Text(activeAssessment!.prompt),
                trailing: Text(
                  '${activeAssessment!.responses.length} responses',
                ),
              );
        final questionTiles = room.questions
            .map((question) {
              return ListTile(
                tileColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: Text(question.askedByName),
                subtitle: Text(
                  question.answer == null
                      ? question.question
                      : '${question.question}\n\nAnswer: ${question.answer}',
                ),
                trailing: isLecturer && question.answer == null
                    ? FilledButton.tonal(
                        onPressed: () => onAnswerQuestion(question),
                        child: const Text('Answer'),
                      )
                    : null,
              );
            })
            .toList(growable: false);

        if (compactPanel) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              title,
              const SizedBox(height: 10),
              composer,
              if (activeTile != null) ...[
                const SizedBox(height: 10),
                activeTile,
              ],
              const SizedBox(height: 10),
              ...questionTiles.expand(
                (tile) => [tile, const SizedBox(height: 10)],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 12),
            composer,
            if (activeTile != null) ...[const SizedBox(height: 12), activeTile],
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: questionTiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => questionTiles[index],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NetworkMeta {
  const _NetworkMeta({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
