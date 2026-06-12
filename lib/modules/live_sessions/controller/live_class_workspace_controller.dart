import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../data/models/live_session_models.dart';

enum LiveClassMode { video, board, presentation, hybrid, studentPresentation }

extension LiveClassModeX on LiveClassMode {
  String get label {
    switch (this) {
      case LiveClassMode.video:
        return 'Video mode';
      case LiveClassMode.board:
        return 'Board mode';
      case LiveClassMode.presentation:
        return 'Presentation';
      case LiveClassMode.hybrid:
        return 'Hybrid mode';
      case LiveClassMode.studentPresentation:
        return 'Student presenter';
    }
  }

  IconData get icon {
    switch (this) {
      case LiveClassMode.video:
        return Icons.videocam_rounded;
      case LiveClassMode.board:
        return Icons.draw_rounded;
      case LiveClassMode.presentation:
        return Icons.slideshow_rounded;
      case LiveClassMode.hybrid:
        return Icons.dashboard_customize_rounded;
      case LiveClassMode.studentPresentation:
        return Icons.person_pin_circle_rounded;
    }
  }
}

enum LiveClassPanelTab { chat, participants, hands, ai, resources, quiz }

extension LiveClassPanelTabX on LiveClassPanelTab {
  String get label {
    switch (this) {
      case LiveClassPanelTab.chat:
        return 'Chat';
      case LiveClassPanelTab.participants:
        return 'Participants';
      case LiveClassPanelTab.hands:
        return 'Raised hands';
      case LiveClassPanelTab.ai:
        return 'AI Assistant';
      case LiveClassPanelTab.resources:
        return 'Resources';
      case LiveClassPanelTab.quiz:
        return 'Quiz';
    }
  }

  IconData get icon {
    switch (this) {
      case LiveClassPanelTab.chat:
        return Icons.chat_bubble_rounded;
      case LiveClassPanelTab.participants:
        return Icons.groups_rounded;
      case LiveClassPanelTab.hands:
        return Icons.front_hand_rounded;
      case LiveClassPanelTab.ai:
        return Icons.auto_awesome_rounded;
      case LiveClassPanelTab.resources:
        return Icons.folder_open_rounded;
      case LiveClassPanelTab.quiz:
        return Icons.quiz_rounded;
    }
  }
}

enum LiveClassContentSource {
  lecturerCamera,
  slides,
  screenShare,
  whiteboard,
  mixed,
}

extension LiveClassContentSourceX on LiveClassContentSource {
  String get label {
    switch (this) {
      case LiveClassContentSource.lecturerCamera:
        return 'Lecturer camera';
      case LiveClassContentSource.slides:
        return 'Slides / PDF';
      case LiveClassContentSource.screenShare:
        return 'Shared screen';
      case LiveClassContentSource.whiteboard:
        return 'Whiteboard';
      case LiveClassContentSource.mixed:
        return 'Mixed mode';
    }
  }

  IconData get icon {
    switch (this) {
      case LiveClassContentSource.lecturerCamera:
        return Icons.ondemand_video_rounded;
      case LiveClassContentSource.slides:
        return Icons.library_books_rounded;
      case LiveClassContentSource.screenShare:
        return Icons.screen_share_rounded;
      case LiveClassContentSource.whiteboard:
        return Icons.sticky_note_2_rounded;
      case LiveClassContentSource.mixed:
        return Icons.layers_rounded;
    }
  }
}

enum LiveClassBoardTool { pen, highlighter, eraser, pointer }

extension LiveClassBoardToolX on LiveClassBoardTool {
  String get label {
    switch (this) {
      case LiveClassBoardTool.pen:
        return 'Pen';
      case LiveClassBoardTool.highlighter:
        return 'Highlighter';
      case LiveClassBoardTool.eraser:
        return 'Eraser';
      case LiveClassBoardTool.pointer:
        return 'Pointer';
    }
  }

  IconData get icon {
    switch (this) {
      case LiveClassBoardTool.pen:
        return Icons.edit_rounded;
      case LiveClassBoardTool.highlighter:
        return Icons.draw_rounded;
      case LiveClassBoardTool.eraser:
        return Icons.auto_fix_off_rounded;
      case LiveClassBoardTool.pointer:
        return Icons.ads_click_rounded;
    }
  }
}

enum LiveClassBoardBackground { blank, dark, grid, presentationOverlay }

extension LiveClassBoardBackgroundX on LiveClassBoardBackground {
  String get label {
    switch (this) {
      case LiveClassBoardBackground.blank:
        return 'Blank board';
      case LiveClassBoardBackground.dark:
        return 'Dark board';
      case LiveClassBoardBackground.grid:
        return 'Grid board';
      case LiveClassBoardBackground.presentationOverlay:
        return 'Presentation overlay';
    }
  }
}

enum LiveClassSessionUiState { initializing, live, paused, reconnecting, ended }

