import '../models/school_models.dart';

class CatalogService {
  // MVP mock schools
  static List<SchoolModel> schools() => [
    SchoolModel(
      id: "abu",
      name: "Ahmadu Bello University, Zaria",
      shortName: "ABU",
    ),
    SchoolModel(id: "unilag", name: "University of Lagos", shortName: "UNILAG"),
    SchoolModel(id: "ui", name: "University of Ibadan", shortName: "UI"),
  ];

  static List<DepartmentModel> departments(String schoolId) {
    final all = [
      DepartmentModel(id: "abu_cs", schoolId: "abu", name: "Computer Science"),
      DepartmentModel(id: "abu_math", schoolId: "abu", name: "Mathematics"),
      DepartmentModel(
        id: "unilag_cs",
        schoolId: "unilag",
        name: "Computer Science",
      ),
      DepartmentModel(id: "ui_cs", schoolId: "ui", name: "Computer Science"),
    ];
    return all.where((d) => d.schoolId == schoolId).toList();
  }

  // MVP curriculum list by dept+level+semester
  static List<CourseModelLite> courses({
    required String departmentId,
    required int level,
    required int semester,
  }) {
    // Example for ABU CS
    if (departmentId == "abu_cs" && level == 300 && semester == 1) {
      return [
        CourseModelLite(
          code: "CSC 305",
          title: "Data Structures",
          level: 300,
          semester: 1,
        ),
        CourseModelLite(
          code: "CSC 301",
          title: "Algorithms",
          level: 300,
          semester: 1,
        ),
        CourseModelLite(
          code: "MTH 202",
          title: "Linear Algebra",
          level: 200,
          semester: 2,
          isElective: true,
        ),
        CourseModelLite(
          code: "GST 201",
          title: "Use of English",
          level: 200,
          semester: 1,
          isElective: true,
        ),
      ];
    }

    // Default fallback
    return [
      CourseModelLite(
        code: "GST 101",
        title: "Communication in English",
        level: level,
        semester: semester,
      ),
      CourseModelLite(
        code: "CSC 101",
        title: "Introduction to Computing",
        level: level,
        semester: semester,
      ),
      CourseModelLite(
        code: "MTH 101",
        title: "Algebra & Trigonometry",
        level: level,
        semester: semester,
        isElective: true,
      ),
    ];
  }
}
