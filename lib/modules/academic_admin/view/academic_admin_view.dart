import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/academic_admin_model.dart';
import '../../../data/models/course_model.dart';
import '../controller/academic_admin_controller.dart';

class AcademicAdminView extends GetView<AcademicAdminController> {
  const AcademicAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Obx(
                () => _Header(
                  cs: cs,
                  role: controller.role.value,
                  provider: controller.providerLabel,
                  onRoleChanged: controller.switchRole,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                switch (controller.role.value) {
                  case AcademicAdminRole.hod:
                    return _HodPanel(cs: cs, controller: controller);
                  case AcademicAdminRole.registry:
                    return _RegistryPanel(cs: cs, controller: controller);
                  case AcademicAdminRole.student:
                    return _StudentPanel(cs: cs, controller: controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.cs,
    required this.role,
    required this.provider,
    required this.onRoleChanged,
  });

  final ColorScheme cs;
  final AcademicAdminRole role;
  final String provider;
  final ValueChanged<AcademicAdminRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.94),
            cs.tertiary.withValues(alpha: 0.74),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Administration',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AcademicAdminRole>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? cs.primary
                      : Colors.white,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              segments: AcademicAdminRole.values
                  .map(
                    (item) => ButtonSegment<AcademicAdminRole>(
                      value: item,
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
              selected: {role},
              onSelectionChanged: (values) => onRoleChanged(values.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _HodPanel extends StatelessWidget {
  const _HodPanel({required this.cs, required this.controller});

  final ColorScheme cs;
  final AcademicAdminController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ActionCard(
          cs: cs,
          icon: Icons.co_present_outlined,
          title: 'Create Lecturer',
          subtitle:
              'Creates a staff user with lecturer role scoped to department.',
          actionLabel: 'Create',
          onTap: controller.createLecturer,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          cs: cs,
          icon: Icons.admin_panel_settings_outlined,
          title: 'Create Exam Officer',
          subtitle:
              'Creates the officer that releases exams and manages timetable.',
          actionLabel: 'Create',
          onTap: controller.createExamOfficer,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          cs: cs,
          icon: Icons.menu_book_outlined,
          title: 'Course Setup',
          subtitle:
              'Courses are created with programme, semester, level, and units.',
          actionLabel: 'Ready',
          onTap: () {},
        ),
      ],
    );
  }
}

class _RegistryPanel extends StatelessWidget {
  const _RegistryPanel({required this.cs, required this.controller});

  final ColorScheme cs;
  final AcademicAdminController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ActionCard(
          cs: cs,
          icon: Icons.badge_outlined,
          title: 'Register Student',
          subtitle:
              'Creates student account, programme, level, semester, and session.',
          actionLabel: 'Register',
          onTap: controller.createRegistryStudent,
        ),
      ],
    );
  }
}

class _StudentPanel extends StatelessWidget {
  const _StudentPanel({required this.cs, required this.controller});

  final ColorScheme cs;
  final AcademicAdminController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        ...controller.eligibleCourses.map(
          (course) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Obx(
              () => _CourseChoice(
                cs: cs,
                course: course,
                selected: controller.selectedCourses.any(
                  (item) => item.code == course.code,
                ),
                onTap: () => controller.toggleCourse(course),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.registerSelectedCourses,
            icon: const Icon(Icons.app_registration_outlined),
            label: const Text('Register Selected Courses'),
          ),
        ),
        const SizedBox(height: 14),
        ...controller.registrations.map(
          (item) => _RegistrationPill(cs: cs, item: item),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.cs,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final ColorScheme cs;
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(cs),
      child: Row(
        children: [
          _IconBox(cs: cs, icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonal(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _CourseChoice extends StatelessWidget {
  const _CourseChoice({
    required this.cs,
    required this.course,
    required this.selected,
    required this.onTap,
  });

  final ColorScheme cs;
  final CourseModel course;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(cs),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: (_) => onTap()),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.code,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.title,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationPill extends StatelessWidget {
  const _RegistrationPill({required this.cs, required this.item});

  final ColorScheme cs;
  final CourseRegistrationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: cs.primary.withValues(alpha: 0.10),
        ),
        child: Text(
          '${item.course.code} • ${item.status}',
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.cs, required this.icon});

  final ColorScheme cs;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: cs.primary),
    );
  }
}

BoxDecoration _cardDecoration(ColorScheme cs) {
  return BoxDecoration(
    color: cs.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
    boxShadow: [
      BoxShadow(
        blurRadius: 18,
        offset: const Offset(0, 10),
        color: Colors.black.withValues(alpha: 0.04),
      ),
    ],
  );
}
