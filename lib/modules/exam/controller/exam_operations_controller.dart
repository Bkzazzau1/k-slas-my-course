import 'package:get/get.dart';

import '../../../data/services/exam_proctoring_backend_service.dart';

enum ExamOpsRole { officer, invigilator }

enum ExamOpsStatus {
  lecturerSubmitted,
  officerReview,
  invigilatorAssigned,
  released,
  submittedToOfficer,
  sharedForMarking,
  marked,
}

class ExamOpsExam {
  const ExamOpsExam({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.lecturerName,
    required this.examOfficerName,
    required this.invigilatorName,
    required this.startsAt,
    required this.durationMinutes,
    required this.status,
    required this.deliveryMode,
    required this.questionSummary,
    required this.submissionSummary,
    this.lecturerComment,
  });

  final String id;
  final String courseCode;
  final String title;
  final String lecturerName;
  final String examOfficerName;
  final String invigilatorName;
  final DateTime startsAt;
  final int durationMinutes;
  final ExamOpsStatus status;
  final String deliveryMode;
  final String questionSummary;
  final String submissionSummary;
  final String? lecturerComment;

  ExamOpsExam copyWith({ExamOpsStatus? status, String? lecturerComment}) {
    return ExamOpsExam(
      id: id,
      courseCode: courseCode,
      title: title,
      lecturerName: lecturerName,
      examOfficerName: examOfficerName,
      invigilatorName: invigilatorName,
      startsAt: startsAt,
      durationMinutes: durationMinutes,
      status: status ?? this.status,
      deliveryMode: deliveryMode,
      questionSummary: questionSummary,
      submissionSummary: submissionSummary,
      lecturerComment: lecturerComment ?? this.lecturerComment,
    );
  }
}

class InvigilatorAlert {
  const InvigilatorAlert({
    required this.id,
    required this.examId,
    required this.studentName,
    required this.eventType,
    required this.message,
    required this.severity,
    required this.integrityScore,
    required this.createdAt,
    this.acknowledged = false,
  });

  final String id;
  final String examId;
  final String studentName;
  final String eventType;
  final String message;
  final String severity;
  final int integrityScore;
  final DateTime createdAt;
  final bool acknowledged;

