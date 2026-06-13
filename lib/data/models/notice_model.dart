class NoticeScope {
  static const String school = 'SCHOOL';
  static const String course = 'COURSE';
  static const String department = 'DEPARTMENT';
  static const String programme = 'PROGRAMME';
  static const String level = 'LEVEL';
  static const String cohort = 'COHORT';
  static const String exam = 'EXAM';
}

class NoticeAudience {
  static const String students = 'STUDENTS';
  static const String lecturers = 'LECTURERS';
  static const String invigilators = 'INVIGILATORS';
  static const String examOfficers = 'EXAM_OFFICERS';
  static const String all = 'ALL';
}

class NoticeStatus {
  static const String draft = 'DRAFT';
  static const String published = 'PUBLISHED';
  static const String archived = 'ARCHIVED';
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
    this.priority = 0,
    this.audience = NoticeAudience.students,
    this.status = NoticeStatus.published,
    this.authorId,
    this.authorName,
    this.authorRole,
    this.expiresAt,
    this.pinned = false,
    this.requiresAcknowledgement = false,
    this.reference,
    this.schoolId,
    this.departmentId,
    this.programmeId,
    this.targetLevel,
    this.targetSemester,
    this.targetCohortKey,
  });

  final String id;
  final String title;
  final String body;
  final String scope;
  final String? courseCode;
  final String source;
  final DateTime createdAt;
  final int priority;
  final String audience;
  final String status;
  final String? authorId;
  final String? authorName;
  final String? authorRole;
  final DateTime? expiresAt;
  final bool pinned;
  final bool requiresAcknowledgement;
  final String? reference;
  final String? schoolId;
  final String? departmentId;
  final String? programmeId;
  final int? targetLevel;
  final int? targetSemester;
  final String? targetCohortKey;

  bool get isImportant => priority > 0;
  bool get isPublished => status == NoticeStatus.published;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool matchesAcademicTarget({
    int? level,
    int? semester,
    String? departmentId,
    String? programmeId,
    String? cohortKey,
  }) {
    final levelOk = targetLevel == null || targetLevel == level;
    final semesterOk = targetSemester == null || targetSemester == semester;
    final departmentOk = this.departmentId == null || this.departmentId == departmentId;
    final programmeOk = this.programmeId == null || this.programmeId == programmeId;
    final cohortOk = targetCohortKey == null || targetCohortKey == cohortKey;
    return levelOk && semesterOk && departmentOk && programmeOk && cohortOk;
  }

  bool matchesLevel({int? level, int? semester}) {
    return matchesAcademicTarget(level: level, semester: semester);
  }

  NoticeModel copyWith({
    String? id,
    String? title,
    String? body,
    String? scope,
    String? courseCode,
    String? source,
    DateTime? createdAt,
    int? priority,
    String? audience,
    String? status,
    String? authorId,
    String? authorName,
    String? authorRole,
    DateTime? expiresAt,
    bool? pinned,
    bool? requiresAcknowledgement,
    String? reference,
    String? schoolId,
    String? departmentId,
    String? programmeId,
    int? targetLevel,
    int? targetSemester,
    String? targetCohortKey,
  }) {
    return NoticeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      scope: scope ?? this.scope,
      courseCode: courseCode ?? this.courseCode,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      audience: audience ?? this.audience,
      status: status ?? this.status,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      expiresAt: expiresAt ?? this.expiresAt,
      pinned: pinned ?? this.pinned,
      requiresAcknowledgement:
          requiresAcknowledgement ?? this.requiresAcknowledgement,
      reference: reference ?? this.reference,
      schoolId: schoolId ?? this.schoolId,
      departmentId: departmentId ?? this.departmentId,
      programmeId: programmeId ?? this.programmeId,
      targetLevel: targetLevel ?? this.targetLevel,
      targetSemester: targetSemester ?? this.targetSemester,
      targetCohortKey: targetCohortKey ?? this.targetCohortKey,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'scope': scope,
      'courseCode': courseCode,
      'source': source,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'audience': audience,
      'status': status,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'expiresAt': expiresAt?.toIso8601String(),
      'pinned': pinned,
      'requiresAcknowledgement': requiresAcknowledgement,
      'reference': reference,
      'schoolId': schoolId,
      'departmentId': departmentId,
      'programmeId': programmeId,
      'targetLevel': targetLevel,
      'targetSemester': targetSemester,
      'targetCohortKey': targetCohortKey,
    };
  }

  factory NoticeModel.fromMap(Map<String, dynamic> map) {
    return NoticeModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      scope: (map['scope'] ?? NoticeScope.school).toString(),
      courseCode: map['courseCode']?.toString(),
      source: (map['source'] ?? 'Portal').toString(),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      priority: map['priority'] is num ? (map['priority'] as num).toInt() : 0,
      audience: (map['audience'] ?? NoticeAudience.students).toString(),
      status: (map['status'] ?? NoticeStatus.published).toString(),
      authorId: map['authorId']?.toString(),
      authorName: map['authorName']?.toString(),
      authorRole: map['authorRole']?.toString(),
      expiresAt: DateTime.tryParse((map['expiresAt'] ?? '').toString()),
      pinned: map['pinned'] == true,
      requiresAcknowledgement: map['requiresAcknowledgement'] == true,
      reference: map['reference']?.toString(),
      schoolId: map['schoolId']?.toString(),
      departmentId: map['departmentId']?.toString(),
      programmeId: map['programmeId']?.toString(),
      targetLevel: _intOrNull(map['targetLevel']),
      targetSemester: _intOrNull(map['targetSemester']),
      targetCohortKey: map['targetCohortKey']?.toString(),
    );
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
