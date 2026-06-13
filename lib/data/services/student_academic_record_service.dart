import '../models/course_model.dart';
import 'course_catalog_service.dart';
import 'student_profile_storage.dart';

class AcademicProgressSummary {
  const AcademicProgressSummary({
    required this.enrolledCourses,
    required this.completedCourses,
    required this.coreCourses,
    required this.electiveCourses,
    required this.currentCredits,
    required this.completedCredits,
    required this.currentGpa,
    required this.cgpa,
  });

  final int enrolledCourses;
  final int completedCourses;
  final int coreCourses;
  final int electiveCourses;
  final int currentCredits;
  final int completedCredits;
  final double currentGpa;
  final double cgpa;
}

class StudentAcademicRecordSnapshot {
  const StudentAcademicRecordSnapshot({
    required this.enrolled,
    required this.completed,
    required this.summary,
    required this.providerLabel,
  });

  final List<CourseModel> enrolled;
  final List<CourseModel> completed;
  final AcademicProgressSummary summary;
  final String providerLabel;

  List<CourseModel> get allCourses => [...enrolled, ...completed];
}

class StudentAcademicRecordService {
  StudentAcademicRecordService._();

  static Future<StudentAcademicRecordSnapshot> load() async {
    final gateway = RemoteCourseCatalogGateway();
    final registered = await gateway.fetchCourses();
    final profile = StudentProfileStorage.load();
    final session = _academicSession(DateTime.now());

    final enrolled = registered
        .map(
          (course) => CourseModel(
            course.code,
            course.title,
            id: course.id,
            notes: course.notes,
            pastQuestions: course.pastQuestions,
            progress: course.progress,
            creditUnits: course.creditUnits,
            type: _typeForCode(course.code),
            status: CourseStatus.enrolled,
            level: profile?.level,
            semester: profile?.semester,
            academicSession: session,
          ),
        )
        .toList();

    final completed = _demoCompletedCourses(profileLevel: profile?.level ?? 300);
    return StudentAcademicRecordSnapshot(
      enrolled: enrolled,
      completed: completed,
      summary: _summary(enrolled: enrolled, completed: completed),
      providerLabel: gateway.providerLabel,
    );
  }

  static AcademicProgressSummary _summary({
    required List<CourseModel> enrolled,
    required List<CourseModel> completed,
  }) {
    final currentGradeReady = enrolled
        .where((course) => course.gradePoint != null)
        .toList();
    final completedGradeReady = completed
        .where((course) => course.gradePoint != null)
        .toList();
    final allGradeReady = [...currentGradeReady, ...completedGradeReady];

    final currentCredits = enrolled.fold<int>(0, (sum, course) => sum + course.creditUnits);
    final completedCredits = completed.fold<int>(0, (sum, course) => sum + course.creditUnits);

    return AcademicProgressSummary(
      enrolledCourses: enrolled.length,
      completedCourses: completed.length,
      coreCourses: [...enrolled, ...completed].where((course) => course.isCore).length,
      electiveCourses: [...enrolled, ...completed].where((course) => course.isElective).length,
      currentCredits: currentCredits,
      completedCredits: completedCredits,
      currentGpa: _weightedGpa(currentGradeReady),
      cgpa: _weightedGpa(allGradeReady),
    );
  }

  static double _weightedGpa(List<CourseModel> courses) {
    final credits = courses.fold<int>(0, (sum, course) => sum + course.creditUnits);
    if (credits == 0) return 0;
    final quality = courses.fold<double>(0, (sum, course) => sum + course.qualityPoints);
    return double.parse((quality / credits).toStringAsFixed(2));
  }

  static String _typeForCode(String code) {
    final normalized = code.toUpperCase();
    if (normalized.startsWith('GST') || normalized.startsWith('ENT')) {
      return CourseType.elective;
    }
    return CourseType.core;
  }

  static List<CourseModel> _demoCompletedCourses({required int profileLevel}) {
    final previousLevel = profileLevel <= 100 ? 100 : profileLevel - 100;
    return [
      CourseModel(
        'CSC 201',
        'Object Oriented Programming',
        creditUnits: 3,
        type: CourseType.core,
        status: CourseStatus.completed,
        level: previousLevel,
        semester: 1,
        academicSession: '2024/2025',
        grade: 'A',
        gradePoint: 5.0,
        progress: 100,
      ),
      CourseModel(
        'CSC 202',
        'Computer Organization',
        creditUnits: 3,
        type: CourseType.core,
        status: CourseStatus.completed,
        level: previousLevel,
        semester: 2,
        academicSession: '2024/2025',
        grade: 'B',
        gradePoint: 4.0,
        progress: 100,
      ),
      CourseModel(
        'MTH 201',
        'Discrete Mathematics',
        creditUnits: 3,
        type: CourseType.core,
        status: CourseStatus.completed,
        level: previousLevel,
        semester: 1,
        academicSession: '2024/2025',
        grade: 'B',
        gradePoint: 4.0,
        progress: 100,
      ),
      CourseModel(
        'GST 202',
        'Peace Studies and Conflict Resolution',
        creditUnits: 2,
        type: CourseType.elective,
        status: CourseStatus.completed,
        level: previousLevel,
        semester: 2,
        academicSession: '2024/2025',
        grade: 'A',
        gradePoint: 5.0,
        progress: 100,
      ),
    ];
  }

  static String _academicSession(DateTime date) {
    final startYear = date.month >= 9 ? date.year : date.year - 1;
    return '$startYear/${startYear + 1}';
  }
}
