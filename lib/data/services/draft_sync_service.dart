import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class OfflineDraftRecord {
  const OfflineDraftRecord({
    required this.key,
    required this.courseCode,
    required this.title,
    required this.sessionType,
    required this.gradingType,
    required this.answered,
    required this.total,
    required this.secondsLeft,
    required this.savedAt,
  });

  final String key;
  final String courseCode;
  final String title;
  final String sessionType;
  final String gradingType;
  final int answered;
  final int total;
  final int secondsLeft;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'key': key,
        'courseCode': courseCode,
        'title': title,
        'sessionType': sessionType,
        'gradingType': gradingType,
        'answered': answered,
        'total': total,
        'secondsLeft': secondsLeft,
        'savedAt': savedAt.toIso8601String(),
      };

  static OfflineDraftRecord fromJson(Map<String, dynamic> json) {
    return OfflineDraftRecord(
      key: json['key']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? 'UNKNOWN',
      title: json['title']?.toString() ?? 'Saved draft',
      sessionType: json['sessionType']?.toString() ?? 'ASSESSMENT',
      gradingType: json['gradingType']?.toString() ?? 'UNGRADED',
      answered: _asInt(json['answered']),
      total: _asInt(json['total']),
      secondsLeft: _asInt(json['secondsLeft']),
      savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class PendingSyncRecord {
  const PendingSyncRecord({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String courseCode;
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'courseCode': courseCode,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };

  static PendingSyncRecord fromJson(Map<String, dynamic> json) {
    return PendingSyncRecord(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Pending sync',
      courseCode: json['courseCode']?.toString() ?? 'UNKNOWN',
      status: json['status']?.toString() ?? 'Waiting for network',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class DraftSyncService {
  DraftSyncService._();

  static final GetStorage _box = GetStorage();
  static const String _draftRegistryKey = 'student.offline.draft.registry';
  static const String _pendingSyncKey = 'student.pending.sync.registry';

  static List<OfflineDraftRecord> loadDrafts() {
    final raw = _box.read(_draftRegistryKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw as String) as List;
      final records = list
          .whereType<Map>()
          .map((item) => OfflineDraftRecord.fromJson(item.cast<String, dynamic>()))
          .toList();
      records.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> upsertDraft(OfflineDraftRecord record) async {
    final list = loadDrafts().where((item) => item.key != record.key).toList();
    list.insert(0, record);
    await _box.write(_draftRegistryKey, jsonEncode(list.take(50).map((e) => e.toJson()).toList()));
  }

  static Future<void> removeDraft(String key) async {
    final list = loadDrafts().where((item) => item.key != key).toList();
    await _box.write(_draftRegistryKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static List<PendingSyncRecord> loadPendingSync() {
    final raw = _box.read(_pendingSyncKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw as String) as List;
      final records = list
          .whereType<Map>()
          .map((item) => PendingSyncRecord.fromJson(item.cast<String, dynamic>()))
          .toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> upsertPendingSync(PendingSyncRecord record) async {
    final list = loadPendingSync().where((item) => item.id != record.id).toList();
    list.insert(0, record);
    await _box.write(_pendingSyncKey, jsonEncode(list.take(50).map((e) => e.toJson()).toList()));
  }

  static Future<void> removePendingSync(String id) async {
    final list = loadPendingSync().where((item) => item.id != id).toList();
    await _box.write(_pendingSyncKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }
}
