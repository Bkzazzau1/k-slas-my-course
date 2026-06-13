import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/live_session_models.dart';
import '../widgets/live_class_attendance_report_overlay.dart';
import '../widgets/live_class_auto_alert_overlay.dart';
import '../widgets/live_class_malpractice_report_overlay.dart';
import '../widgets/live_class_moderation_overlay.dart';
import '../widgets/live_class_student_attendance_overlay.dart';
import '../widgets/live_class_student_moderation_guard.dart';
import '../widgets/live_screen_share_approval_overlay.dart';
import 'live_classroom_professional_shell.dart';
import 'student_live_class_room_view.dart';

class LiveSessionRoomView extends StatelessWidget {
  const LiveSessionRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments ?? {}) as Map;
    final role = args['role']?.toString() ?? LiveSessionRole.student;
    final sessionId = args['sessionId']?.toString() ?? '';

    if (role == LiveSessionRole.student) {
      final registrationNumber = args['registrationNumber']?.toString() ?? '';
      final participantId = registrationNumber.trim().isEmpty
          ? ''
          : 'student-${registrationNumber.toLowerCase()}';
      return LiveClassStudentAttendanceOverlay(
        sessionId: sessionId,
        enabled: true,
        child: LiveClassStudentModerationGuard(
          sessionId: sessionId,
          participantId: participantId,
          enabled: true,
          child: const StudentLiveClassRoomView(),
        ),
      );
    }

    final lecturerName =
        args['displayName']?.toString() ??
        args['lecturerName']?.toString() ??
        'Course lecturer';

    return LiveClassAutoAlertOverlay(
      sessionId: sessionId,
      reviewerName: lecturerName,
      reviewerRole: role,
      enabled: role == LiveSessionRole.lecturer,
      child: LiveClassMalpracticeReportOverlay(
        sessionId: sessionId,
        reporterName: lecturerName,
        reporterRole: role,
        enabled: role == LiveSessionRole.lecturer,
        child: LiveClassAttendanceReportOverlay(
          sessionId: sessionId,
          enabled: role == LiveSessionRole.lecturer,
          child: LiveClassModerationOverlay(
            sessionId: sessionId,
            lecturerName: lecturerName,
            enabled: role == LiveSessionRole.lecturer,
            child: LiveScreenShareApprovalOverlay(
              sessionId: sessionId,
              lecturerName: lecturerName,
              enabled: role == LiveSessionRole.lecturer,
              child: const LiveClassroomProfessionalShell(),
            ),
          ),
        ),
      ),
    );
  }
}
