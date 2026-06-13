class StudentProfileModel {
  StudentProfileModel({
    required this.schoolId,
    required this.schoolName,
    required this.departmentId,
    required this.departmentName,
    required this.level,
    required this.semester,
    required this.selectedCourses,
    required this.fullName,
    this.programmeId,
    this.programmeName,
    this.matricNo,
    this.email,
    this.phone,
    this.studentCategoryKey,
  });

  final String schoolId;
  final String schoolName;
  final String departmentId;
  final String departmentName;
  final String? programmeId;
  final String? programmeName;
  final int level;
  final int semester;
  final List<String> selectedCourses; // course codes
  final String fullName;

  final String? matricNo;
  final String? email;
  final String? phone;
  final String? studentCategoryKey;
}