extension LiveClassSessionUiStateX on LiveClassSessionUiState {
  String get label {
    switch (this) {
      case LiveClassSessionUiState.initializing:
        return 'Initializing';
      case LiveClassSessionUiState.live:
        return 'Live';
      case LiveClassSessionUiState.paused:
        return 'Paused';
      case LiveClassSessionUiState.reconnecting:
        return 'Reconnecting';
      case LiveClassSessionUiState.ended:
        return 'Ended';
    }
  }
}

enum LiveClassGestureTrackingState {
  notStarted,
  checkingPermission,
  active,
  handDetected,
  noHandDetected,
  lowLight,
  blockedCamera,
  trackingError,
}

extension LiveClassGestureTrackingStateX on LiveClassGestureTrackingState {
  String get label {
    switch (this) {
      case LiveClassGestureTrackingState.notStarted:
        return 'Off';
      case LiveClassGestureTrackingState.checkingPermission:
        return 'Starting';
      case LiveClassGestureTrackingState.active:
        return 'Active';
      case LiveClassGestureTrackingState.handDetected:
        return 'Hand detected';
      case LiveClassGestureTrackingState.noHandDetected:
        return 'No hand detected';
      case LiveClassGestureTrackingState.lowLight:
        return 'Low light';
      case LiveClassGestureTrackingState.blockedCamera:
        return 'Camera blocked';
      case LiveClassGestureTrackingState.trackingError:
        return 'Error';
    }
  }
}

enum LiveClassGestureAction {
  none,
  ready,
  draw,
  erase,
  move,
  slideNext,
  slidePrevious,
  pauseInput,
}

extension LiveClassGestureActionX on LiveClassGestureAction {
  String get label {
    switch (this) {
      case LiveClassGestureAction.none:
        return 'Gesture mode';
      case LiveClassGestureAction.ready:
        return 'Ready to write';
      case LiveClassGestureAction.draw:
        return 'Draw mode';
      case LiveClassGestureAction.erase:
        return 'Erase mode';
      case LiveClassGestureAction.move:
        return 'Move mode';
      case LiveClassGestureAction.slideNext:
        return 'Slide next';
      case LiveClassGestureAction.slidePrevious:
        return 'Slide previous';
      case LiveClassGestureAction.pauseInput:
        return 'Pause input';
    }
  }
}

enum LiveClassAssessmentType { quiz, poll, shortAnswer }

extension LiveClassAssessmentTypeX on LiveClassAssessmentType {
  String get label {
    switch (this) {
      case LiveClassAssessmentType.quiz:
        return 'Quiz';
      case LiveClassAssessmentType.poll:
        return 'Poll';
      case LiveClassAssessmentType.shortAnswer:
        return 'Short answer';
    }
  }
}

class LiveClassAssessmentOption {
  const LiveClassAssessmentOption({required this.id, required this.label});

  final String id;
  final String label;
}

class LiveClassAssessmentState {
  const LiveClassAssessmentState({
    required this.id,
    required this.title,
    required this.prompt,
    required this.type,
    this.options = const <LiveClassAssessmentOption>[],
    this.shortAnswerHint,
    this.startedAt,
    this.isOpen = true,
    this.responses = const <String, String>{},
  });

  final String id;
  final String title;
  final String prompt;
  final LiveClassAssessmentType type;
  final List<LiveClassAssessmentOption> options;
  final String? shortAnswerHint;
  final DateTime? startedAt;
  final bool isOpen;
  final Map<String, String> responses;

  LiveClassAssessmentState copyWith({
    String? id,
    String? title,
    String? prompt,
    LiveClassAssessmentType? type,
    List<LiveClassAssessmentOption>? options,
    String? shortAnswerHint,
    DateTime? startedAt,
    bool? isOpen,
    Map<String, String>? responses,
  }) {
    return LiveClassAssessmentState(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      type: type ?? this.type,
      options: options ?? this.options,
      shortAnswerHint: shortAnswerHint ?? this.shortAnswerHint,
      startedAt: startedAt ?? this.startedAt,
      isOpen: isOpen ?? this.isOpen,
      responses: responses ?? this.responses,
    );
  }

