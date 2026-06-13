import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class LiveScreenShareStatus {
  const LiveScreenShareStatus._();

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String denied = 'denied';
  static const String active = 'active';
  static const String stopped = 'stopped';
}

class LiveScreenShareRequest {
  const LiveScreenShareRequest({
    required this.id,
    required this.sessionId,
    required this.participantId,
    required this.studentName,
    required this.registrationNumber,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.startedAt,
    this.stoppedAt,
  });

  final String id;
  final String sessionId;
  final String participantId;
  final String studentName;
  final String registrationNumber;
  final String reason;
  final String status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? startedAt;
  final DateTime? stoppedAt;

  bool get isPending => status == LiveScreenShareStatus.pending;
  bool get isApproved => status == LiveScreenShareStatus.approved;
  bool get isActive => status == LiveScreenShareStatus.active;
  bool get isDenied => status == LiveScreenShareStatus.denied;
  bool get isStopped => status == LiveScreenShareStatus.stopped;
  bool get canStart => isApproved || isActive;

  LiveScreenShareRequest copyWith({
    String? id,
    String? sessionId,
    String? participantId,
    String? studentName,
    String? registrationNumber,
    String? reason,
    String? status,
    DateTime? requestedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? startedAt,
    DateTime? stoppedAt,
  }) {
    return LiveScreenShareRequest(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      participantId: participantId ?? this.participantId,
      studentName: studentName ?? this.studentName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'participantId': participantId,
    'studentName': studentName,
    'registrationNumber': registrationNumber,
    'reason': reason,
    'status': status,
    'requestedAt': requestedAt.toIso8601String(),
    'reviewedBy': reviewedBy,
    'reviewedAt': reviewedAt?.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'stoppedAt': stoppedAt?.toIso8601String(),
  };

  factory LiveScreenShareRequest.fromJson(Map<String, dynamic> json) {
    return LiveScreenShareRequest(
      id: json['id']?.toString() ?? LiveScreenShareControlService.newId(),
      sessionId: json['sessionId']?.toString() ?? '',
      participantId: json['participantId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? 'Student',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? LiveScreenShareStatus.pending,
      requestedAt:
          DateTime.tryParse(json['requestedAt']?.toString() ?? '') ?? DateTime.now(),
      reviewedBy: _nullable(json['reviewedBy']),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? ''),
      stoppedAt: DateTime.tryParse(json['stoppedAt']?.toString() ?? ''),
    );
  }

  static String? _nullable(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class LiveScreenShareControlService {
  LiveScreenShareControlService._();

  static final GetStorage _box = GetStorage();
  static final Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();

  static String _key(String sessionId) =>
      'live.screenShare.requests.${sessionId.trim()}';

  static List<LiveScreenShareRequest> loadRequests(String sessionId) {
    final raw = _box.read<List>(_key(sessionId)) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((item) => LiveScreenShareRequest.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.sessionId == sessionId)
        .toList();
    items.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return items;
  }

  static LiveScreenShareRequest? latestForParticipant({
    required String sessionId,
    required String participantId,
  }) {
    for (final item in loadRequests(sessionId)) {
      if (item.participantId == participantId && !item.isStopped) {
        return item;
      }
    }
    return null;
  }

  static List<LiveScreenShareRequest> pendingRequests(String sessionId) {
    return loadRequests(sessionId).where((item) => item.isPending).toList();
  }

  static List<LiveScreenShareRequest> activeRequests(String sessionId) {
    return loadRequests(sessionId).where((item) => item.isActive).toList();
  }

  static Future<LiveScreenShareRequest> requestShare({
    required String sessionId,
    required String participantId,
    required String studentName,
    required String registrationNumber,
    String reason = 'Student wants to share screen during live class.',
  }) async {
    final existing = latestForParticipant(
      sessionId: sessionId,
      participantId: participantId,
    );
    if (existing != null && (existing.isPending || existing.isApproved || existing.isActive)) {
      return existing;
    }

    final request = LiveScreenShareRequest(
      id: _uuid.v4(),
      sessionId: sessionId,
      participantId: participantId,
      studentName: studentName,
      registrationNumber: registrationNumber,
      reason: reason.trim().isEmpty
          ? 'Student wants to share screen during live class.'
          : reason.trim(),
      status: LiveScreenShareStatus.pending,
      requestedAt: DateTime.now(),
    );
    await _upsert(request);
    return request;
  }

  static Future<LiveScreenShareRequest?> approve({
    required String sessionId,
    required String requestId,
    required String lecturerName,
  }) async {
    final request = _find(sessionId, requestId);
    if (request == null) return null;
    final updated = request.copyWith(
      status: LiveScreenShareStatus.approved,
      reviewedBy: lecturerName,
      reviewedAt: DateTime.now(),
    );
    await _upsert(updated);
    return updated;
  }

  static Future<LiveScreenShareRequest?> deny({
    required String sessionId,
    required String requestId,
    required String lecturerName,
  }) async {
    final request = _find(sessionId, requestId);
    if (request == null) return null;
    final updated = request.copyWith(
      status: LiveScreenShareStatus.denied,
      reviewedBy: lecturerName,
      reviewedAt: DateTime.now(),
      stoppedAt: DateTime.now(),
    );
    await _upsert(updated);
    return updated;
  }

  static Future<LiveScreenShareRequest?> markStarted({
    required String sessionId,
    required String participantId,
  }) async {
    final request = latestForParticipant(
      sessionId: sessionId,
      participantId: participantId,
    );
    if (request == null) return null;
    final updated = request.copyWith(
      status: LiveScreenShareStatus.active,
      startedAt: DateTime.now(),
    );
    await _upsert(updated);
    return updated;
  }

  static Future<LiveScreenShareRequest?> stop({
    required String sessionId,
    required String participantId,
    String? stoppedBy,
  }) async {
    final request = latestForParticipant(
      sessionId: sessionId,
      participantId: participantId,
    );
    if (request == null) return null;
    final updated = request.copyWith(
      status: LiveScreenShareStatus.stopped,
      reviewedBy: stoppedBy ?? request.reviewedBy,
      stoppedAt: DateTime.now(),
    );
    await _upsert(updated);
    return updated;
  }

  static LiveScreenShareRequest? _find(String sessionId, String requestId) {
    for (final item in loadRequests(sessionId)) {
      if (item.id == requestId) return item;
    }
    return null;
  }

  static Future<void> _upsert(LiveScreenShareRequest request) async {
    final items = loadRequests(request.sessionId);
    final index = items.indexWhere((item) => item.id == request.id);
    if (index >= 0) {
      items[index] = request;
    } else {
      items.insert(0, request);
    }
    await _write(request.sessionId, items);
  }

  static Future<void> _write(
    String sessionId,
    List<LiveScreenShareRequest> items,
  ) async {
    items.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    await _box.write(_key(sessionId), items.map((item) => item.toJson()).toList());
  }
}
