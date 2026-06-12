import 'exam_models.dart';

class CourseAssessmentModel {
  const CourseAssessmentModel({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.gradingType,
    required this.kind,
    required this.durationMinutes,
    this.availableAt,
    this.dueAt,
  });

  final String id;
  final String courseCode;
  final String title;
  final String gradingType;
  final String kind;
  final int durationMinutes;
  final DateTime? availableAt;
  final DateTime? dueAt;

  bool get isGraded => gradingType == GradingType.graded;
}

class CourseAssessmentSummary {
  const CourseAssessmentSummary({
    required this.courseCode,
    required this.assessments,
    required this.completedIds,
  });

  final String courseCode;
  final List<CourseAssessmentModel> assessments;
  final Set<String> completedIds;

  int get gradedTotal =>
      assessments.where((assessment) => assessment.isGraded).length;
  int get ungradedTotal =>
      assessments.where((assessment) => !assessment.isGraded).length;

  int get gradedCompleted => assessments
      .where(
        (assessment) =>
            assessment.isGraded && completedIds.contains(assessment.id),
      )
      .length;
  int get ungradedCompleted => assessments
      .where(
        (assessment) =>
            !assessment.isGraded && completedIds.contains(assessment.id),
      )
      .length;

  int get gradedPending =>
      (gradedTotal - gradedCompleted).clamp(0, gradedTotal).toInt();
  int get ungradedPending =>
      (ungradedTotal - ungradedCompleted).clamp(0, ungradedTotal).toInt();
}
