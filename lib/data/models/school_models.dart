class SchoolModel {
  SchoolModel({required this.id, required this.name, this.shortName = ""});
  final String id;
  final String name;
  final String shortName;
}

class DepartmentModel {
  DepartmentModel({
    required this.id,
    required this.schoolId,
    required this.name,
  });
  final String id;
  final String schoolId;
  final String name;
}

class CourseModelLite {
  CourseModelLite({
    required this.code,
    required this.title,
    required this.level,
    required this.semester,
    this.isElective = false,
  });

  final String code;
  final String title;
  final int level; // 100, 200...
  final int semester; // 1 or 2
  final bool isElective;
}
