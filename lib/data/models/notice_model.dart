class NoticeScope {
  static const String school = "SCHOOL";
  static const String course = "COURSE";
}

class NoticeModel {
  NoticeModel({
    required this.id,
    required this.title,
    required this.body,
    required this.scope,
    this.courseCode,
    required this.source,
    required this.createdAt,
    this.priority = 0, // 0 normal, 1 important
  });

  final String id;
  final String title;
  final String body;
  final String scope; // SCHOOL or COURSE
  final String? courseCode;

  final String source; // e.g., "Dept Office", "Class Rep", "Portal"
  final DateTime createdAt;

  final int priority;
}
