import '../models/exam_models.dart';

class GradedSessionTemplate {
  const GradedSessionTemplate({
    required this.sections,
    required this.objectiveQuestions,
    required this.fillBlankQuestions,
    required this.theoryQuestions,
    required this.durationMinutes,
    required this.deliveryMode,
  });

  final List<String> sections;
  final int objectiveQuestions;
  final int fillBlankQuestions;
  final int theoryQuestions;
  final int durationMinutes;
  final ExamDeliveryMode deliveryMode;

  bool get hasObjective => sections.contains(ExamSectionType.objective);
  bool get hasFillBlank => sections.contains(ExamSectionType.fillBlank);
  bool get hasTheory => sections.contains(ExamSectionType.theory);
}

class GradedSessionTemplateService {
  GradedSessionTemplateService._();

  static const GradedSessionTemplate _assessmentDemoTemplate =
      GradedSessionTemplate(
        sections: [
          ExamSectionType.objective,
          ExamSectionType.fillBlank,
          ExamSectionType.theory,
        ],
        // Five-question demo sample: 3 CBT/objective + 1 fill-blank + 1 theory.
        objectiveQuestions: 3,
        fillBlankQuestions: 1,
        theoryQuestions: 1,
        durationMinutes: 20,
        deliveryMode: ExamDeliveryMode.remoteProctored,
      );

  // Backend placeholder. Replace with API payload from lecturer/admin panel.
  static GradedSessionTemplate? templateFor({
    required String courseCode,
    required String sessionType,
  }) {
    final code = courseCode.trim().toUpperCase();
    final isAssessment = sessionType == SessionType.assessment;

    if (code == 'CSC 305') {
      return isAssessment
          ? _assessmentDemoTemplate
          : const GradedSessionTemplate(
              sections: [
                ExamSectionType.objective,
                ExamSectionType.fillBlank,
                ExamSectionType.theory,
              ],
              objectiveQuestions: 40,
              fillBlankQuestions: 10,
              theoryQuestions: 2,
              durationMinutes: 120,
              deliveryMode: ExamDeliveryMode.remoteProctored,
            );
    }

    if (code == 'MTH 202') {
      return isAssessment
          ? _assessmentDemoTemplate
          : const GradedSessionTemplate(
              sections: [
                ExamSectionType.objective,
                ExamSectionType.fillBlank,
                ExamSectionType.theory,
              ],
              objectiveQuestions: 35,
              fillBlankQuestions: 12,
              theoryQuestions: 2,
              durationMinutes: 110,
              deliveryMode: ExamDeliveryMode.remoteProctored,
            );
    }

    if (code == 'GST 201') {
      return isAssessment
          ? _assessmentDemoTemplate
          : const GradedSessionTemplate(
              sections: [
                ExamSectionType.objective,
                ExamSectionType.fillBlank,
                ExamSectionType.theory,
              ],
              objectiveQuestions: 30,
              fillBlankQuestions: 8,
              theoryQuestions: 2,
              durationMinutes: 90,
              deliveryMode: ExamDeliveryMode.remoteProctored,
            );
    }

    return isAssessment
        ? _assessmentDemoTemplate
        : const GradedSessionTemplate(
            sections: [
              ExamSectionType.objective,
              ExamSectionType.fillBlank,
              ExamSectionType.theory,
            ],
            objectiveQuestions: 30,
            fillBlankQuestions: 10,
            theoryQuestions: 2,
            durationMinutes: 100,
            deliveryMode: ExamDeliveryMode.remoteProctored,
          );
  }
}
