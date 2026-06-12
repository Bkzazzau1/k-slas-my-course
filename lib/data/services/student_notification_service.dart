import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class StudentNotificationRecord {
  const StudentNotificationRecord({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.read,
    this.route,
  });

  final String id;
  final String title;
  final String message;
  final String category;
  final DateTime createdAt;
  final bool read;
  final String? route;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
        'route': route,
      };

  StudentNotificationRecord copyWith({bool? read}) {
    return StudentNotificationRecord(
      id: id,
      title: title,
      message: message,
      category: category,
      createdAt: createdAt,
      read: read ?? this.read,
      route: route,
    );
  }

  static StudentNotificationRecord fromJson(Map<String, dynamic> json) {
    return StudentNotificationRecord(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      read: json['read'] == true,
      route: json['route']?.toString(),
    );
  }
}

class StudentNotificationService {
  StudentNotificationService._();

  static final GetStorage _box = GetStorage();
  static const String _key = 'student.notifications';
  static const int _maxItems = 80;

  static List<StudentNotificationRecord> load() {
    final raw = _box.read(_key);
    if (raw == null) {
      final seeded = _seed();
      _write(seeded);
      return seeded;
    }
    try {
      final list = jsonDecode(raw as String) as List;
      final records = list
          .whereType<Map>()
          .map((item) => StudentNotificationRecord.fromJson(item.cast<String, dynamic>()))
          .toList();
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return records;
    } catch (_) {
      return const [];
    }
  }

  static int unreadCount() => load().where((item) => !item.read).length;

  static Future<void> add({
    required String title,
    required String message,
    required String category,
    String? route,
  }) async {
    final now = DateTime.now();
    final record = StudentNotificationRecord(
      id: 'notif-${now.microsecondsSinceEpoch}',
      title: title,
      message: message,
      category: category,
      createdAt: now,
      read: false,
      route: route,
    );
    final list = load().where((item) => item.id != record.id).toList();
    list.insert(0, record);
    await _write(list.take(_maxItems).toList());
  }

  static Future<void> markRead(String id) async {
    final list = load().map((item) => item.id == id ? item.copyWith(read: true) : item).toList();
    await _write(list);
  }

  static Future<void> markAllRead() async {
    final list = load().map((item) => item.copyWith(read: true)).toList();
    await _write(list);
  }

  static Future<void> clearAll() async {
    await _write(const []);
  }

  static Future<void> _write(List<StudentNotificationRecord> records) async {
    await _box.write(_key, jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  static List<StudentNotificationRecord> _seed() {
    final now = DateTime.now();
    return [
      StudentNotificationRecord(
        id: 'welcome-notification',
        title: 'Welcome to K-SLAS',
        message: 'Your student dashboard is ready. Check exams, assessments, live classes, and receipts from one place.',
        category: 'General',
        createdAt: now,
        read: false,
        route: '/',
      ),
      StudentNotificationRecord(
        id: 'offline-center-tip',
        title: 'Offline recovery enabled',
        message: 'Saved drafts and pending sync items will appear in Submission & Offline Center.',
        category: 'Offline',
        createdAt: now.subtract(const Duration(minutes: 2)),
        read: false,
        route: '/results',
      ),
    ];
  }
}
