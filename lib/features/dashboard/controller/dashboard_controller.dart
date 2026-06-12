import 'dart:async';

import 'package:get/get.dart';

import '../../../data/models/assignment_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/performance_model.dart';
import '../../../data/models/practice_models.dart';
import '../../../data/models/student_category.dart';
import '../../../data/services/assignment_service.dart';
import '../../../data/services/assignment_submission_storage.dart';
import '../../../data/services/practice_storage_service.dart';
import '../../../data/services/study_plan_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/weak_topics_service.dart';
import '../../../modules/revision/controller/revision_controller.dart';
import '../../../modules/settings/controller/settings_controller.dart';
import '../../../modules/timetable/controller/timetable_controller.dart';

class ExamModel {
  ExamModel({
    required this.courseCode,
    required this.title,
    required this.dateLabel,
    required this.location,
    required this.daysLeft,
    required this.deliveryMode,
  });

  final String courseCode;
  final String title;
  final String dateLabel;
  final String location;
  final int daysLeft;
  final ExamDeliveryMode deliveryMode;

  bool get isRemoteProctored =>
      deliveryMode == ExamDeliveryMode.remoteProctored;

  String get deliveryLabel {
    return isRemoteProctored ? 'Remote (Proctored)' : 'Distance Self-Practice';
  }
}

class DashboardController extends GetxController {
  // pull Settings values from SettingsController
  late final SettingsController settings;

  // MVP data sources (later from backend/school calendar)
  final courses = <CourseModel>[].obs;
  final weakTopics = <String>[].obs;

  final nextExam = Rxn<ExamModel>();
  final studyNow = Rxn<StudyRecommendation>();

  final performance = Rxn<PerformanceModel>();
  final attempts = <PracticeAttemptModel>[].obs;
  final assignments = <AssignmentModel>[].obs;
  final assignmentSubmissions = <String, AssignmentSubmissionModel>{}.obs;

  // UI state (for skeletons / smooth loading)
  final isLoading = false.obs;

  // Profile-like UI fields (MVP now, backend later)
  final studentName = "Zainab".obs;
  final studentProgramLine =
      StudentCategory.distanceUndergraduate.programLineLabel.obs;
  final studentCategory = StudentCategory.distanceUndergraduate.obs;
  final studentMode = StudentAccessMode.distance.obs;

  // Streak
  final streakDays = 0.obs;

  @override
  void onInit() {
    super.onInit();
    settings = Get.find<SettingsController>();
    _hydrateStudentProfile();
    _syncStudentCategoryFromProgramLine();

    // MVP sample courses
    courses.assignAll([
      CourseModel(
        'CSC 305',
        'Data Structures',
        notes: true,
        pastQuestions: true,
        progress: 72,
      ),
      CourseModel(
        'MTH 202',
        'Linear Algebra',
        notes: true,
        pastQuestions: false,
        progress: 48,
      ),
      CourseModel(
        'GST 201',
        'Use of English',
        notes: false,
        pastQuestions: true,
        progress: 54,
      ),
    ]);

    final tt = Get.find<TimetableController>();
    final e = tt.getNextExam();
    if (e != null) {
      nextExam.value = ExamModel(
        courseCode: e.courseCode,
        title: e.title,
        dateLabel:
            "${e.start.day.toString().padLeft(2, '0')}/${e.start.month.toString().padLeft(2, '0')} • "
            "${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}",
        location: e.location,
        daysLeft: e.start.difference(DateTime.now()).inDays,
        deliveryMode: e.deliveryMode,
      );
    }

    final rev = Get.find<RevisionPlanController>();
    rev.loadFromStorage();
    final primaryCourse = courses.isNotEmpty
        ? courses.first.code
        : (e?.courseCode ?? "CSC 305");
    rev.loadForCourse(primaryCourse);

    streakDays.value = PracticeStorageService.loadStreak();
    refreshFromAttempts();
    unawaited(loadAssignments());

    // Update recommendation whenever exam mode changes
    ever(settings.examMode, (_) => _rebuildRecommendation());
    ever(studentProgramLine, (_) => _syncStudentCategoryFromProgramLine());
  }

  void _hydrateStudentProfile() {
    final profile = StudentProfileStorage.load();
    if (profile == null) return;

    final fullName = profile.fullName.trim();
    if (fullName.isNotEmpty) {
      studentName.value = fullName;
    }

    final storedCategoryKey = profile.studentCategoryKey?.trim() ?? '';
    if (storedCategoryKey.isEmpty) return;

    final resolvedCategory = studentCategoryFromStorage(storedCategoryKey);
    studentCategory.value = resolvedCategory;
    studentMode.value = resolvedCategory.accessMode;
    studentProgramLine.value = resolvedCategory.programLineLabel;
  }

  void _syncStudentCategoryFromProgramLine() {
    final resolvedCategory = inferStudentCategoryFromProgramLine(
      studentProgramLine.value,
    );
    studentCategory.value = resolvedCategory;
    studentMode.value = resolvedCategory.accessMode;
  }

  bool get canSeeIntegrity => studentCategory.value.requiresIntegritySync;

