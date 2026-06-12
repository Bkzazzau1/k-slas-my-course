import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/services/student_profile_storage.dart';
import '../controller/revision_controller.dart';

class RevisionView extends StatefulWidget {
  const RevisionView({super.key});

  @override
  State<RevisionView> createState() => _RevisionViewState();
}

class _RevisionViewState extends State<RevisionView> {
  late final RevisionPlanController controller;
  late final String defaultCourseCode;

  @override
  void initState() {
    super.initState();
    controller = Get.find<RevisionPlanController>();
    final profile = StudentProfileStorage.load();
    defaultCourseCode = profile?.selectedCourses.isNotEmpty == true
        ? profile!.selectedCourses.first
        : 'CSC 305';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Revision')),
      body: LuxuryScaffold(
        safeArea: false,
        child: Obx(() {
          final p = controller.plan.value;

          if (p == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _glassCard(
                  context,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 44,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No revision plan yet.',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Generate a daily plan based on your weak areas and course materials.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            controller.loadForCourse(defaultCourseCode);
                          },
                          icon: const Icon(Icons.bolt),
                          label: const Text('Generate plan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            children: [
              _hero(
                context,
                title: '${p.courseCode} - Today Plan',
                subtitle: 'Focus: ${p.focusTopic}',
              ),
              const SizedBox(height: 12),

              _glassCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why this plan',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.reason,
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _pill(
                          context,
                          text: 'Today',
                          icon: Icons.today_outlined,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 8),
                        _pill(
                          context,
                          text: '${p.totalMinutes} mins',
                          icon: Icons.timer_outlined,
                          color: cs.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Tasks',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 10),

              ...p.tasks.map(
                (t) => _glassCard(
                  context,
                  child: InkWell(
                    onTap: () {
                      // You can route later based on t.type (Study / Quiz / Review)
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Icon(Icons.task_alt_outlined, color: cs.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${t.minutes} mins • ${t.type}',
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: cs.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => controller.loadForCourse(p.courseCode),
                      child: const Text('Refresh plan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.loadFromStorage(),
                      child: const Text('Load saved'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _hero(BuildContext context, {required String title, required String subtitle}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
