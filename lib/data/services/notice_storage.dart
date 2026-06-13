import 'package:get_storage/get_storage.dart';

import '../models/notice_model.dart';

class NoticeStorage {
  NoticeStorage._();
  static final box = GetStorage();
  static const _publishedKey = 'notice.published.items';

  static String _readKey(String id) => 'notice.read.$id';
  static String _bmKey(String id) => 'notice.bm.$id';
  static String _ackKey(String id) => 'notice.ack.$id';

  static bool isRead(String id) => box.read(_readKey(id)) ?? false;
  static bool isBookmarked(String id) => box.read(_bmKey(id)) ?? false;
  static bool isAcknowledged(String id) => box.read(_ackKey(id)) ?? false;

  static Future<void> setRead(String id, bool v) => box.write(_readKey(id), v);
  static Future<void> setBookmarked(String id, bool v) => box.write(_bmKey(id), v);
  static Future<void> setAcknowledged(String id, bool v) => box.write(_ackKey(id), v);

  static List<NoticeModel> loadPublishedNotices() {
    final raw = box.read(_publishedKey);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => NoticeModel.fromMap(Map<String, dynamic>.from(item)))
        .where((item) => item.id.trim().isNotEmpty)
        .toList();
  }

  static Future<void> savePublishedNotice(NoticeModel notice) async {
    final items = loadPublishedNotices();
    final next = [
      notice,
      ...items.where((item) => item.id != notice.id),
    ];
    await box.write(_publishedKey, next.map((item) => item.toMap()).toList());
  }

  static Future<void> archivePublishedNotice(String noticeId) async {
    final next = loadPublishedNotices()
        .map(
          (item) => item.id == noticeId
              ? item.copyWith(status: NoticeStatus.archived)
              : item,
        )
        .toList();
    await box.write(_publishedKey, next.map((item) => item.toMap()).toList());
  }
}