  Map<String, int> tally() {
    final counts = <String, int>{};
    for (final value in responses.values) {
      counts.update(value, (current) => current + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

class LiveClassRealtimeEventType {
  static const String drawStart = 'draw_start';
  static const String drawMove = 'draw_move';
  static const String drawEnd = 'draw_end';
  static const String clearCanvas = 'clear_canvas';
  static const String undo = 'undo';
  static const String redo = 'redo';
  static const String gestureState = 'gesture_state';
  static const String quizStarted = 'quiz_started';
  static const String handRaised = 'hand_raised';
  static const String participantJoined = 'participant_joined';
  static const String participantLeft = 'participant_left';
  static const String presenterChanged = 'presenter_changed';
}

class LiveClassRealtimeEvent {
  LiveClassRealtimeEvent({
    required this.type,
    this.payload = const <String, dynamic>{},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
}

class LiveClassGestureController extends ChangeNotifier {
  LiveClassGestureController({
    this.gesturePreviewVisible = false,
    this.previewOffset = const Offset(24, 24),
  });

  bool isGestureEnabled = false;
  bool isCameraReady = false;
  bool isHandDetected = false;
  LiveClassGestureAction currentGesture = LiveClassGestureAction.none;
  String? gestureError;
  bool gesturePreviewVisible;
  LiveClassGestureTrackingState trackingState =
      LiveClassGestureTrackingState.notStarted;
  Offset previewOffset;

  Timer? _handPresenceTimer;

  bool get isUnavailable =>
      trackingState == LiveClassGestureTrackingState.blockedCamera ||
      trackingState == LiveClassGestureTrackingState.trackingError;

  Future<void> setGestureEnabled(
    bool enabled, {
    required bool cameraReady,
  }) async {
    _handPresenceTimer?.cancel();
    if (!enabled) {
      isGestureEnabled = false;
      isCameraReady = cameraReady;
      isHandDetected = false;
      currentGesture = LiveClassGestureAction.none;
      trackingState = LiveClassGestureTrackingState.notStarted;
      gestureError = null;
      gesturePreviewVisible = false;
      notifyListeners();
      return;
    }

    isGestureEnabled = true;
    isCameraReady = cameraReady;
    gesturePreviewVisible = true;
    trackingState = LiveClassGestureTrackingState.checkingPermission;
    currentGesture = LiveClassGestureAction.none;
    gestureError = null;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 320));
    if (!isGestureEnabled) return;
    if (!cameraReady) {
      trackingState = LiveClassGestureTrackingState.blockedCamera;
      currentGesture = LiveClassGestureAction.none;
      gestureError =
          'Gesture tracking needs a live camera feed. Turn the camera on or use manual drawing.';
      notifyListeners();
      return;
    }

    trackingState = LiveClassGestureTrackingState.active;
    currentGesture = LiveClassGestureAction.ready;
    gestureError = null;
    notifyListeners();
  }

  void syncCameraReady(bool ready) {
    isCameraReady = ready;
    if (!isGestureEnabled) {
      notifyListeners();
      return;
    }

    if (!ready) {
      trackingState = LiveClassGestureTrackingState.blockedCamera;
      currentGesture = LiveClassGestureAction.none;
      isHandDetected = false;
      gestureError =
          'Camera feed became unavailable. Switch to manual writing or re-enable the camera.';
      _handPresenceTimer?.cancel();
    } else if (trackingState == LiveClassGestureTrackingState.blockedCamera) {
      trackingState = LiveClassGestureTrackingState.active;
      currentGesture = LiveClassGestureAction.ready;
      gestureError = null;
    }
    notifyListeners();
  }

  void updateHandState({
    required bool detected,
    LiveClassGestureAction? action,
    LiveClassGestureTrackingState? state,
    String? error,
  }) {
    if (!isGestureEnabled) return;
    _handPresenceTimer?.cancel();
    isHandDetected = detected;
    gestureError = error;

    if (error != null && error.isNotEmpty) {
      trackingState = LiveClassGestureTrackingState.trackingError;
      currentGesture = LiveClassGestureAction.none;
      notifyListeners();
      return;
    }

    if (detected) {
      trackingState = state ?? LiveClassGestureTrackingState.handDetected;
      currentGesture = action ?? LiveClassGestureAction.draw;
      _handPresenceTimer = Timer(const Duration(seconds: 4), () {
        if (!isGestureEnabled) return;
        isHandDetected = false;
        trackingState = LiveClassGestureTrackingState.noHandDetected;
        if (currentGesture != LiveClassGestureAction.pauseInput) {
          currentGesture = LiveClassGestureAction.ready;
        }
        notifyListeners();
      });
    } else {
      trackingState = state ?? LiveClassGestureTrackingState.noHandDetected;
      currentGesture = action ?? LiveClassGestureAction.ready;
    }
    notifyListeners();
  }

  void setTrackingWarning(
    LiveClassGestureTrackingState state, {
    String? message,
  }) {
    if (!isGestureEnabled) return;
    trackingState = state;
    if (message != null && message.isNotEmpty) {
      gestureError = message;
    }
    notifyListeners();
  }

  void movePreview(Offset delta, Size bounds) {
    final maxX = math.max(0.0, bounds.width - 220);
    final maxY = math.max(0.0, bounds.height - 160);
    previewOffset = Offset(
      (previewOffset.dx + delta.dx).clamp(0.0, maxX),
      (previewOffset.dy + delta.dy).clamp(0.0, maxY),
    );
    notifyListeners();
  }

  void handleRealtimeEvent(LiveClassRealtimeEvent event) {
    if (event.type != LiveClassRealtimeEventType.gestureState) return;
    final rawState = event.payload['state']?.toString();
    final rawAction = event.payload['action']?.toString();
    updateHandState(
      detected: event.payload['isHandDetected'] == true,
      state: _gestureStateFromWire(rawState),
      action: _gestureActionFromWire(rawAction),
      error: event.payload['error']?.toString(),
    );
  }

  LiveClassGestureTrackingState? _gestureStateFromWire(String? value) {
    switch (value) {
      case 'checking_permission':
        return LiveClassGestureTrackingState.checkingPermission;
      case 'active':
        return LiveClassGestureTrackingState.active;
      case 'hand_detected':
        return LiveClassGestureTrackingState.handDetected;
      case 'no_hand_detected':
        return LiveClassGestureTrackingState.noHandDetected;
      case 'low_light':
        return LiveClassGestureTrackingState.lowLight;
      case 'blocked_camera':
        return LiveClassGestureTrackingState.blockedCamera;
      case 'tracking_error':
        return LiveClassGestureTrackingState.trackingError;
      default:
        return null;
    }
  }

  LiveClassGestureAction? _gestureActionFromWire(String? value) {
    switch (value) {
      case 'ready':
        return LiveClassGestureAction.ready;
      case 'draw':
        return LiveClassGestureAction.draw;
      case 'erase':
        return LiveClassGestureAction.erase;
      case 'move':
        return LiveClassGestureAction.move;
      case 'slide_next':
        return LiveClassGestureAction.slideNext;
      case 'slide_previous':
        return LiveClassGestureAction.slidePrevious;
      case 'pause_input':
        return LiveClassGestureAction.pauseInput;
      default:
        return null;
    }
  }

  @override
  void dispose() {
    _handPresenceTimer?.cancel();
    super.dispose();
  }
}

class LiveClassBoardController extends ChangeNotifier {
  LiveClassBoardController({required this.sessionId, required this.userId});

  final String sessionId;
  final String userId;

  LiveClassBoardTool currentTool = LiveClassBoardTool.pen;
  LiveClassBoardBackground background = LiveClassBoardBackground.blank;
  final Map<int, List<WhiteboardStroke>> _pageAnnotations =
      <int, List<WhiteboardStroke>>{};
  final Map<int, List<List<WhiteboardStroke>>> _undoHistory =
      <int, List<List<WhiteboardStroke>>>{};
  final Map<int, List<List<WhiteboardStroke>>> _redoHistory =
      <int, List<List<WhiteboardStroke>>>{};
  final Map<String, _RealtimeStrokeBuffer> _remoteStrokeBuffer =
      <String, _RealtimeStrokeBuffer>{};

  WhiteboardStroke? _activeStroke;
  Offset? _laserPointer;
  int currentPage = 1;
  int pageCount = 5;
  double canvasZoom = 1.0;
  Offset canvasOffset = Offset.zero;
  double strokeWidth = 3.5;
  int colorValue = 0xFF1D4ED8;

  WhiteboardStroke? get activeStroke => _activeStroke;
  Offset? get laserPointer => _laserPointer;
  List<WhiteboardStroke> get currentPageStrokes =>
      List<WhiteboardStroke>.unmodifiable(
        _pageAnnotations[currentPage] ?? const <WhiteboardStroke>[],
      );
  List<WhiteboardStroke> get remotePreviewStrokes => _remoteStrokeBuffer.values
      .where((buffer) => buffer.page == currentPage)
      .map((buffer) => buffer.stroke)
      .toList(growable: false);
  int get currentAnnotationCount => currentPageStrokes.length;
  bool get hasActiveStroke => _activeStroke != null;
  bool get canUndo => (_undoHistory[currentPage] ?? const []).isNotEmpty;
  bool get canRedo => (_redoHistory[currentPage] ?? const []).isNotEmpty;

  Map<int, List<WhiteboardStroke>> get pageAnnotations =>
      Map<int, List<WhiteboardStroke>>.unmodifiable(_pageAnnotations);

  void setTool(LiveClassBoardTool tool) {
    currentTool = tool;
    if (tool != LiveClassBoardTool.pointer) {
      _laserPointer = null;
    }
    notifyListeners();
  }

  void setBackground(LiveClassBoardBackground value) {
    background = value;
    notifyListeners();
  }

  void setStrokeColor(int value) {
    colorValue = value;
    notifyListeners();
  }

  void setStrokeWidth(double value) {
    strokeWidth = value.clamp(2.0, 18.0);
    notifyListeners();
  }

  void setPageCount(int value) {
    pageCount = value < 1 ? 1 : value;
    if (currentPage > pageCount) {
      currentPage = pageCount;
    }
    notifyListeners();
  }

  void setPage(int page) {
    if (page < 1 || page > pageCount) return;
    if (_activeStroke != null) {
      endStroke();
    }
    currentPage = page;
    _laserPointer = null;
    notifyListeners();
  }

  void nextPage() => setPage(math.min(pageCount, currentPage + 1));

  void previousPage() => setPage(math.max(1, currentPage - 1));

  void adjustZoom(double delta) {
    setZoom(canvasZoom + delta);
  }

  void setZoom(double value) {
    canvasZoom = value.clamp(1.0, 3.5);
    notifyListeners();
  }

  void translateCanvas(Offset delta) {
    canvasOffset += delta;
    notifyListeners();
  }

  void resetViewport() {
    canvasZoom = 1.0;
    canvasOffset = Offset.zero;
    notifyListeners();
  }

  void updateLaserPointer(Offset? localPosition, Size size) {
    if (localPosition == null) {
      _laserPointer = null;
    } else {
      _laserPointer = _denormalize(_normalizePoint(localPosition, size), size);
    }
    notifyListeners();
  }

  void beginStroke(
    Offset localPosition,
    Size size, {
    String? authorId,
    String? sourceSessionId,
    LiveClassBoardTool? tool,
    DateTime? timestamp,
  }) {
    final activeTool = tool ?? currentTool;
    if (activeTool == LiveClassBoardTool.pointer) {
      updateLaserPointer(localPosition, size);
      return;
    }

    final point = _normalizePoint(localPosition, size);
    if (activeTool == LiveClassBoardTool.eraser) {
      _eraseAtPoint(point);
      return;
    }

    _activeStroke = WhiteboardStroke(
      points: <WhiteboardPoint>[point],
      colorValue: _toolColor(activeTool),
      strokeWidth: _toolWidth(activeTool),
      toolType: activeTool.name,
      timestamp: timestamp ?? DateTime.now(),
      userId: authorId ?? userId,
      sessionId: sourceSessionId ?? sessionId,
    );
    notifyListeners();
  }

  void appendPoint(Offset localPosition, Size size) {
    final stroke = _activeStroke;
    if (stroke == null) {
      if (currentTool == LiveClassBoardTool.pointer) {
        updateLaserPointer(localPosition, size);
      }
      return;
    }

    final point = _normalizePoint(localPosition, size);
    final points = List<WhiteboardPoint>.from(stroke.points);
    final previous = points.last;
    final distance = _distanceBetween(previous, point);
    if (distance < 0.002) return;

    final steps = math.max(1, (distance / 0.025).ceil());
    for (var index = 1; index <= steps; index++) {
      final t = index / steps;
      points.add(_lerpPoint(previous, point, t));
    }

    _activeStroke = stroke.copyWith(points: points);
    notifyListeners();
  }

  void endStroke() {
    final stroke = _activeStroke;
    _activeStroke = null;
    if (stroke == null || !stroke.isUsable) {
      notifyListeners();
      return;
    }

    _commitPageMutation(currentPage, (current) {
      return <WhiteboardStroke>[...current, stroke];
    });
  }

  void clearCurrentPage() {
    if ((_pageAnnotations[currentPage] ?? const []).isEmpty) return;
    _activeStroke = null;
    _commitPageMutation(currentPage, (_) => const <WhiteboardStroke>[]);
  }

  void undo() => _undoPage(currentPage);

  void redo() => _redoPage(currentPage);

  Map<String, dynamic> exportCurrentPage() {
    return <String, dynamic>{
      'sessionId': sessionId,
      'page': currentPage,
      'background': background.name,
      'zoom': canvasZoom,
      'offset': <String, double>{'dx': canvasOffset.dx, 'dy': canvasOffset.dy},
      'strokes': currentPageStrokes.map((stroke) => stroke.toMap()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  int annotationCountForPage(int page) {
    return (_pageAnnotations[page] ?? const <WhiteboardStroke>[]).length;
  }

  void handleRealtimeEvent(LiveClassRealtimeEvent event) {
    switch (event.type) {
      case LiveClassRealtimeEventType.drawStart:
        _handleRealtimeDrawStart(event.payload);
        break;
      case LiveClassRealtimeEventType.drawMove:
        _handleRealtimeDrawMove(event.payload);
        break;
      case LiveClassRealtimeEventType.drawEnd:
        _handleRealtimeDrawEnd(event.payload);
        break;
      case LiveClassRealtimeEventType.clearCanvas:
        final page = _pageFromPayload(event.payload);
        _commitPageMutation(page, (_) => const <WhiteboardStroke>[]);
        break;
      case LiveClassRealtimeEventType.undo:
        _undoPage(_pageFromPayload(event.payload));
        break;
      case LiveClassRealtimeEventType.redo:
        _redoPage(_pageFromPayload(event.payload));
        break;
      default:
        break;
    }
  }

  void _handleRealtimeDrawStart(Map<String, dynamic> payload) {
    final page = _pageFromPayload(payload);
    final strokeId =
        payload['strokeId']?.toString() ?? _bufferKey(page, payload);
    final point = _payloadPoint(payload);
    if (point == null) return;
    final tool = _toolFromWire(payload['toolType']?.toString());
    _remoteStrokeBuffer[strokeId] = _RealtimeStrokeBuffer(
      page: page,
      stroke: WhiteboardStroke(
        points: <WhiteboardPoint>[point],
        colorValue: (payload['color'] is num)
            ? (payload['color'] as num).toInt()
            : _toolColor(tool),
        strokeWidth: (payload['thickness'] is num)
            ? (payload['thickness'] as num).toDouble()
            : _toolWidth(tool),
        toolType: tool.name,
        timestamp: DateTime.tryParse(payload['timestamp']?.toString() ?? ''),
        userId: payload['userId']?.toString(),
        sessionId: payload['sessionId']?.toString() ?? sessionId,
      ),
    );
    notifyListeners();
  }

  void _handleRealtimeDrawMove(Map<String, dynamic> payload) {
    final strokeId =
        payload['strokeId']?.toString() ??
        _bufferKey(_pageFromPayload(payload), payload);
    final buffer = _remoteStrokeBuffer[strokeId];
    final point = _payloadPoint(payload);
    if (buffer == null || point == null) return;

    final points = List<WhiteboardPoint>.from(buffer.stroke.points);
    final previous = points.last;
    final distance = _distanceBetween(previous, point);
    final steps = math.max(1, (distance / 0.025).ceil());
    for (var index = 1; index <= steps; index++) {
      final t = index / steps;
      points.add(_lerpPoint(previous, point, t));
    }

    _remoteStrokeBuffer[strokeId] = buffer.copyWith(
      stroke: buffer.stroke.copyWith(points: points),
    );
    notifyListeners();
  }

  void _handleRealtimeDrawEnd(Map<String, dynamic> payload) {
    final strokeId =
        payload['strokeId']?.toString() ??
        _bufferKey(_pageFromPayload(payload), payload);
    final buffer = _remoteStrokeBuffer.remove(strokeId);
    if (buffer == null || !buffer.stroke.isUsable) {
      notifyListeners();
      return;
    }

    _commitPageMutation(buffer.page, (current) {
      return <WhiteboardStroke>[...current, buffer.stroke];
    });
  }

  WhiteboardPoint _normalizePoint(Offset localPosition, Size size) {
    final safeWidth = size.width <= 0 ? 1.0 : size.width;
    final safeHeight = size.height <= 0 ? 1.0 : size.height;
    final translated = Offset(
      (localPosition.dx - canvasOffset.dx) / canvasZoom,
      (localPosition.dy - canvasOffset.dy) / canvasZoom,
    );
    return WhiteboardPoint(
      dx: (translated.dx / safeWidth).clamp(0.0, 1.0),
      dy: (translated.dy / safeHeight).clamp(0.0, 1.0),
    );
  }

  Offset _denormalize(WhiteboardPoint point, Size size) {
    return Offset(
      (point.dx * size.width * canvasZoom) + canvasOffset.dx,
      (point.dy * size.height * canvasZoom) + canvasOffset.dy,
    );
  }

  WhiteboardPoint _lerpPoint(WhiteboardPoint a, WhiteboardPoint b, double t) {
    return WhiteboardPoint(
      dx: lerpDouble(a.dx, b.dx, t) ?? a.dx,
      dy: lerpDouble(a.dy, b.dy, t) ?? a.dy,
    );
  }

  double _distanceBetween(WhiteboardPoint a, WhiteboardPoint b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    return math.sqrt((dx * dx) + (dy * dy));
  }

  int _toolColor(LiveClassBoardTool tool) {
    switch (tool) {
      case LiveClassBoardTool.pen:
        return colorValue;
      case LiveClassBoardTool.highlighter:
        return const Color(0xAAFFF176).toARGB32();
      case LiveClassBoardTool.eraser:
        return const Color(0x00000000).toARGB32();
      case LiveClassBoardTool.pointer:
        return const Color(0xFFFF7043).toARGB32();
    }
  }

  double _toolWidth(LiveClassBoardTool tool) {
    switch (tool) {
      case LiveClassBoardTool.pen:
        return strokeWidth;
      case LiveClassBoardTool.highlighter:
        return math.max(strokeWidth + 6, 10);
      case LiveClassBoardTool.eraser:
        return math.max(strokeWidth + 4, 12);
      case LiveClassBoardTool.pointer:
        return 4;
    }
  }

  void _eraseAtPoint(WhiteboardPoint point) {
    final current = _pageAnnotations[currentPage] ?? const <WhiteboardStroke>[];
    if (current.isEmpty) return;
    const tolerance = 0.03;
    final filtered = current.where((stroke) {
      return stroke.points.every(
        (strokePoint) => _distanceBetween(strokePoint, point) > tolerance,
      );
    }).toList();
    if (filtered.length == current.length) return;
    _commitPageMutation(currentPage, (_) => filtered);
  }

  void _commitPageMutation(
    int page,
    List<WhiteboardStroke> Function(List<WhiteboardStroke> current) builder,
  ) {
    final before = List<WhiteboardStroke>.from(
      _pageAnnotations[page] ?? const <WhiteboardStroke>[],
    );
    _undoHistory
        .putIfAbsent(page, () => <List<WhiteboardStroke>>[])
        .add(before);
    _redoHistory[page]?.clear();
    _pageAnnotations[page] = builder(before);
    notifyListeners();
  }

  void _undoPage(int page) {
    final history = _undoHistory[page];
    if (history == null || history.isEmpty) return;
    final current = List<WhiteboardStroke>.from(
      _pageAnnotations[page] ?? const <WhiteboardStroke>[],
    );
    _redoHistory
        .putIfAbsent(page, () => <List<WhiteboardStroke>>[])
        .add(current);
    _pageAnnotations[page] = history.removeLast();
    notifyListeners();
  }

  void _redoPage(int page) {
    final history = _redoHistory[page];
    if (history == null || history.isEmpty) return;
    final current = List<WhiteboardStroke>.from(
      _pageAnnotations[page] ?? const <WhiteboardStroke>[],
    );
    _undoHistory
        .putIfAbsent(page, () => <List<WhiteboardStroke>>[])
        .add(current);
    _pageAnnotations[page] = history.removeLast();
    notifyListeners();
  }

  int _pageFromPayload(Map<String, dynamic> payload) {
    final rawPage = payload['page'];
    if (rawPage is int) return rawPage;
    return int.tryParse(rawPage?.toString() ?? '') ?? currentPage;
  }

  WhiteboardPoint? _payloadPoint(Map<String, dynamic> payload) {
    final rawX = payload['x'] ?? payload['dx'];
    final rawY = payload['y'] ?? payload['dy'];
    if (rawX is! num || rawY is! num) return null;
    return WhiteboardPoint(
      dx: rawX.toDouble().clamp(0.0, 1.0),
      dy: rawY.toDouble().clamp(0.0, 1.0),
    );
  }

  LiveClassBoardTool _toolFromWire(String? toolType) {
    switch (toolType) {
      case 'highlighter':
        return LiveClassBoardTool.highlighter;
      case 'eraser':
        return LiveClassBoardTool.eraser;
      case 'pointer':
        return LiveClassBoardTool.pointer;
      default:
        return LiveClassBoardTool.pen;
    }
  }

  String _bufferKey(int page, Map<String, dynamic> payload) {
    return '$page:${payload['userId'] ?? 'user'}:${payload['timestamp'] ?? 'now'}';
  }
}

class LiveClassLayoutController extends ChangeNotifier {
  LiveClassLayoutController({required this.role})
    : currentMode = role == LiveSessionRole.lecturer
          ? LiveClassMode.hybrid
          : LiveClassMode.presentation,
      selectedContentSource = role == LiveSessionRole.lecturer
          ? LiveClassContentSource.mixed
          : LiveClassContentSource.slides;

  final String role;

  LiveClassMode currentMode;
  LiveClassPanelTab activePanel = LiveClassPanelTab.chat;
  LiveClassContentSource selectedContentSource;
  bool isInteractionPanelOpen = true;
  bool isScreenSharingActive = false;
  bool isFullscreen = false;
  bool isSettingsOpen = false;
  bool isAIAssistantPinned = false;
  bool isAssessmentVisible = false;
  bool isSessionPaused = false;
  bool boardAccessRequested = false;
  bool studentBoardAccessGranted = false;
  String? activePresenterId;
  String? selectedParticipantId;
  final Set<String> raisedHands = <String>{};
  final Map<String, String> reactions = <String, String>{};
  LiveClassAssessmentState? activeAssessment;

  bool get isLecturer => role == LiveSessionRole.lecturer;
  bool get canUseBoard => isLecturer || studentBoardAccessGranted;

  void setMode(LiveClassMode mode) {
    currentMode = mode;
    switch (mode) {
      case LiveClassMode.video:
        selectedContentSource = LiveClassContentSource.lecturerCamera;
        break;
      case LiveClassMode.board:
        selectedContentSource = LiveClassContentSource.whiteboard;
        break;
      case LiveClassMode.presentation:
        selectedContentSource = LiveClassContentSource.slides;
        break;
      case LiveClassMode.hybrid:
        selectedContentSource = LiveClassContentSource.mixed;
        break;
      case LiveClassMode.studentPresentation:
        selectedContentSource = LiveClassContentSource.screenShare;
        break;
    }
    notifyListeners();
  }

  void setContentSource(LiveClassContentSource source) {
    selectedContentSource = source;
    notifyListeners();
  }

  void setActivePanel(LiveClassPanelTab tab) {
    activePanel = tab;
    isInteractionPanelOpen = true;
    notifyListeners();
  }

  void toggleInteractionPanel([bool? open]) {
    isInteractionPanelOpen = open ?? !isInteractionPanelOpen;
    notifyListeners();
  }

  void toggleScreenShare() {
    if (!isLecturer) return;
    isScreenSharingActive = !isScreenSharingActive;
    if (isScreenSharingActive) {
      selectedContentSource = LiveClassContentSource.screenShare;
      currentMode = LiveClassMode.presentation;
    } else if (selectedContentSource == LiveClassContentSource.screenShare) {
      selectedContentSource = LiveClassContentSource.mixed;
      currentMode = LiveClassMode.hybrid;
    }
    notifyListeners();
  }

  void toggleFullscreen() {
    isFullscreen = !isFullscreen;
    notifyListeners();
  }

  void toggleSettings() {
    isSettingsOpen = !isSettingsOpen;
    notifyListeners();
  }

  void toggleAIAssistantPinned() {
    isAIAssistantPinned = !isAIAssistantPinned;
    notifyListeners();
  }

  void toggleSessionPaused() {
    isSessionPaused = !isSessionPaused;
    notifyListeners();
  }

  void requestBoardAccess() {
    boardAccessRequested = true;
    notifyListeners();
  }

  void setStudentBoardAccess(bool granted) {
    studentBoardAccessGranted = granted;
    if (granted) {
      boardAccessRequested = false;
    }
    notifyListeners();
  }

  void setRaisedHand(String participantId, bool raised) {
    if (raised) {
      raisedHands.add(participantId);
    } else {
      raisedHands.remove(participantId);
    }
    notifyListeners();
  }

  void addReaction(String participantId, String reaction) {
    reactions[participantId] = reaction;
    notifyListeners();
  }

  void clearReaction(String participantId) {
    reactions.remove(participantId);
    notifyListeners();
  }

  void setPresenter(String? participantId) {
    activePresenterId = participantId;
    notifyListeners();
  }

  void selectParticipant(String? participantId) {
    selectedParticipantId = participantId;
    notifyListeners();
  }

  void launchAssessment({
    required LiveClassAssessmentType type,
    String? title,
    String? prompt,
  }) {
    final startedAt = DateTime.now();
    activeAssessment = LiveClassAssessmentState(
      id: '${type.name}-${startedAt.microsecondsSinceEpoch}',
      title:
          title ??
          (type == LiveClassAssessmentType.poll ? 'Live poll' : 'Quick quiz'),
      prompt:
          prompt ??
          switch (type) {
            LiveClassAssessmentType.quiz =>
              'Which tool best supports page-linked annotation recovery?',
            LiveClassAssessmentType.poll =>
              'How confident are you with today\'s topic?',
            LiveClassAssessmentType.shortAnswer =>
              'Write one key idea you want summarized after class.',
          },
      type: type,
      startedAt: startedAt,
      options: switch (type) {
        LiveClassAssessmentType.quiz => const <LiveClassAssessmentOption>[
          LiveClassAssessmentOption(id: 'a', label: 'Undo + redo stacks'),
          LiveClassAssessmentOption(id: 'b', label: 'Random canvas refresh'),
          LiveClassAssessmentOption(id: 'c', label: 'One shared stroke list'),
        ],
        LiveClassAssessmentType.poll => const <LiveClassAssessmentOption>[
          LiveClassAssessmentOption(id: 'great', label: 'Very clear'),
          LiveClassAssessmentOption(id: 'ok', label: 'Need one more example'),
          LiveClassAssessmentOption(id: 'lost', label: 'Please slow down'),
        ],
        LiveClassAssessmentType.shortAnswer =>
          const <LiveClassAssessmentOption>[],
      },
      shortAnswerHint: type == LiveClassAssessmentType.shortAnswer
          ? 'Students can answer without leaving the class workspace.'
          : null,
    );
    isAssessmentVisible = true;
    activePanel = LiveClassPanelTab.quiz;
    isInteractionPanelOpen = true;
    notifyListeners();
  }

  void submitAssessmentResponse({
    required String participantId,
    required String response,
  }) {
    final assessment = activeAssessment;
    if (assessment == null) return;
    final updatedResponses = Map<String, String>.from(assessment.responses)
      ..[participantId] = response;
    activeAssessment = assessment.copyWith(responses: updatedResponses);
    notifyListeners();
  }

  void closeAssessment() {
    isAssessmentVisible = false;
    if (activeAssessment != null) {
      activeAssessment = activeAssessment!.copyWith(isOpen: false);
    }
    notifyListeners();
  }

  void handleRealtimeEvent(LiveClassRealtimeEvent event) {
    switch (event.type) {
      case LiveClassRealtimeEventType.handRaised:
        final participantId = event.payload['participantId']?.toString();
        if (participantId == null || participantId.isEmpty) return;
        setRaisedHand(participantId, event.payload['raised'] != false);
        break;
      case LiveClassRealtimeEventType.presenterChanged:
        setPresenter(event.payload['participantId']?.toString());
        break;
      case LiveClassRealtimeEventType.quizStarted:
        launchAssessment(
          type: _assessmentTypeFromWire(event.payload['type']?.toString()),
          title: event.payload['title']?.toString(),
          prompt: event.payload['prompt']?.toString(),
        );
        break;
      case LiveClassRealtimeEventType.participantLeft:
        final participantId = event.payload['participantId']?.toString();
        if (participantId == null) return;
        raisedHands.remove(participantId);
        reactions.remove(participantId);
        if (activePresenterId == participantId) {
          activePresenterId = null;
        }
        if (selectedParticipantId == participantId) {
          selectedParticipantId = null;
        }
        notifyListeners();
        break;
      default:
        break;
    }
  }

  LiveClassAssessmentType _assessmentTypeFromWire(String? value) {
    switch (value) {
      case 'poll':
        return LiveClassAssessmentType.poll;
      case 'short_answer':
        return LiveClassAssessmentType.shortAnswer;
      default:
        return LiveClassAssessmentType.quiz;
    }
  }
}

class _RealtimeStrokeBuffer {
  const _RealtimeStrokeBuffer({required this.page, required this.stroke});

  final int page;
  final WhiteboardStroke stroke;

  _RealtimeStrokeBuffer copyWith({int? page, WhiteboardStroke? stroke}) {
    return _RealtimeStrokeBuffer(
      page: page ?? this.page,
      stroke: stroke ?? this.stroke,
    );
  }
}
