import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/live_session_models.dart';
import '../widgets/live_screen_share_approval_overlay.dart';
import 'live_classroom_professional_shell.dart';
import 'student_live_class_room_view.dart';

class LiveSessionRoomView extends StatelessWidget {
  const LiveSessionRoomView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (Get.arguments ?? {}) as Map;
    final role = args['role']?.toString() ?? LiveSessionRole.student;
    if (role == LiveSessionRole.student) {
      return const StudentLiveClassRoomView();
    }

    final sessionId = args['sessionId']?.toString() ?? '';
    final lecturerName =
        args['displayName']?.toString() ??
        args['lecturerName']?.toString() ??
        'Course lecturer';

    return LiveScreenShareApprovalOverlay(
      sessionId: sessionId,
      lecturerName: lecturerName,
      enabled: role == LiveSessionRole.lecturer,
      child: const LiveClassroomProfessionalShell(),
    );
  }
}
