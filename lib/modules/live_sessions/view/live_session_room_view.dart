import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/live_session_models.dart';
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
    return const LiveClassroomProfessionalShell();
  }
}
