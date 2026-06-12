import 'package:get_storage/get_storage.dart';

class NoticeStorage {
  NoticeStorage._();
  static final box = GetStorage();

  static String _readKey(String id) => "notice.read.$id";
  static String _bmKey(String id) => "notice.bm.$id";

  static bool isRead(String id) => box.read(_readKey(id)) ?? false;
  static bool isBookmarked(String id) => box.read(_bmKey(id)) ?? false;

  static Future<void> setRead(String id, bool v) => box.write(_readKey(id), v);
  static Future<void> setBookmarked(String id, bool v) =>
      box.write(_bmKey(id), v);
}
