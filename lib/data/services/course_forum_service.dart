import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/course_forum_model.dart';
import 'course_catalog_service.dart';
import 'live_session_runtime_mode_service.dart';
import 'student_profile_storage.dart';

abstract class CourseForumGateway {
  Future<List<CourseForumPostModel>> fetchPosts({
    required int? courseId,
    required String courseCode,
  });

  Future<CourseForumPostModel> createPost({
    required int? courseId,
    required String courseCode,
    required String body,
    String? title,
    String? parentId,
  });
}

class CourseForumService {
  CourseForumService._();

  static final CourseForumGateway gateway = RemoteCourseForumGateway(
    fallback: LocalCourseForumGateway.instance,
  );
}

class LocalCourseForumGateway implements CourseForumGateway {
  LocalCourseForumGateway._();

  static final LocalCourseForumGateway instance = LocalCourseForumGateway._();
  static final GetStorage _box = GetStorage();
  static const Uuid _uuid = Uuid();
  static const String _kForumPosts = 'courseForums.posts';

  @override
  Future<List<CourseForumPostModel>> fetchPosts({
    required int? courseId,
    required String courseCode,
  }) async {
    final code = courseCode.trim().toUpperCase();
    final items = _load();
    final roots = items
        .where(
          (post) =>
              post.courseCode.trim().toUpperCase() == code &&
              post.parentId == null,
        )
        .toList();
    roots.sort((a, b) {
      final pinned = (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0);
      if (pinned != 0) return pinned;
      return b.createdAt.compareTo(a.createdAt);
    });
    return roots.map((root) {
      final replies = items.where((post) => post.parentId == root.id).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return root.copyWith(replies: replies);
    }).toList();
  }

  @override
  Future<CourseForumPostModel> createPost({
    required int? courseId,
    required String courseCode,
    required String body,
    String? title,
    String? parentId,
  }) async {
    final profile = StudentProfileStorage.load();
    final item = CourseForumPostModel(
      id: _uuid.v4(),
      courseId: courseId,
      courseCode: courseCode,
      authorDisplayName: profile?.fullName ?? 'Student',
      authorRole: 'student',
      title: title?.trim().isEmpty == true ? null : title?.trim(),
      body: body.trim(),
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    final items = _load()..add(item);
    await _save(items);
    return item;
  }

  List<CourseForumPostModel> _load() {
    final raw = _box.read(_kForumPosts);
    if (raw == null) return _seed();
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                CourseForumPostModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return _seed();
    }
  }

  Future<void> _save(List<CourseForumPostModel> items) async {
    await _box.write(
      _kForumPosts,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  List<CourseForumPostModel> _seed() {
    final now = DateTime.now();
    return [
      CourseForumPostModel(
        id: 'forum-mth202-office-note',
        courseId: null,
        courseCode: 'MTH 202',
        authorDisplayName: 'Course lecturer',
        authorRole: 'lecturer',
        title: 'Eigenvalues discussion',
        body:
            'Share questions from the eigenvalues notes here. Keep answers tied to the uploaded lecturer material.',
        isPinned: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CourseForumPostModel(
        id: 'forum-mth202-student-question',
        courseId: null,
        courseCode: 'MTH 202',
        authorDisplayName: 'Student',
        authorRole: 'student',
        title: 'Characteristic equation',
        body:
            'Can someone explain why det(A - lambda I) becomes zero for eigenvalues?',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }
}

class RemoteCourseForumGateway implements CourseForumGateway {
  RemoteCourseForumGateway({
    http.Client? client,
    CourseCatalogBackendConfig? config,
    required CourseForumGateway fallback,
  }) : _client = client ?? http.Client(),
       _config = config ?? CourseCatalogBackendConfig.fromRuntime(),
       _fallback = fallback;

  final http.Client _client;
  final CourseCatalogBackendConfig _config;
  final CourseForumGateway _fallback;

  bool get isConfigured =>
      LiveSessionRuntimeModeStore.load() == LiveSessionRuntimeMode.production &&
      _config.isConfigured;

  @override
  Future<List<CourseForumPostModel>> fetchPosts({
    required int? courseId,
    required String courseCode,
  }) async {
    if (!isConfigured || courseId == null) {
      return _fallback.fetchPosts(courseId: courseId, courseCode: courseCode);
    }
    try {
      final response = await _client.get(
        _uri(['api', 'courses', '$courseId', 'forum', 'posts']),
        headers: _headers,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback.fetchPosts(courseId: courseId, courseCode: courseCode);
      }
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic>
          ? decoded['items']
          : decoded;
      if (items is! List) {
        return _fallback.fetchPosts(courseId: courseId, courseCode: courseCode);
      }
      return items
          .whereType<Map>()
          .map(
            (item) =>
                CourseForumPostModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return _fallback.fetchPosts(courseId: courseId, courseCode: courseCode);
    }
  }

  @override
  Future<CourseForumPostModel> createPost({
    required int? courseId,
    required String courseCode,
    required String body,
    String? title,
    String? parentId,
  }) async {
    if (!isConfigured || courseId == null) {
      return _fallback.createPost(
        courseId: courseId,
        courseCode: courseCode,
        title: title,
        body: body,
        parentId: parentId,
      );
    }
    try {
      final response = await _client.post(
        _uri(['api', 'courses', '$courseId', 'forum', 'posts']),
        headers: {..._headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'parent_id': int.tryParse(parentId ?? ''),
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _fallback.createPost(
          courseId: courseId,
          courseCode: courseCode,
          title: title,
          body: body,
          parentId: parentId,
        );
      }
      return CourseForumPostModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
    } catch (_) {
      return _fallback.createPost(
        courseId: courseId,
        courseCode: courseCode,
        title: title,
        body: body,
        parentId: parentId,
      );
    }
  }

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Authorization': 'Bearer ${_config.accessToken}',
  };

  Uri _uri(List<String> segments) {
    final base = Uri.parse(_config.apiBaseUrl);
    final baseSegments = base.pathSegments.where((s) => s.isNotEmpty);
    return base.replace(pathSegments: [...baseSegments, ...segments]);
  }
}
