import 'dart:async';

import 'package:get/get.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_session_backend_service.dart';
import '../../../data/services/live_session_media_service.dart';
import '../../../data/services/live_session_remote_backend_service.dart';
import '../../../data/services/live_session_runtime_mode_service.dart';

class LiveSessionsController extends GetxController {
  LiveSessionsController({
    LiveSessionBackendGateway? gateway,
    LiveSessionMediaService? mediaService,
  }) : _gateway = gateway ?? LocalLiveSessionBackendGateway.instance,
       _mediaService = mediaService ?? LiveSessionMediaService();

  final LiveSessionBackendGateway _gateway;
  final LiveSessionMediaService _mediaService;

  final sessions = <LiveSessionModel>[].obs;
  final room = Rxn<LiveSessionRoomState>();
  final rtcRoom = Rxn<lk.Room>();
  final isLoadingSessions = false.obs;
  final isLoadingRoom = false.obs;
  final isConnectingMedia = false.obs;
  final activeSessionId = RxnString();
  final activeRole = LiveSessionRole.student.obs;
  final activeParticipantId = RxnString();
  final lastDisplayName = RxnString();
  final lastRegistrationNumber = RxnString();
  final catalogError = RxnString();
  final mediaError = RxnString();
  final runtimeMode = LiveSessionRuntimeModeStore.load().obs;

  List<LiveSessionBackendPath> get backendContract => _gateway.backendContract;
  LiveSessionRuntimeMode get currentRuntimeMode => runtimeMode.value;
  bool get isProductionSelected =>
      currentRuntimeMode == LiveSessionRuntimeMode.production;
  bool get isMediaConfigured => _mediaService.isConfigured;
  String? get mediaConfigurationNotice => _mediaService.configurationNotice;
  bool get isDemoBackend {
    if (_gateway is LocalLiveSessionBackendGateway) {
      return true;
    }
    final remoteGateway = _gateway;
    return remoteGateway is RemoteLiveSessionBackendGateway &&
        !remoteGateway.isConfigured;
  }

  bool get isDemoMedia => _mediaService.isDemoMode;
  bool get isDemoMode => isDemoBackend || isDemoMedia;
  String get backendProviderLabel => !isProductionSelected
      ? 'Demo classroom API'
      : isDemoBackend
      ? 'Go live-class API (demo fallback)'
      : 'Go live-class API';
  String get mediaProviderLabel => _mediaService.stackLabel;
  String? get demoModeNotice => isDemoMode
      ? isProductionSelected
            ? 'Production mode is selected, but the Go live-class services are not fully configured yet. Demo fallback stays active so the classroom remains usable.'
            : 'Demo mode is active so the school can preview the full classroom workspace without waiting for production infrastructure.'
      : null;

  @override
  void onInit() {
    super.onInit();
    loadSessions();
  }

  @override
  void onClose() {
    unawaited(disconnectMediaRoom(clearError: false));
    super.onClose();
  }

  Future<void> loadSessions({String? courseCode}) async {
    isLoadingSessions.value = true;
    try {
      final items = await _gateway.fetchSessions(courseCode: courseCode);
      sessions.assignAll(items);
      catalogError.value = null;
    } catch (error) {
      sessions.clear();
      catalogError.value = error.toString();
    } finally {
      isLoadingSessions.value = false;
    }
  }

