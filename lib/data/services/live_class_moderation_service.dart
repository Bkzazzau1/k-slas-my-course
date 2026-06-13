import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class LiveClassModerationAction {
  const LiveClassModerationAction._();

  static const String muteMicrophone = 'mute_microphone';
  static const String disableCamera = 'disable_camera';
  static const String removeParticipant = 'remove_participant';
}

class LiveClassModerationCommand {
  const LiveClassModerationCommand({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.participantName,
    required this.action,
    required this.issuedBy,
    required this.issuedAt,
    this.reason,
    this.appliedAt,
  });

  final String id;
  final String sessionId;
  final String participantId;
  final String participantName;
  final String action;
  final String issuedBy;
  final DateTime issuedAt;
  final String? reason;
  final DateTime? appliedAt;

  bool get isApplied => appliedAt != null;

  String get label {
    return switch (action) {
      LiveClassModerationAction.muteMicrophone => 'Mute microphone',
      LiveClassModerationAction.disableCamera => 'Turn camera off',
      LiveClassModerationAction.removeParticipant => 'Remove from class',
      _ => 'Moderation command',
    };
  }

  LiveClassModerationCommand copyWith({
    String? id,
    String? sessionId,
    String? participantId,
    String? participantName,
    String? action,
    String? issuedBy,
    DateTime? issuedAt,
    String? reason,
    DateTime? appliedAt,
  }) {
    return LiveClassModerationCommand(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      action: action ?? this.action,
      issuedBy: issuedBy ?? this.issuedBy,
      issuedAt: issuedAt ?? this.issuedAt,
      reason: reason ?? this.reason,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'participantId': participantId,
    'participantName': participantName,
    'action': action,
    'issuedBy': issuedBy,
    'issuedAt': issuedAt.toIso8601String(),
    'reason': reason,
    'appliedAt': appliedAt?.toIso8601String(),
  };

  factory LiveClassModerationCommand.fromJson(Map<String, dynamic> json) {
    return LiveClassModerationCommand(
      id: json['id']?.toString() ?? LiveClassModerationService.newId(),
      sessionId: json['sessionId']?.toString() ?? '',
      participantId: json['participantId']?.toString() ?? '',
      participantName: json['participantName']?.toString() ?? 'Participant',
      action: json['action']?.toString() ?? '',
      issuedBy: json['issuedBy']?.toString() ?? 'Lecturer',
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? '') ?? DateTime.now(),
      reason: _nullable(json['reason']),
      appliedAt: DateTime.tryParse(json['appliedAt']?.toString() ?? ''),
    );
  }

  static String? _nullable(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class LiveClassModerationService {
  LiveClassModerationService._();

  static final GetStorage _box = GetStorage();
  static final Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
  static String _key(String sessionId) =>
      'live.classroom.moderation.commands.${sessionId.trim()}';

  static List<LiveClassModerationCommand> loadCommands(String sessionId) {
    final raw = _box.read<List>(_key(sessionId)) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((item) => LiveClassModerationCommand.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.sessionId == sessionId)
        .toList();
    items.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return items;
  }

  static List<LiveClassModerationCommand> pendingForParticipant({
    required String sessionId,
    required String participantId,
  }) {
    return loadCommands(sessionId)
        .where((item) => item.participantId == participantId && !item.isApplied)
        .toList();
  }

  static Future<LiveClassModerationCommand> issueCommand({
    required String sessionId,
    required String participantId,
    required String participantName,
    required String action,
    required String issuedBy,
    String? reason,
  }) async {
    final command = LiveClassModerationCommand(
      id: _uuid.v4(),
      sessionId: sessionId,
      participantId: participantId,
      participantName: participantName,
      action: action,
      issuedBy: issuedBy,
      issuedAt: DateTime.now(),
      reason: reason,
    );
    final commands = loadCommands(sessionId)..insert(0, command);
    await _write(sessionId, commands);
    return command;
  }

  static Future<void> markApplied({
    required String sessionId,
    required String commandId,
  }) async {
    final commands = loadCommands(sessionId);
    final index = commands.indexWhere((item) => item.id == commandId);
    if (index < 0) return;
    commands[index] = commands[index].copyWith(appliedAt: DateTime.now());
    await _write(sessionId, commands);
  }

  static Future<void> _write(
    String sessionId,
    List<LiveClassModerationCommand> commands,
  ) async {
    commands.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    await _box.write(_key(sessionId), commands.map((item) => item.toJson()).toList());
  }
}
