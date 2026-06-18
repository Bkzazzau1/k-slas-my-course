import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../features/identity_trust/view/student_face_enrollment_view.dart';
import '../../exam/view/exam_setup_view.dart';

class DemoExamFaceOnlyView extends StatelessWidget {
  const DemoExamFaceOnlyView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DemoExamFaceOnlyController());

    return Obx(() {
      final width = MediaQuery.sizeOf(context).width;
      final useRail = width >= 820;
      final page = IndexedStack(
        index: controller.index.value,
        children: const [
          ExamSetupView(),
          StudentFaceEnrollmentView(),
        ],
      );

      return Scaffold(
        appBar: AppBar(
          title: const Text('K-SLAS Demo'),
          centerTitle: false,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Exam + Face ID only',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        body: Row(
          children: [
            if (useRail)
              NavigationRail(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                extended: width >= 1100,
                leading: const Padding(
                  padding: EdgeInsets.fromLTRB(10, 18, 10, 18),
                  child: _DemoBadge(),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment_turned_in),
                    label: Text('Exams'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.face_retouching_natural_outlined),
                    selectedIcon: Icon(Icons.face_retouching_natural),
                    label: Text('Face ID'),
                  ),
                ],
              ),
            Expanded(child: page),
          ],
        ),
        bottomNavigationBar: useRail
            ? null
            : NavigationBar(
                selectedIndex: controller.index.value,
                onDestinationSelected: controller.setIndex,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.assignment_outlined),
                    selectedIcon: Icon(Icons.assignment_turned_in),
                    label: 'Exams',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.face_retouching_natural_outlined),
                    selectedIcon: Icon(Icons.face_retouching_natural),
                    label: 'Face ID',
                  ),
                ],
              ),
      );
    });
  }
}

class DemoExamFaceOnlyController extends GetxController {
  final index = 0.obs;

  void setIndex(int value) => index.value = value;
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white),
    );
  }
}