  InvigilatorAlert copyWith({bool? acknowledged}) {
    return InvigilatorAlert(
      id: id,
      examId: examId,
      studentName: studentName,
      eventType: eventType,
      message: message,
      severity: severity,
      integrityScore: integrityScore,
      createdAt: createdAt,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}

class ExamOperationsController extends GetxController {
  final role = ExamOpsRole.officer.obs;
  final exams = <ExamOpsExam>[].obs;
  final alerts = <InvigilatorAlert>[].obs;
  final isLoadingAlerts = false.obs;

  @override
  void onInit() {
    super.onInit();
    _seedDemo();
    refreshAlerts();
  }

  void switchRole(ExamOpsRole next) {
    role.value = next;
  }

  Future<void> refreshAlerts() async {
    isLoadingAlerts.value = true;
    try {
      final remote =
          await ExamProctoringBackendService.fetchInvigilatorAlerts();
      if (remote.isNotEmpty) {
        alerts.assignAll(remote.map(_alertFromBackend).toList());
      }
    } finally {
      isLoadingAlerts.value = false;
    }
  }

  void assignInvigilator(String examId) {
    _updateExamStatus(examId, ExamOpsStatus.invigilatorAssigned);
    Get.snackbar(
      'Invigilator assigned',
      'The assigned invigilator will receive live alerts for this exam.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void releaseExam(String examId) {
    _updateExamStatus(examId, ExamOpsStatus.released);
    Get.snackbar(
      'Exam released',
      'Students can now start the exam during the scheduled window.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void shareWithLecturer(String examId) {
    _updateExamStatus(examId, ExamOpsStatus.sharedForMarking);
    Get.snackbar(
      'Shared for marking',
      'Submitted scripts are now visible to the lecturer as read-only scripts.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void addLecturerComment(String examId, String comment) {
    final cleaned = comment.trim();
    if (cleaned.isEmpty) return;
    final index = exams.indexWhere((item) => item.id == examId);
    if (index == -1) return;
    exams[index] = exams[index].copyWith(lecturerComment: cleaned);
    exams.refresh();
    Get.snackbar(
      'Comment added',
      'The lecturer comment was saved without editing the submitted script.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void acknowledgeAlert(String alertId) {
    final index = alerts.indexWhere((item) => item.id == alertId);
    if (index == -1) return;
    alerts[index] = alerts[index].copyWith(acknowledged: true);
    alerts.refresh();
  }

  int get pendingAlertCount =>
      alerts.where((item) => !item.acknowledged).length;

  void _updateExamStatus(String examId, ExamOpsStatus status) {
    final index = exams.indexWhere((item) => item.id == examId);
    if (index == -1) return;
    exams[index] = exams[index].copyWith(status: status);
    exams.refresh();
  }

  InvigilatorAlert _alertFromBackend(Map<String, dynamic> item) {
    return InvigilatorAlert(
      id: (item['id'] ?? '').toString(),
      examId: (item['exam_id'] ?? '').toString(),
      studentName: 'Student #${item['student_id'] ?? ''}',
      eventType: (item['event_type'] ?? 'integrity').toString(),
      message: (item['message'] ?? '').toString(),
      severity: (item['severity'] ?? 'warning').toString(),
      integrityScore:
          int.tryParse((item['integrity_score'] ?? '').toString()) ?? 100,
      createdAt:
          DateTime.tryParse((item['created_at'] ?? '').toString()) ??
          DateTime.now(),
      acknowledged: item['acknowledged_at'] != null,
    );
  }

  void _seedDemo() {
    final now = DateTime.now();
    exams.assignAll([
      ExamOpsExam(
        id: 'exam-csc305-final',
        courseCode: 'CSC 305',
        title: 'Algorithms Final Examination',
        lecturerName: 'Dr. Musa',
        examOfficerName: 'Mrs. Halima Yusuf',
        invigilatorName: 'Mr. Adewale K.',
        startsAt: now.add(const Duration(days: 2, hours: 3)),
        durationMinutes: 120,
        status: ExamOpsStatus.officerReview,
        deliveryMode: 'Remote proctored',
        questionSummary: '40 CBT, 5 fill-blank, 2 theory questions',
        submissionSummary:
            'Lecturer submitted questions. Officer review pending.',
      ),
      ExamOpsExam(
        id: 'exam-mth202-mid',
        courseCode: 'MTH 202',
        title: 'Linear Algebra Mid-Semester Assessment',
        lecturerName: 'Dr. Bala',
        examOfficerName: 'Mrs. Halima Yusuf',
        invigilatorName: 'Aisha Bello',
        startsAt: now.add(const Duration(days: 1, hours: 5)),
        durationMinutes: 75,
        status: ExamOpsStatus.released,
        deliveryMode: 'Center-based',
        questionSummary: '25 CBT, 3 theory questions',
        submissionSummary:
            'Released. Invigilator assigned and timetable confirmed.',
      ),
      ExamOpsExam(
        id: 'exam-gst201-sub',
        courseCode: 'GST 201',
        title: 'Communication Skills Assessment',
        lecturerName: 'Ms. Grace',
        examOfficerName: 'Mrs. Halima Yusuf',
        invigilatorName: 'Mr. Adewale K.',
        startsAt: now.subtract(const Duration(hours: 6)),
        durationMinutes: 60,
        status: ExamOpsStatus.submittedToOfficer,
        deliveryMode: 'Remote proctored',
        questionSummary: '20 CBT, 1 essay response',
        submissionSummary:
            '47 scripts submitted to exam officer. Awaiting lecturer handoff.',
      ),
    ]);

    alerts.assignAll([
      InvigilatorAlert(
        id: 'alert-001',
        examId: 'exam-csc305-final',
        studentName: 'Zainab Ibrahim',
        eventType: 'audio',
        message: 'Speech-like audio detected after monitoring was armed.',
        severity: 'warning',
        integrityScore: 82,
        createdAt: now.subtract(const Duration(minutes: 6)),
      ),
      InvigilatorAlert(
        id: 'alert-002',
        examId: 'exam-csc305-final',
        studentName: 'Sani Abdullahi',
        eventType: 'camera',
        message: 'Multiple faces detected. Environment scan requested.',
        severity: 'critical',
        integrityScore: 64,
        createdAt: now.subtract(const Duration(minutes: 11)),
      ),
      InvigilatorAlert(
        id: 'alert-003',
        examId: 'exam-mth202-mid',
        studentName: 'Nana Yusuf',
        eventType: 'app_background',
        message: 'App moved to background during graded assessment.',
        severity: 'warning',
        integrityScore: 76,
        createdAt: now.subtract(const Duration(minutes: 18)),
        acknowledged: true,
      ),
    ]);
  }
}
