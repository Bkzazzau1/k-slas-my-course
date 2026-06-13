import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/live_session_models.dart';
import 'live_session_remote_backend_service.dart';
import 'live_session_runtime_mode_service.dart';

class LiveReplayBookmark {
  const LiveReplayBookmark({
    required this.id,
    required this.sessionId,
    required this.minute,
    required this.title,
    required this.createdAt,
    this.note = '',
    this.isImportant = false,
  });

  final String id;
  final String sessionId;
  final int minute;
  final String title;
  final String note;
  final bool isImportant;
  final DateTime createdAt;

  String get timeLabel => LiveReplayLearningToolsService.minuteLabel(minute);

  LiveReplayBookmark copyWith({
    String? id,
    String? sessionId,
    int? minute,
    String? title,
    String? note,
    bool? isImportant,
    DateTime? createdAt,
  }) {
    return LiveReplayBookmark(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      minute: minute ?? this.minute,
      title: title ?? this.title,
      note: note ?? this.note,
      isImportant: isImportant ?? this.isImportant,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'minute': minute,
    'title': title,
    'note': note,
    'isImportant': isImportant,
    'createdAt': createdAt.toIso8601String(),
  };

  Map<String, dynamic> toRemoteJson() => {
    'bookmarkId': id,
    'sessionId': sessionId,
    'minute': minute,
    'title': title,
    'note': note,
    'important': isImportant,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory LiveReplayBookmark.fromJson(Map<String, dynamic> json) {
    return LiveReplayBookmark(
      id:
          json['id']?.toString() ??
          json['bookmarkId']?.toString() ??
          LiveReplayLearningToolsService._uuid.v4(),
      sessionId: json['sessionId']?.toString() ?? '',
      minute: json['minute'] is int
          ? json['minute'] as int
          : int.tryParse(json['minute']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? 'Replay moment',
      note: json['note']?.toString() ?? '',
      isImportant: json['isImportant'] == true || json['important'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class LiveReplayRevisionQuestion {
  const LiveReplayRevisionQuestion({
    required this.question,
    required this.answerGuide,
    required this.sourceLabel,
    this.minute,
  });

  final String question;
  final String answerGuide;
  final String sourceLabel;
  final int? minute;

  String get timeLabel => minute == null
      ? 'Whole replay'
      : LiveReplayLearningToolsService.minuteLabel(minute!);
}

class LiveReplayLearningSyncResult {
  const LiveReplayLearningSyncResult({
    required this.attempted,
    required this.success,
    required this.message,
    required this.bookmarkCount,
  });

  final bool attempted;
  final bool success;
  final String message;
  final int bookmarkCount;

  static LiveReplayLearningSyncResult skipped(String message, int count) {
    return LiveReplayLearningSyncResult(
      attempted: false,
      success: false,
      message: message,
      bookmarkCount: count,
    );
  }

  static LiveReplayLearningSyncResult ok(String message, int count) {
    return LiveReplayLearningSyncResult(
      attempted: true,
      success: true,
      message: message,
      bookmarkCount: count,
    );
  }

  static LiveReplayLearningSyncResult failed(String message, int count) {
    return LiveReplayLearningSyncResult(
      attempted: true,
      success: false,
      message: message,
      bookmarkCount: count,
    );
  }
}

class LiveReplayLearningToolsService {
  LiveReplayLearningToolsService._();

  static final GetStorage _box = GetStorage();
  static final Uuid _uuid = Uuid();

  static String _key(String sessionId) =>
      'student.live.replay.learning.bookmarks.${sessionId.trim()}';

  static List<LiveReplayBookmark> loadBookmarks(String sessionId) {
    final raw = _box.read<List>(_key(sessionId)) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((item) => LiveReplayBookmark.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.sessionId == sessionId)
        .toList();
    items.sort((a, b) {
      final byMinute = a.minute.compareTo(b.minute);
      if (byMinute != 0) return byMinute;
      return a.createdAt.compareTo(b.createdAt);
    });
    return items;
  }

  static Future<LiveReplayBookmark> createBookmark({
    required String sessionId,
    required int minute,
    required String title,
    String note = '',
    bool isImportant = false,
  }) async {
    final bookmark = LiveReplayBookmark(
      id: _uuid.v4(),
      sessionId: sessionId,
      minute: minute < 0 ? 0 : minute,
      title: title.trim().isEmpty ? 'Replay moment' : title.trim(),
      note: note.trim(),
      isImportant: isImportant,
      createdAt: DateTime.now(),
    );
    await saveBookmark(bookmark);
    return bookmark;
  }

  static Future<void> saveBookmark(LiveReplayBookmark bookmark) async {
    final items = loadBookmarks(bookmark.sessionId);
    final index = items.indexWhere((item) => item.id == bookmark.id);
    if (index >= 0) {
      items[index] = bookmark;
    } else {
      items.add(bookmark);
    }
    items.sort((a, b) => a.minute.compareTo(b.minute));
    await _writeBookmarks(bookmark.sessionId, items);
  }

  static Future<void> deleteBookmark({
    required String sessionId,
    required String bookmarkId,
  }) async {
    final items = loadBookmarks(sessionId)
        .where((item) => item.id != bookmarkId)
        .toList();
    await _writeBookmarks(sessionId, items);
  }

  static Future<LiveReplayLearningSyncResult> pushBookmarksToBackend({
    required String sessionId,
    http.Client? client,
    LiveSessionBackendConfig? config,
  }) async {
    final bookmarks = loadBookmarks(sessionId);
    final backendConfig = config ?? LiveSessionBackendConfig.fromRuntime();
    if (!_canUseRemoteBackend(backendConfig)) {
      return LiveReplayLearningSyncResult.skipped(
        'Replay learning sync is waiting for production backend configuration.',
        bookmarks.length,
      );
    }

    final ownsClient = client == null;
    final activeClient = client ?? http.Client();
    try {
      await _requestJson(
        client: activeClient,
        config: backendConfig,
        method: 'POST',
        pathSegments: [
          'api',
          'v1',
          'live-sessions',
          sessionId,
          'replay-learning',
          'bookmarks',
          'sync',
        ],
        body: {
          'sessionId': sessionId,
          'bookmarks': bookmarks.map((item) => item.toRemoteJson()).toList(),
          'syncedAt': DateTime.now().toUtc().toIso8601String(),
        },
      );
      return LiveReplayLearningSyncResult.ok(
        'Replay learning bookmarks synced to backend.',
        bookmarks.length,
      );
    } catch (error) {
      return LiveReplayLearningSyncResult.failed(error.toString(), bookmarks.length);
    } finally {
      if (ownsClient) activeClient.close();
    }
  }

  static Future<LiveReplayLearningSyncResult> pullBookmarksFromBackend({
    required String sessionId,
    http.Client? client,
    LiveSessionBackendConfig? config,
  }) async {
    final localBookmarks = loadBookmarks(sessionId);
    final backendConfig = config ?? LiveSessionBackendConfig.fromRuntime();
    if (!_canUseRemoteBackend(backendConfig)) {
      return LiveReplayLearningSyncResult.skipped(
        'Replay learning pull is waiting for production backend configuration.',
        localBookmarks.length,
      );
    }

    final ownsClient = client == null;
    final activeClient = client ?? http.Client();
    try {
      final payload = await _requestJson(
        client: activeClient,
        config: backendConfig,
        method: 'GET',
        pathSegments: [
          'api',
          'v1',
          'live-sessions',
          sessionId,
          'replay-learning',
          'bookmarks',
        ],
      );
      final remoteBookmarks = _asList(payload['bookmarks'])
          .whereType<Map>()
          .map((item) => LiveReplayBookmark.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.sessionId == sessionId)
          .toList();
      final merged = _mergeBookmarks(localBookmarks, remoteBookmarks);
      await _writeBookmarks(sessionId, merged);
      return LiveReplayLearningSyncResult.ok(
        'Replay learning bookmarks pulled from backend.',
        merged.length,
      );
    } catch (error) {
      return LiveReplayLearningSyncResult.failed(error.toString(), localBookmarks.length);
    } finally {
      if (ownsClient) activeClient.close();
    }
  }

  static List<LiveReplayRevisionQuestion> buildQuickRevisionQuestions({
    required LiveSessionModel session,
    required String notes,
    required List<LiveReplayBookmark> bookmarks,
  }) {
    final questions = <LiveReplayRevisionQuestion>[];

    for (final agenda in session.agenda.take(5)) {
      final topic = _shorten(agenda, max: 72);
      questions.add(
        LiveReplayRevisionQuestion(
          question: 'Explain the main idea behind "$topic".',
          answerGuide:
              'Replay this agenda section and write the definition, one example, and why it matters in ${session.courseCode}.',
          sourceLabel: 'Class agenda',
        ),
      );
    }

    for (final bookmark in bookmarks.where((item) => item.isImportant).take(5)) {
      final title = _shorten(bookmark.title, max: 72);
      questions.add(
        LiveReplayRevisionQuestion(
          question: 'Why was "$title" marked as important?',
          answerGuide:
              'Go to ${bookmark.timeLabel}, summarize the lecturer\'s point, and add one likely exam question from it.',
          sourceLabel: 'Important replay moment',
          minute: bookmark.minute,
        ),
      );
    }

    for (final material in session.materials.take(3)) {
      final title = _shorten(material.title, max: 72);
      questions.add(
        LiveReplayRevisionQuestion(
          question: 'How does "$title" support this lecture?',
          answerGuide:
              'Mention the material purpose, the topic it connects to, and one thing you should revise from it.',
          sourceLabel: 'Class material',
        ),
      );
    }

    final usefulNoteLines = notes
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.length > 24)
        .take(4);
    for (final line in usefulNoteLines) {
      final idea = _shorten(line, max: 72);
      questions.add(
        LiveReplayRevisionQuestion(
          question: 'Turn this note into an exam answer: "$idea".',
          answerGuide:
              'Rewrite the point clearly, support it with an example, and list any formula, term, or process involved.',
          sourceLabel: 'Saved note',
        ),
      );
    }

    if (questions.isEmpty) {
      questions.add(
        LiveReplayRevisionQuestion(
          question: 'What are the three most important lessons from this replay?',
          answerGuide:
              'Watch the replay again, pause at key moments, and write three points with one example each.',
          sourceLabel: 'Whole replay',
        ),
      );
    }

    return questions.take(12).toList();
  }

  static String minuteLabel(int minute) {
    final safeMinute = minute < 0 ? 0 : minute;
    final hours = safeMinute ~/ 60;
    final mins = safeMinute % 60;
    if (hours == 0) return '${mins}m';
    return '${hours}h ${mins.toString().padLeft(2, '0')}m';
  }

  static Future<void> _writeBookmarks(
    String sessionId,
    List<LiveReplayBookmark> bookmarks,
  ) async {
    bookmarks.sort((a, b) {
      final byMinute = a.minute.compareTo(b.minute);
      if (byMinute != 0) return byMinute;
      return a.createdAt.compareTo(b.createdAt);
    });
    await _box.write(_key(sessionId), bookmarks.map((item) => item.toJson()).toList());
  }

  static bool _canUseRemoteBackend(LiveSessionBackendConfig config) {
    return LiveSessionRuntimeModeStore.load() == LiveSessionRuntimeMode.production &&
        config.isConfigured;
  }

  static List<LiveReplayBookmark> _mergeBookmarks(
    List<LiveReplayBookmark> local,
    List<LiveReplayBookmark> remote,
  ) {
    final merged = <String, LiveReplayBookmark>{};
    for (final item in [...local, ...remote]) {
      final existing = merged[item.id];
      if (existing == null || item.createdAt.isAfter(existing.createdAt)) {
        merged[item.id] = item;
      }
    }
    return merged.values.toList();
  }

  static Future<Map<String, dynamic>> _requestJson({
    required http.Client client,
    required LiveSessionBackendConfig config,
    required String method,
    required List<String> pathSegments,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(config, pathSegments);
    final response = switch (method) {
      'GET' => await client.get(uri, headers: _jsonHeaders),
      'POST' => await client.post(
          uri,
          headers: _jsonHeaders,
          body: jsonEncode(body ?? const {}),
        ),
      _ => throw UnsupportedError('Unsupported replay learning method: $method'),
    };

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Replay learning sync failed (${response.statusCode}).');
    }

    if (response.body.trim().isEmpty) return const {};
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  static Uri _buildUri(
    LiveSessionBackendConfig config,
    List<String> pathSegments,
  ) {
    final base = Uri.parse(config.apiBaseUrl);
    final baseSegments = base.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    return base.replace(pathSegments: [...baseSegments, ...pathSegments]);
  }

  static List<dynamic> _asList(Object? value) {
    if (value is List) return value;
    return const [];
  }

  static String _shorten(String text, {int max = 90}) {
    final clean = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max).trim()}...';
  }

  static Map<String, String> get _jsonHeaders => const {
    'Content-Type': 'application/json',
  };
}
