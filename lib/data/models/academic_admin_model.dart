import 'course_model.dart';

enum AcademicAdminRole { hod, registry, student }

extension AcademicAdminRoleX on AcademicAdminRole {
  String get label {
    switch (this) {
      case AcademicAdminRole.hod:
        return 'HoD';
      case AcademicAdminRole.registry:
        return 'Registry';
      case AcademicAdminRole.student:
        return 'Student';
    }
  }
}

class AcademicStaffDraft {
  const AcademicStaffDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.staffId,
    required this.roleCode,
    required this.departmentId,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String staffId;
  final String roleCode;
  final int departmentId;
  final String password;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'staff_id': staffId,
    'role_code': roleCode,
    'department_id': departmentId,
    'password': password,
  };
}

class StudentRegistrationDraft {
  const StudentRegistrationDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.matricNo,
    required this.departmentId,
    required this.programmeId,
    required this.level,
    required this.semester,
    required this.academicSession,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String matricNo;
  final int departmentId;
  final int programmeId;
  final String level;
  final String semester;
  final String academicSession;
  final String password;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'matric_no': matricNo,
    'department_id': departmentId,
    'programme_id': programmeId,
    'level': level,
    'semester': semester,
    'academic_session': academicSession,
    'password': password,
  };
}

class CourseRegistrationItem {
  const CourseRegistrationItem({
    required this.course,
    required this.status,
    required this.academicSession,
  });

  final CourseModel course;
  final String status;
  final String academicSession;

  factory CourseRegistrationItem.fromJson(Map<String, dynamic> json) {
    final nested = json['course'];
    final courseJson = nested is Map<String, dynamic> ? nested : json;
    return CourseRegistrationItem(
      course: CourseModel(
        courseJson['code']?.toString() ?? json['course_code']?.toString() ?? '',
        courseJson['title']?.toString() ??
            json['course_title']?.toString() ??
            '',
        notes: true,
        pastQuestions: true,
      ),
      status: json['status']?.toString() ?? 'pending',
      academicSession: json['academic_session']?.toString() ?? '',
    );
  }
}
