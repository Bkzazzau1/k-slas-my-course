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

  static const GradedSessionTemplate _demoTemplate = GradedSessionTemplate(
    sections: [
      ExamSectionType.objective,
      ExamSectionType.fillBlank,
      ExamSectionType.theory,
    ],
    objectiveQuestions: 3,
    fillBlankQuestions: 1,
    theoryQuestions: 1,
    durationMinutes: 30,
    deliveryMode: ExamDeliveryMode.remoteProctored,
  );

  static GradedSessionTemplate? templateFor({
    required String courseCode,
    required String sessionType,
  }) {
    return _demoTemplate;
  }
}