  List<LiveSessionModel> sessionsForCourse(String courseCode) {
    final code = courseCode.trim().toUpperCase();
    final items = sessions
        .where((session) => session.courseCode.toUpperCase() == code)
        .toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  LiveSessionModel? primarySessionForCourse(String courseCode) {
    final items = sessionsForCourse(courseCode);
    if (items.isEmpty) return null;

    final now = DateTime.now();
    items.sort((a, b) {
      final aWeight = a.isLiveAt(now) ? 0 : (a.isUpcomingAt(now) ? 1 : 2);
      final bWeight = b.isLiveAt(now) ? 0 : (b.isUpcomingAt(now) ? 1 : 2);
      if (aWeight != bWeight) return aWeight.compareTo(bWeight);
      return aWeight == 2
          ? b.startTime.compareTo(a.startTime)
          : a.startTime.compareTo(b.startTime);
    });
    return items.first;
  }

  Future<void> openStudentRoom({
    required String sessionId,
    required String displayName,
    required String registrationNumber,
  }) async {
    activeSessionId.value = sessionId;
    activeRole.value = LiveSessionRole.student;
    lastDisplayName.value = displayName;
    lastRegistrationNumber.value = registrationNumber;
    isLoadingRoom.value = true;
    try {
      final updatedRoom = await _gateway.joinAsStudent(
        sessionId: sessionId,
        displayName: displayName,
        registrationNumber: registrationNumber,
      );
      room.value = updatedRoom;
      activeParticipantId.value = 'student-${registrationNumber.toLowerCase()}';
      await _connectMediaRoom(
        liveRoom: updatedRoom,
        participantId: activeParticipantId.value!,
        userId: registrationNumber,
        displayName: displayName,
        registrationNumber: registrationNumber,
      );
      await loadSessions();
    } finally {
      isLoadingRoom.value = false;
    }
  }

  Future<void> openLecturerRoom({
    required String sessionId,
    required String lecturerName,
  }) async {
    activeSessionId.value = sessionId;
    activeRole.value = LiveSessionRole.lecturer;
    lastDisplayName.value = lecturerName;
    lastRegistrationNumber.value = null;
    isLoadingRoom.value = true;
    try {
      final updatedRoom = await _gateway.joinAsLecturer(
        sessionId: sessionId,
        lecturerName: lecturerName,
      );
      room.value = updatedRoom;
      activeParticipantId.value = 'lecturer-${sessionId.toLowerCase()}';
      await _connectMediaRoom(
        liveRoom: updatedRoom,
        participantId: activeParticipantId.value!,
        userId: activeParticipantId.value!,
        displayName: lecturerName,
      );
      await loadSessions();
    } finally {
      isLoadingRoom.value = false;
    }
  }

  Future<void> refreshRoom() async {
    final sessionId = activeSessionId.value;
    if (sessionId == null) return;
    room.value = await _gateway.fetchRoom(sessionId);
  }

  Future<LiveSessionRoomState> gatewayRoomPreview(String sessionId) {
    return _gateway.fetchRoom(sessionId);
  }

  Future<void> setRuntimeMode(LiveSessionRuntimeMode mode) async {
    if (runtimeMode.value == mode) return;

    await LiveSessionRuntimeModeStore.save(mode);
    runtimeMode.value = mode;
    mediaError.value = null;
    catalogError.value = null;

    final sessionId = activeSessionId.value;
    final role = activeRole.value;
    final displayName = lastDisplayName.value;
    final registrationNumber = lastRegistrationNumber.value;

    await disconnectMediaRoom();
    room.value = null;

    if (sessionId == null) {
      await loadSessions();
      return;
    }

    if (role == LiveSessionRole.lecturer && displayName != null) {
      await openLecturerRoom(sessionId: sessionId, lecturerName: displayName);
      return;
    }

    if (displayName != null && registrationNumber != null) {
      await openStudentRoom(
        sessionId: sessionId,
        displayName: displayName,
        registrationNumber: registrationNumber,
      );
      return;
    }

    room.value = await _gateway.fetchRoom(sessionId);
    await loadSessions();
  }

  Future<void> saveSession(LiveSessionModel session) async {
    await _gateway.saveSession(session);
    await loadSessions();
    if (activeSessionId.value == session.id) {
      room.value = await _gateway.fetchRoom(session.id);
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _gateway.deleteSession(sessionId);
    if (activeSessionId.value == sessionId) {
      await disconnectMediaRoom();
      room.value = null;
      activeSessionId.value = null;
      activeParticipantId.value = null;
    }
    await loadSessions();
  }

  Future<void> toggleCamera(bool enabled) async {
    final sessionId = activeSessionId.value;
    final participantId = activeParticipantId.value;
    if (sessionId == null || participantId == null) return;
    await _mediaService.setCameraEnabled(rtcRoom.value, enabled);
    room.value = await _gateway.setCameraState(
      sessionId: sessionId,
      participantId: participantId,
      enabled: enabled,
    );
  }

  Future<void> toggleMicrophone(bool enabled) async {
    final sessionId = activeSessionId.value;
    final participantId = activeParticipantId.value;
    if (sessionId == null || participantId == null) return;
    await _mediaService.setMicrophoneEnabled(rtcRoom.value, enabled);
    room.value = await _gateway.setMicrophoneState(
      sessionId: sessionId,
      participantId: participantId,
      enabled: enabled,
    );
  }

  Future<void> toggleRecording(bool enabled) async {
    final sessionId = activeSessionId.value;
    final participantId = activeParticipantId.value;
    if (sessionId == null || participantId == null) return;
    room.value = await _gateway.setRecordingState(
      sessionId: sessionId,
      participantId: participantId,
      enabled: enabled,
    );
  }

  Future<void> sendChat({
    required String senderName,
    required String senderRole,
    required String message,
    String? registrationNumber,
  }) async {
    final sessionId = activeSessionId.value;
    if (sessionId == null || message.trim().isEmpty) return;
    room.value = await _gateway.sendChat(
      sessionId: sessionId,
      senderName: senderName,
      senderRole: senderRole,
      message: message,
      registrationNumber: registrationNumber,
    );
  }

  Future<void> askQuestion({
    required String askedByName,
    required String question,
    String? registrationNumber,
  }) async {
    final sessionId = activeSessionId.value;
    if (sessionId == null || question.trim().isEmpty) return;
    room.value = await _gateway.askQuestion(
      sessionId: sessionId,
      askedByName: askedByName,
      question: question,
      registrationNumber: registrationNumber,
    );
  }

  Future<void> answerQuestion({
    required String questionId,
    required String answeredByName,
    required String answer,
  }) async {
    final sessionId = activeSessionId.value;
    if (sessionId == null || answer.trim().isEmpty) return;
    room.value = await _gateway.answerQuestion(
      sessionId: sessionId,
      questionId: questionId,
      answeredByName: answeredByName,
      answer: answer,
    );
  }

  Future<void> disconnectMediaRoom({bool clearError = true}) async {
    final currentRoom = rtcRoom.value;
    rtcRoom.value = null;
    isConnectingMedia.value = false;
    if (clearError) {
      mediaError.value = null;
    }
    await _mediaService.disconnect(currentRoom);
  }

  lk.Participant? mediaParticipantFor(String participantId) {
    final mediaRoom = rtcRoom.value;
    if (mediaRoom == null) return null;

    final local = mediaRoom.localParticipant;
    if (local != null &&
        (local.identity == participantId ||
            participantId == activeParticipantId.value)) {
      return local;
    }

    for (final participant in mediaRoom.remoteParticipants.values) {
      if (participant.identity == participantId) {
        return participant;
      }
    }
    return null;
  }

  Future<void> _connectMediaRoom({
    required LiveSessionRoomState liveRoom,
    required String participantId,
    required String userId,
    required String displayName,
    String? registrationNumber,
  }) async {
    await disconnectMediaRoom();

    if (!liveRoom.session.isLiveAt(DateTime.now())) {
      mediaError.value = null;
      return;
    }

    if (!_mediaService.isConfigured) {
      mediaError.value = null;
      return;
    }

    final participant = liveRoom.participants.firstWhereOrNull(
      (item) => item.id == participantId,
    );
    final role = participant?.role ?? activeRole.value;

    isConnectingMedia.value = true;
    mediaError.value = null;
    try {
      final connection = await _mediaService.connect(
        sessionId: liveRoom.session.id,
        participantId: participantId,
        userId: userId,
        role: role,
        displayName: displayName,
        registrationNumber: registrationNumber,
        enableCamera: participant?.cameraEnabled ?? false,
        enableMicrophone: participant?.micEnabled ?? false,
      );
      if (connection == null) {
        mediaError.value = _mediaService.configurationNotice;
        return;
      }
      rtcRoom.value = connection.room;
    } catch (error) {
      mediaError.value = error.toString();
    } finally {
      isConnectingMedia.value = false;
    }
  }
}
