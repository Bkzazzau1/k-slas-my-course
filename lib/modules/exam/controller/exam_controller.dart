import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../data/models/exam_models.dart';

class ExamController extends GetxController {
  final config = Rxn<ExamConfig>();
  final sectionScores = <ExamSectionScore>[].obs;
  final whiteboardStrokes = <WhiteboardStroke>[].obs;

  DateTime? _startedAt;

  void startExam(ExamConfig c) {
    config.value = c;
    sectionScores.clear();
    whiteboardStrokes.clear();
    _startedAt = DateTime.now();
  }

  void addSectionScore(ExamSectionScore s) {
    // replace if same section already exists
    final idx = sectionScores.indexWhere((e) => e.sectionType == s.sectionType);
    if (idx >= 0) {
      sectionScores[idx] = s;
    } else {
      sectionScores.add(s);
    }
  }

  void saveWhiteboardStrokes(List<WhiteboardStroke> strokes) {
    whiteboardStrokes.assignAll(strokes.where((s) => s.isUsable));
  }

  bool get hasWhiteboardSketch => whiteboardStrokes.isNotEmpty;

  ExamResult finalize() {
    final now = DateTime.now();
    final cfg = config.value;
    return ExamResult(
      courseCode: cfg?.courseCode ?? "UNKNOWN",
      sessionType: cfg?.sessionType ?? SessionType.examination,
      gradingType: cfg?.gradingType ?? GradingType.ungraded,
      startedAt: _startedAt ?? now,
      endedAt: now,
      sectionScores: sectionScores.toList(),
      deliveryMode: cfg?.deliveryMode ?? ExamDeliveryMode.remoteProctored,
      whiteboardEnabled: cfg?.whiteboardEnabled == true,
      whiteboardRequired: cfg?.whiteboardRequired == true,
      whiteboardSubmitted: whiteboardStrokes.isNotEmpty,
      whiteboardStrokeCount: whiteboardStrokes.length,
      whiteboardPrompt: cfg?.whiteboardPrompt,
    );
  }
}
