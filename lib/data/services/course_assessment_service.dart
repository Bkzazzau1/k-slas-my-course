import '../models/course_assessment_model.dart';
import '../models/course_model.dart';
import '../models/exam_models.dart';
import 'cbt_attempt_storage.dart';
import 'graded_session_template_service.dart';

class CourseAssessmentService {
  CourseAssessmentService._();

  static Future<CourseAssessmentSummary> summaryFor(CourseModel course) async {
    final assessments = await fetchAssessments(course);
    final attempts = CBTAttemptStorage.loadAttempts(course.code)
        .where((attempt) => attempt.sessionType == SessionType.assessment)
        .toList();

    final completed = <String>{};
    for (final assessment in assessments) {
      final hasAttempt = attempts.any(
        (attempt) => attempt.gradingType == assessment.gradingType,
      );
      if (hasAttempt) completed.add(assessment.id);
    }

    return CourseAssessmentSummary(
      courseCode: course.code,
      assessments: assessments,
      completedIds: completed,
    );
  }

  static Future<List<CourseAssessmentModel>> fetchAssessments(
    CourseModel course,
  ) async {
    final code = course.code.trim().toUpperCase();
    final template = GradedSessionTemplateService.templateFor(
      courseCode: code,
      sessionType: SessionType.assessment,
    );

    return [
      if (template != null)
        CourseAssessmentModel(
          id: '$code-graded-assessment',
          courseCode: code,
          title: '${course.title} graded assessment',
          gradingType: GradingType.graded,
          kind: _kindLabel(template),
          durationMinutes: template.durationMinutes,
        ),
      CourseAssessmentModel(
        id: '$code-ungraded-practice',
        courseCode: code,
        title: '${course.title} ungraded practice',
        gradingType: GradingType.ungraded,
        kind: 'Practice CBT',
        durationMinutes: 20,
      ),
    ];
  }

  static String _kindLabel(GradedSessionTemplate template) {
    final parts = <String>[
      if (template.hasObjective) 'CBT',
      if (template.hasFillBlank) 'Fill',
      if (template.hasTheory) 'Theory',
    ];
    return parts.isEmpty ? 'Assessment' : parts.join(' + ');
  }
}
