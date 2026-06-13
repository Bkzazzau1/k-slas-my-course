import '../models/course_model.dart';
import '../models/student_profile_model.dart';
import 'student_profile_storage.dart';

class CourseRegistrationRuleSet {
  const CourseRegistrationRuleSet({
    required this.minCreditUnits,
    required this.maxCreditUnits,
    required this.requiredCoreCourses,
    required this.availableElectives,
    required this.academicSession,
  });

  final int minCreditUnits;
  final int maxCreditUnits;
  final List<CourseModel> requiredCoreCourses;
  final List<CourseModel> availableElectives;
  final String academicSession;

  List<CourseModel> get allAvailable => [...requiredCoreCourses, ...availableElectives];
}

class CourseRegistrationValidationResult {
  const CourseRegistrationValidationResult({
    required this.isValid,
    required this.messages,
    required this.totalCredits,
    required this.coreCredits,
    required this.electiveCredits,
  });

  final bool isValid;
  final List<String> messages;
  final int totalCredits;
  final int coreCredits;
  final int electiveCredits;
}

class CourseRegistrationDraft {
  const CourseRegistrationDraft({
    required this.selectedCourses,
    required this.ruleSet,
    required this.validation,
  });

  final List<CourseModel> selectedCourses;
  final CourseRegistrationRuleSet ruleSet;
  final CourseRegistrationValidationResult validation;
}

class CourseRegistrationService {
  CourseRegistrationService._();

  static CourseRegistrationRuleSet loadRuleSet() {
    final profile = StudentProfileStorage.load();
    final level = profile?.level ?? 300;
    final semester = profile?.semester ?? 1;
    final session = _academicSession(DateTime.now());

    return CourseRegistrationRuleSet(
      minCreditUnits: 15,
      maxCreditUnits: 24,
      academicSession: session,
      requiredCoreCourses: _coreCourses(level: level, semester: semester, profile: profile),
      availableElectives: _electiveCourses(level: level, semester: semester, profile: profile),
    );
  }

  static CourseRegistrationDraft buildDraft(Set<String> selectedElectiveCodes) {
    final rules = loadRuleSet();
    final selectedElectives = rules.availableElectives
        .where((course) => selectedElectiveCodes.contains(course.code))
        .toList();
    final selected = [...rules.requiredCoreCourses, ...selectedElectives];
    return CourseRegistrationDraft(
      selectedCourses: selected,
      ruleSet: rules,
      validation: validate(selectedCourses: selected, ruleSet: rules),
    );
  }

  static CourseRegistrationValidationResult validate({
    required List<CourseModel> selectedCourses,
    required CourseRegistrationRuleSet ruleSet,
  }) {
    final messages = <String>[];
    final selectedCodes = selectedCourses.map((course) => course.code).toSet();
    final coreCodes = ruleSet.requiredCoreCourses.map((course) => course.code).toSet();
    final missingCore = coreCodes.difference(selectedCodes);
    final totalCredits = selectedCourses.fold<int>(0, (sum, course) => sum + course.creditUnits);
    final coreCredits = selectedCourses
        .where((course) => course.isCore)
        .fold<int>(0, (sum, course) => sum + course.creditUnits);
    final electiveCredits = selectedCourses
        .where((course) => course.isElective)
        .fold<int>(0, (sum, course) => sum + course.creditUnits);

    if (missingCore.isNotEmpty) {
      messages.add('All core courses are compulsory: ${missingCore.join(', ')}.');
    }
    if (totalCredits < ruleSet.minCreditUnits) {
      messages.add('Minimum credit load is ${ruleSet.minCreditUnits}. Add more elective credits.');
    }
    if (totalCredits > ruleSet.maxCreditUnits) {
      messages.add('Maximum credit load is ${ruleSet.maxCreditUnits}. Remove some courses.');
    }
    if (selectedCourses.where((course) => course.isElective).isEmpty &&
        ruleSet.availableElectives.isNotEmpty &&
        totalCredits < ruleSet.minCreditUnits) {
      messages.add('Choose at least one elective to meet the credit requirement.');
    }

    return CourseRegistrationValidationResult(
      isValid: messages.isEmpty,
      messages: messages,
      totalCredits: totalCredits,
      coreCredits: coreCredits,
      electiveCredits: electiveCredits,
    );
  }

  static List<CourseModel> _coreCourses({
    required int level,
    required int semester,
    StudentProfileModel? profile,
  }) {
    final session = _academicSession(DateTime.now());
    if (level >= 300) {
      return [
        CourseModel(
          'CSC 305',
          'Data Structures',
          creditUnits: 3,
          type: CourseType.core,
          level: level,
          semester: semester,
          academicSession: session,
          notes: true,
          pastQuestions: true,
          progress: 72,
        ),
        CourseModel(
          'CSC 309',
          'Artificial Intelligence',
          creditUnits: 3,
          type: CourseType.core,
          level: level,
          semester: semester,
          academicSession: session,
          notes: true,
          pastQuestions: true,
          progress: 40,
        ),
        CourseModel(
          'MTH 301',
          'Numerical Methods',
          creditUnits: 3,
          type: CourseType.core,
          level: level,
          semester: semester,
          academicSession: session,
          notes: true,
          pastQuestions: false,
          progress: 34,
        ),
        CourseModel(
          'SEN 301',
          'Software Requirements Engineering',
          creditUnits: 3,
          type: CourseType.core,
          level: level,
          semester: semester,
          academicSession: session,
          notes: true,
          pastQuestions: true,
          progress: 55,
        ),
      ];
    }

    return [
      CourseModel(
        'CSC 201',
        'Object Oriented Programming',
        creditUnits: 3,
        type: CourseType.core,
        level: level,
        semester: semester,
        academicSession: session,
      ),
      CourseModel(
        'MTH 201',
        'Discrete Mathematics',
        creditUnits: 3,
        type: CourseType.core,
        level: level,
        semester: semester,
        academicSession: session,
      ),
      CourseModel(
        'GST 201',
        'Use of English',
        creditUnits: 2,
        type: CourseType.core,
        level: level,
        semester: semester,
        academicSession: session,
      ),
    ];
  }

  static List<CourseModel> _electiveCourses({
    required int level,
    required int semester,
    StudentProfileModel? profile,
  }) {
    final session = _academicSession(DateTime.now());
    return [
      CourseModel(
        'CSC 311',
        'Mobile Application Development',
        creditUnits: 2,
        type: CourseType.elective,
        level: level,
        semester: semester,
        academicSession: session,
        notes: true,
        pastQuestions: true,
        progress: 10,
      ),
      CourseModel(
        'SEN 313',
        'Human Computer Interaction',
        creditUnits: 2,
        type: CourseType.elective,
        level: level,
        semester: semester,
        academicSession: session,
        notes: true,
        pastQuestions: false,
        progress: 8,
      ),
      CourseModel(
        'ENT 301',
        'Entrepreneurship Studies',
        creditUnits: 2,
        type: CourseType.elective,
        level: level,
        semester: semester,
        academicSession: session,
        notes: false,
        pastQuestions: true,
        progress: 20,
      ),
      CourseModel(
        'GST 303',
        'Communication in English',
        creditUnits: 2,
        type: CourseType.elective,
        level: level,
        semester: semester,
        academicSession: session,
        notes: false,
        pastQuestions: true,
        progress: 18,
      ),
    ];
  }

  static String _academicSession(DateTime date) {
    final startYear = date.month >= 9 ? date.year : date.year - 1;
    return '$startYear/${startYear + 1}';
  }
}
