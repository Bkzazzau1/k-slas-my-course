import 'dart:async';
import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart' as lk;

import 'live_session_runtime_mode_service.dart';

class LiveSessionMediaConfig {
  const LiveSessionMediaConfig({
    required this.apiBaseUrl,
    required this.liveKitWsUrl,
  });

  static const String _kApiBaseUrl = 'liveSessions.apiBaseUrl';
  static const String _kLiveKitWsUrl = 'liveSessions.liveKitWsUrl';
  static const String _kGoApiBaseEnv = 'LIVE_SESSION_GO_API_BASE_URL';
  static const String _kGoLiveKitWsEnv = 'LIVE_SESSION_GO_LIVEKIT_WS_URL';
  static const String _kApiBaseEnv = 'LIVE_SESSION_API_BASE_URL';
  static const String _kLiveKitWsEnv = 'LIVEKIT_WS_URL';

  final String apiBaseUrl;
  final String liveKitWsUrl;

  bool get isConfigured => apiBaseUrl.isNotEmpty && liveKitWsUrl.isNotEmpty;

  factory LiveSessionMediaConfig.fromRuntime() {
    final box = GetStorage();
    final storedApiBaseUrl = box.read(_kApiBaseUrl)?.toString().trim() ?? '';
    final storedLiveKitWsUrl =
        box.read(_kLiveKitWsUrl)?.toString().trim() ?? '';

    final apiBaseUrl = storedApiBaseUrl.isNotEmpty
        ? storedApiBaseUrl
        : const String.fromEnvironment(_kGoApiBaseEnv).trim().isNotEmpty
        ? const String.fromEnvironment(_kGoApiBaseEnv).trim()
        : const String.fromEnvironment(_kApiBaseEnv).trim();
    final liveKitWsUrl = storedLiveKitWsUrl.isNotEmpty
        ? storedLiveKitWsUrl
        : const String.fromEnvironment(_kGoLiveKitWsEnv).trim().isNotEmpty
        ? const String.fromEnvironment(_kGoLiveKitWsEnv).trim()
        : const String.fromEnvironment(_kLiveKitWsEnv).trim();

    return LiveSessionMediaConfig(
      apiBaseUrl: apiBaseUrl,
      liveKitWsUrl: liveKitWsUrl,
    );
  }

  static Future<void> saveOverrides({
    String? apiBaseUrl,
    String? liveKitWsUrl,
  }) async {
    final box = GetStorage();

    if (apiBaseUrl != null) {
      final value = apiBaseUrl.trim();
      if (value.isEmpty) {
        await box.remove(_kApiBaseUrl);
      } else {
        await box.write(_kApiBaseUrl, value);
      }
    }

    if (liveKitWsUrl != null) {
      final value = liveKitWsUrl.trim();
      if (value.isEmpty) {
        await box.remove(_kLiveKitWsUrl);
      } else {
        await box.write(_kLiveKitWsUrl, value);
      }
    }
  }
}

class LiveSessionTokenResponse {
  const LiveSessionTokenResponse({
    required this.sessionId,
    required this.participantId,
    required this.participantIdentity,
    required this.roomName,
    required this.accessToken,
  });

  final String sessionId;
  final String participantId;
  final String participantIdentity;
  final String roomName;
  final String accessToken;

  factory LiveSessionTokenResponse.fromJson(Map<String, dynamic> json) {
    return LiveSessionTokenResponse(
      sessionId: json['sessionId']?.toString() ?? '',
      participantId: json['participantId']?.toString() ?? '',
      participantIdentity:
          json['participantIdentity']?.toString() ??
          json['participantId']?.toString() ??
          '',
      roomName: json['roomName']?.toString() ?? '',
      accessToken: json['accessToken']?.toString() ?? '',
    );
  }
}

class LiveSessionMediaConnection {
  const LiveSessionMediaConnection({required this.room, required this.token});

  final lk.Room room;
  final LiveSessionTokenResponse token;
}

class LiveSessionMediaService {
  LiveSessionMediaService({http.Client? client, LiveSessionMediaConfig? config})
    : _client = client ?? http.Client(),
      _config = config ?? LiveSessionMediaConfig.fromRuntime();

  final http.Client _client;
  final LiveSessionMediaConfig _config;

  LiveSessionMediaConfig get config => _config;

  LiveSessionRuntimeMode get runtimeMode => LiveSessionRuntimeModeStore.load();
  bool get wantsProduction => runtimeMode == LiveSessionRuntimeMode.production;
  bool get isConfigured => wantsProduction && _config.isConfigured;

  bool get isDemoMode => !wantsProduction || !_config.isConfigured;

  String get stackLabel {
    if (!wantsProduction) return 'Demo media stage';
    if (isConfigured) return 'Go media gateway + LiveKit';
    return 'Go media gateway (demo fallback)';
  }

  String? get configurationNotice {
    if (!wantsProduction) {
      return 'Demo mode is active. Switch to Production when the Go media service is ready.';
    }
    if (isConfigured) return null;
    return 'Production mode is selected. Configure LIVE_SESSION_GO_API_BASE_URL and LIVE_SESSION_GO_LIVEKIT_WS_URL to enable the Go media service.';
  }

  Future<LiveSessionMediaConnection?> connect({
    required String sessionId,
    required String participantId,
    required String userId,
    required String role,
    required String displayName,
    String? registrationNumber,
    required bool enableCamera,
    required bool enableMicrophone,
  }) async {
    if (!isConfigured) return null;

    final token = await _fetchToken(
      sessionId: sessionId,
      participantId: participantId,
      userId: userId,
      role: role,
      displayName: displayName,
      registrationNumber: registrationNumber,
    );

    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );

    await room.prepareConnection(_config.liveKitWsUrl, token.accessToken);
    await room.connect(_config.liveKitWsUrl, token.accessToken);

    if (enableCamera) {
      await room.localParticipant?.setCameraEnabled(true);
    }
    if (enableMicrophone) {
      await room.localParticipant?.setMicrophoneEnabled(true);
    }

    return LiveSessionMediaConnection(room: room, token: token);
  }

  Future<void> disconnect(lk.Room? room) async {
    if (room == null) return;
    await room.disconnect();
    await room.dispose();
  }

  Future<void> setCameraEnabled(lk.Room? room, bool enabled) async {
    await room?.localParticipant?.setCameraEnabled(enabled);
  }

  Future<void> setMicrophoneEnabled(lk.Room? room, bool enabled) async {
    await room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> setScreenShareEnabled(lk.Room? room, bool enabled) async {
    await room?.localParticipant?.setScreenShareEnabled(enabled);
  }

  Future<LiveSessionTokenResponse> _fetchToken({
    required String sessionId,
    required String participantId,
    required String userId,
    required String role,
    required String displayName,
    String? registrationNumber,
  }) async {
    final uri = Uri.parse(
      '${_config.apiBaseUrl.replaceFirst(RegExp(r'/$'), '')}/api/v1/live-sessions/tokens',
    );

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': sessionId,
        'participantId': participantId,
        'userId': userId,
        'role': role,
        'displayName': displayName,
        'registrationNumber': registrationNumber,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Live session token request failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Live session token response is invalid.');
    }

    final token = LiveSessionTokenResponse.fromJson(json);
    if (token.accessToken.trim().isEmpty) {
      throw const FormatException(
        'Live session token response is missing accessToken.',
      );
    }

    return token;
  }
}
