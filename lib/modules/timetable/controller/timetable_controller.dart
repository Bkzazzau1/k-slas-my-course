import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/exam_models.dart';
import '../../../data/models/timetable_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/timetable_storage.dart';
import '../../../features/dashboard/controller/dashboard_controller.dart';

class TimetableController extends GetxController {
  final tabIndex = 0.obs; // 0=Classes, 1=Exams
  final classEvents = <TimetableEventModel>[].obs;
  final examEvents = <TimetableEventModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
    _seedIfEmpty();
  }

  void _load() {
    classEvents.assignAll(TimetableStorage.loadClasses());
    examEvents.assignAll(TimetableStorage.loadExams());
    _sort();
  }

  void _sort() {
    classEvents.sort((a, b) => a.start.compareTo(b.start));
    examEvents.sort((a, b) => a.start.compareTo(b.start));
  }

  Future<void> _seedIfEmpty() async {
    // MVP: seed based on profile selected courses
    final profile = StudentProfileStorage.load();
    if (profile == null) return;

    if (classEvents.isEmpty) {
      classEvents.assignAll(_mockClassSeed(profile.selectedCourses));
      await TimetableStorage.saveClasses(classEvents);
    }

    if (examEvents.isEmpty) {
      examEvents.assignAll(_mockExamSeed(profile.selectedCourses));
      await TimetableStorage.saveExams(examEvents);
    }

    _sort();
    update(); // refresh views
  }

  List<TimetableEventModel> _mockClassSeed(List<String> courseCodes) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: (now.weekday - 1)));

    // simple seed (Mon/Wed/Fri)
    final items = <TimetableEventModel>[];
    final uuid = const Uuid();

    for (final code in courseCodes.take(3)) {
      items.add(
        TimetableEventModel(
          id: uuid.v4(),
          type: TimetableType.classes,
          courseCode: code,
          title: "$code Lecture",
          start: DateTime(monday.year, monday.month, monday.day, 9, 0),
          end: DateTime(monday.year, monday.month, monday.day, 10, 0),
          location: "LT 2",
          dayOfWeek: 1,
          isReadOnly: true,
        ),
      );
      items.add(
        TimetableEventModel(
          id: uuid.v4(),
          type: TimetableType.classes,
          courseCode: code,
          title: "$code Tutorial",
          start: DateTime(monday.year, monday.month, monday.day + 2, 11, 0),
          end: DateTime(monday.year, monday.month, monday.day + 2, 12, 0),
          location: "Room 14",
          dayOfWeek: 3,
          isReadOnly: true,
        ),
      );
    }
    return items;
  }

  List<TimetableEventModel> _mockExamSeed(List<String> courseCodes) {
    final uuid = const Uuid();
    final base = DateTime.now().add(const Duration(days: 10));

    final items = <TimetableEventModel>[];
    for (int i = 0; i < courseCodes.take(3).length; i++) {
      final code = courseCodes[i];
      final d = base.add(Duration(days: i * 2));
      items.add(
        TimetableEventModel(
          id: uuid.v4(),
          type: TimetableType.exams,
          courseCode: code,
          title: "$code Exam",
          start: DateTime(d.year, d.month, d.day, 9, 0),
          end: DateTime(d.year, d.month, d.day, 12, 0),
          location: "Remote LMS",
          deliveryMode: ExamDeliveryMode.remoteProctored,
          isReadOnly: true,
        ),
      );
    }
    return items;
  }

  // Student-created (editable) events only
  Future<void> addCustomEvent({
    required String type,
    required String courseCode,
    required String title,
    required DateTime start,
    required DateTime end,
    required String location,
    int? dayOfWeek,
  }) async {
    final uuid = const Uuid();
    final e = TimetableEventModel(
      id: uuid.v4(),
      type: type,
      courseCode: courseCode,
      title: title,
      start: start,
      end: end,
      location: location,
      dayOfWeek: dayOfWeek,
      isReadOnly: false,
    );

    if (type == TimetableType.exams) {
      examEvents.add(e);
      _sort();
      await TimetableStorage.saveExams(examEvents);
    } else {
      classEvents.add(e);
      _sort();
      await TimetableStorage.saveClasses(classEvents);
    }

    try {
      final dash = Get.find<DashboardController>();
      dash.refreshFromAttempts();
    } catch (_) {}
  }

  Future<void> deleteEvent(TimetableEventModel e) async {
    if (e.isReadOnly) return; // curated locked
    if (e.type == TimetableType.exams) {
      examEvents.removeWhere((x) => x.id == e.id);
      await TimetableStorage.saveExams(examEvents);
    } else {
      classEvents.removeWhere((x) => x.id == e.id);
      await TimetableStorage.saveClasses(classEvents);
    }

    try {
      final dash = Get.find<DashboardController>();
      dash.refreshFromAttempts();
    } catch (_) {}
  }

  // For dashboard “Next exam”
  TimetableEventModel? getNextExam() {
    final now = DateTime.now();
    final upcoming = examEvents.where((e) => e.start.isAfter(now)).toList();
    upcoming.sort((a, b) => a.start.compareTo(b.start));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
