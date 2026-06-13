class CohortMode {
  static const String regular = 'REGULAR';
  static const String partTime = 'PART_TIME';
  static const String distanceLearning = 'DISTANCE_LEARNING';
  static const String sandwich = 'SANDWICH';
  static const String postgraduate = 'POSTGRADUATE';
}

class CohortStatus {
  static const String active = 'ACTIVE';
  static const String archived = 'ARCHIVED';
}

class CohortModel {
  const CohortModel({
    required this.id,
    required this.name,
    required this.schoolId,
    required this.departmentId,
    this.departmentName,
    this.programmeId,
    this.programmeName,
    required this.intakeYear,
    required this.mode,
    this.level,
    this.semester,
    this.academicSession,
    this.status = CohortStatus.active,
    this.createdAt,
  });

  final String id;
  final String name;
  final String schoolId;
  final String departmentId;
  final String? departmentName;
  final String? programmeId;
  final String? programmeName;
  final int intakeYear;
  final String mode;
  final int? level;
  final int? semester;
  final String? academicSession;
  final String status;
  final DateTime? createdAt;

  bool get isActive => status == CohortStatus.active;

  String get targetingKey => id;

  String get displayLabel {
    final programme = programmeName ?? programmeId ?? 'Programme';
    final levelLabel = level == null ? 'All levels' : '$level Level';
    return '$programme • $intakeYear • ${modeLabel(mode)} • $levelLabel';
  }

  CohortModel copyWith({
    String? id,
    String? name,
    String? schoolId,
    String? departmentId,
    String? departmentName,
    String? programmeId,
    String? programmeName,
    int? intakeYear,
    String? mode,
    int? level,
    int? semester,
    String? academicSession,
    String? status,
    DateTime? createdAt,
  }) {
    return CohortModel(
      id: id ?? this.id,
      name: name ?? this.name,
      schoolId: schoolId ?? this.schoolId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      programmeId: programmeId ?? this.programmeId,
      programmeName: programmeName ?? this.programmeName,
      intakeYear: intakeYear ?? this.intakeYear,
      mode: mode ?? this.mode,
      level: level ?? this.level,
      semester: semester ?? this.semester,
      academicSession: academicSession ?? this.academicSession,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'schoolId': schoolId,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'programmeId': programmeId,
      'programmeName': programmeName,
      'intakeYear': intakeYear,
      'mode': mode,
      'level': level,
      'semester': semester,
      'academicSession': academicSession,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory CohortModel.fromMap(Map<String, dynamic> map) {
    return CohortModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      schoolId: (map['schoolId'] ?? '').toString(),
      departmentId: (map['departmentId'] ?? '').toString(),
      departmentName: map['departmentName']?.toString(),
      programmeId: map['programmeId']?.toString(),
      programmeName: map['programmeName']?.toString(),
      intakeYear: _intOrDefault(map['intakeYear'], DateTime.now().year),
      mode: (map['mode'] ?? CohortMode.regular).toString(),
      level: _intOrNull(map['level']),
      semester: _intOrNull(map['semester']),
      academicSession: map['academicSession']?.toString(),
      status: (map['status'] ?? CohortStatus.active).toString(),
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()),
    );
  }

  static String modeLabel(String mode) {
    switch (mode) {
      case CohortMode.partTime:
        return 'Part-Time';
      case CohortMode.distanceLearning:
        return 'Distance Learning';
      case CohortMode.sandwich:
        return 'Sandwich';
      case CohortMode.postgraduate:
        return 'Postgraduate';
      case CohortMode.regular:
      default:
        return 'Regular';
    }
  }

  static int? _intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int _intOrDefault(dynamic value, int fallback) {
    return _intOrNull(value) ?? fallback;
  }
}
