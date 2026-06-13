import 'package:get_storage/get_storage.dart';

class LiveClassStudentNotesService {
  LiveClassStudentNotesService._();

  static final GetStorage _box = GetStorage();

  static String _key(String sessionId) => 'student.live.class.notes.${sessionId.trim()}';

  static String load(String sessionId) {
    return _box.read<String>(_key(sessionId)) ?? '';
  }

  static Future<void> save({
    required String sessionId,
    required String note,
  }) {
    return _box.write(_key(sessionId), note);
  }
}
