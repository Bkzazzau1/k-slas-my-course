class CourseForumPostModel {
  const CourseForumPostModel({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.authorDisplayName,
    required this.authorRole,
    required this.body,
    required this.createdAt,
    this.title,
    this.parentId,
    this.isPinned = false,
    this.isLocked = false,
    this.replies = const [],
  });

  final String id;
  final int? courseId;
  final String courseCode;
  final String authorDisplayName;
  final String authorRole;
  final String? title;
  final String body;
  final bool isPinned;
  final bool isLocked;
  final String? parentId;
  final DateTime createdAt;
  final List<CourseForumPostModel> replies;

  bool get isLecturer => authorRole.toLowerCase() == 'lecturer';

  factory CourseForumPostModel.fromJson(Map<String, dynamic> json) {
    return CourseForumPostModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      courseId: int.tryParse(json['course_id']?.toString() ?? ''),
      courseCode: json['course_code']?.toString() ?? '',
      authorDisplayName:
          json['author_display_name']?.toString() ?? 'Course member',
      authorRole: json['author_role']?.toString() ?? 'student',
      title: json['title']?.toString(),
      body: json['body']?.toString() ?? '',
      isPinned: json['is_pinned'] == true,
      isLocked: json['is_locked'] == true,
      parentId: json['parent_id']?.toString(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      replies: (json['replies'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                CourseForumPostModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'course_id': courseId,
    'course_code': courseCode,
    'author_display_name': authorDisplayName,
    'author_role': authorRole,
    'title': title,
    'body': body,
    'is_pinned': isPinned,
    'is_locked': isLocked,
    'parent_id': parentId,
    'created_at': createdAt.toIso8601String(),
    'replies': replies.map((reply) => reply.toJson()).toList(),
  };

  CourseForumPostModel copyWith({List<CourseForumPostModel>? replies}) {
    return CourseForumPostModel(
      id: id,
      courseId: courseId,
      courseCode: courseCode,
      authorDisplayName: authorDisplayName,
      authorRole: authorRole,
      title: title,
      body: body,
      isPinned: isPinned,
      isLocked: isLocked,
      parentId: parentId,
      createdAt: createdAt,
      replies: replies ?? this.replies,
    );
  }
}
