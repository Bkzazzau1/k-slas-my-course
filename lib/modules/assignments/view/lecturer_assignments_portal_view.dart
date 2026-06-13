import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/assignments_controller.dart';
import 'assignments_view.dart';

class LecturerAssignmentsPortalView extends StatefulWidget {
  const LecturerAssignmentsPortalView({super.key});

  @override
  State<LecturerAssignmentsPortalView> createState() =>
      _LecturerAssignmentsPortalViewState();
}

class _LecturerAssignmentsPortalViewState
    extends State<LecturerAssignmentsPortalView> {
  late final AssignmentsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AssignmentsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.switchDemoRole(lecturer: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const AssignmentsView();
  }
}
