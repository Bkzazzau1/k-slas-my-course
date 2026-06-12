import 'package:get_storage/get_storage.dart';

import '../models/assignment_model.dart';

class AssignmentGroupChatStorage {
  AssignmentGroupChatStorage._();

  static final _box = GetStorage();

  static String _chatKey({
    required String assignmentId,
    required String groupId,
  }) => 'assignment.group-chat.$assignmentId.$groupId';

  static List<AssignmentGroupChatMessage> loadMessages({
    required String assignmentId,
    required String groupId,
  }) {
    final raw = _box.read(
      _chatKey(assignmentId: assignmentId, groupId: groupId),
    );
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map(
          (item) => AssignmentGroupChatMessage.fromMap(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
  }

  static Future<void> saveMessages({
    required String assignmentId,
    required String groupId,
    required List<AssignmentGroupChatMessage> messages,
  }) {
    return _box.write(
      _chatKey(assignmentId: assignmentId, groupId: groupId),
      messages.map((m) => m.toMap()).toList(),
    );
  }

  static Future<void> clearMessages({
    required String assignmentId,
    required String groupId,
  }) {
    return _box.remove(_chatKey(assignmentId: assignmentId, groupId: groupId));
  }
}
