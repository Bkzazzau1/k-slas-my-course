class CourseDrawingPolicy {
  const CourseDrawingPolicy({
    required this.whiteboardEnabledForGraded,
    this.whiteboardRequired = false,
    this.prompt,
  });

  final bool whiteboardEnabledForGraded;
  final bool whiteboardRequired;
  final String? prompt;
}

class DrawingRequirementService {
  DrawingRequirementService._();

  // Mirrors backend policy shape until API wiring is completed.
  static CourseDrawingPolicy policyForCourse(String courseCode) {
    final normalized = courseCode.trim().toUpperCase();

    if (normalized == 'CSC 305') {
      return const CourseDrawingPolicy(
        whiteboardEnabledForGraded: true,
        whiteboardRequired: true,
        prompt:
            'Draw the graph/flow diagram requested by your lecturer. Label all nodes clearly.',
      );
    }

    if (normalized == 'MTH 202') {
      return const CourseDrawingPolicy(
        whiteboardEnabledForGraded: true,
        whiteboardRequired: true,
        prompt:
            'Draw matrix transformation or decomposition steps where required.',
      );
    }

    return const CourseDrawingPolicy(whiteboardEnabledForGraded: false);
  }
}