  bool get canSeeExams => studentCategory.value.canAccessExamSuite;

  bool get canSeeQuizzes => studentCategory.value.canAccessAssessmentSuite;

  String get lowDataSectionTitle => studentCategory.value.requiresIntegritySync
      ? "Low-data & Integrity Sync"
      : "Low-data & Offline";

  bool get shouldShowIntegrityCard {
    return nextExam.value?.isRemoteProctored == true;
  }

  void _rebuildRecommendation() {
    final exam = nextExam.value;
    final daysLeft = exam?.daysLeft ?? 14;

    // pick the course matching the next exam, or fallback to first/placeholder
    final c = (exam != null)
        ? (courses.firstWhereOrNull((x) => x.code == exam.courseCode) ??
              courses.first)
        : (courses.isNotEmpty
              ? courses.first
              : CourseModel("CSC 305", "Course"));

    studyNow.value = StudyPlanService.recommend(
      course: c,
      weakTopics: weakTopics,
      daysToExam: daysLeft,
      examMode: settings.examMode.value,
    );
  }

  void refreshFromAttempts() {
    final exam = nextExam.value;
    final courseCode =
        exam?.courseCode ??
        (courses.isNotEmpty ? courses.first.code : "CSC 305");

    // load practice attempts (still used for performance tiles)
    final list = PracticeStorageService.loadAttempts(courseCode);
    attempts.assignAll(list);

    // ✅ Real weak topics from CBT analytics (topicStats)
    final computed = WeakTopicsService.computeWeakTopics(
      courseCode,
      lastNAttempts: 5,
      minEvidenceCount: 1,
    );

    if (computed.isEmpty) {
      weakTopics.assignAll(["Revision"]);
    } else {
      weakTopics.assignAll(computed.take(3).map((e) => e.topic).toList());
    }

    if (list.isNotEmpty) {
      final last10 = list.take(10).toList();
      final totalQ = last10.fold<int>(0, (p, x) => p + x.total);
      final totalC = last10.fold<int>(0, (p, x) => p + x.correct);
      final acc = totalQ == 0 ? 0 : ((totalC / totalQ) * 100).round();

      final totalSec = last10.fold<int>(0, (p, x) => p + x.durationSec);
      final h = totalSec ~/ 3600;
      final m = (totalSec % 3600) ~/ 60;
      final timeLabel = h > 0 ? "${h}h ${m}m" : "${m}m";

      final streak = streakDays.value;
      performance.value = PerformanceModel(
        accuracyPct: acc,
        studyTimeLabel: timeLabel.isEmpty ? "0m" : timeLabel,
        consistencyLabel: "$streak-day streak",
      );
    } else {
      performance.value = PerformanceModel(
        accuracyPct: 0,
        studyTimeLabel: "0m",
        consistencyLabel: "${streakDays.value}-day streak",
      );
    }

    _rebuildRecommendation();
  }

  Future<void> loadAssignments() async {
    final list = await AssignmentService.fetchAssignedAssignments()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
    assignments.assignAll(list);
    _refreshAssignmentSubmissions();
  }

  void _refreshAssignmentSubmissions() {
    final map = <String, AssignmentSubmissionModel>{};
    for (final item in assignments) {
      final submission = AssignmentSubmissionStorage.loadSubmission(item.id);
      if (submission != null) {
        map[item.id] = submission;
      }
    }
    assignmentSubmissions.assignAll(map);
  }

  Future<void> refreshAssignmentsBoard() {
    return loadAssignments();
  }

  bool isAssignmentSubmitted(String assignmentId) {
    return assignmentSubmissions.containsKey(assignmentId);
  }

  bool isAssignmentOverdue(AssignmentModel assignment) {
    return DateTime.now().isAfter(assignment.deadline);
  }

  int get pendingAssignmentsCount {
    return assignments
        .where((a) => !isAssignmentSubmitted(a.id) && !isAssignmentOverdue(a))
        .length;
  }

  List<AssignmentModel> get upcomingAssignments {
    return assignments.take(3).toList();
  }

  Future<void> bumpStreak() async {
    final today = DateTime.now();
    final key =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final last = PracticeStorageService.loadLastStudyDay();

    if (last == key) return;

    int newStreak = 1;
    if (last != null) {
      final parts = last.split('-');
      if (parts.length == 3) {
        final prev = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final diff = today.difference(prev).inDays;
        if (diff == 1) newStreak = (streakDays.value + 1);
      }
    }

    streakDays.value = newStreak;
    await PracticeStorageService.setStreak(newStreak);
    await PracticeStorageService.setLastStudyDay(key);

    refreshFromAttempts();
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return "Good morning";
    if (h < 17) return "Good afternoon";
    return "Good evening";
  }

  String get headerTitle => "$greeting, ${studentName.value} 👋";

  String? get nextExamPillText {
    final e = nextExam.value;
    if (e == null) return null;
    final d = e.daysLeft;
    if (d < 0) return "Exam started";
    if (d == 0) return "Exam today";
    if (d == 1) return "Next exam tomorrow";
    return "Next exam in $d days";
  }
}
