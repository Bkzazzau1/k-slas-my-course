import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/student_category.dart';
import '../controller/dashboard_controller.dart';

class DashboardQuickActionsLux extends StatelessWidget {
  const DashboardQuickActionsLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final dash = Get.find<DashboardController>();
    final category = dash.studentCategory.value;

    final course = dash.courses.isNotEmpty ? dash.courses.first : null;

    final showAssessment = category.canAccessAssessmentSuite;

    final showExam = category.canAccessExamSuite;

    final items = <_ActionTileModel>[
      _ActionTileModel(
        title: "Demo walkthrough",
        subtitle: "Client presentation path",
        icon: Icons.slideshow_outlined,
        tone: _Tone.primary,
        onTap: () => Get.toNamed(Routes.demoWalkthrough),
      ),

      /// COURSE AI
      _ActionTileModel(
        title: "Ask Course AI",
        subtitle: "Explain topics from notes",
        icon: Icons.auto_awesome_outlined,
        tone: _Tone.primary,
        onTap: course == null
            ? null
            : () => Get.toNamed(Routes.chat, arguments: {'course': course}),
      ),

      /// CBT / ASSESSMENT
      if (showAssessment)
        _ActionTileModel(
          title: AppStrings.assessment,
          subtitle: AppStrings.assessmentSubtitle,
          icon: Icons.task_alt_outlined,
          tone: _Tone.secondary,
          onTap: course == null
              ? null
              : () => Get.toNamed(
                  Routes.cbtSetup,
                  arguments: {"courseCode": course.code},
                ),
        ),

      /// EXAM
      if (showExam)
        _ActionTileModel(
          title: AppStrings.examination,
          subtitle: AppStrings.examinationSubtitle,
          icon: Icons.image_search_rounded,
          tone: _Tone.neutral,
          onTap: course == null
              ? null
              : () => Get.toNamed(
                  Routes.examSetup,
                  arguments: {"courseCode": course.code},
                ),
        ),

      _ActionTileModel(
        title: "Live sessions",
        subtitle: "Join & attendance",
        icon: Icons.video_camera_front_outlined,
        tone: _Tone.secondary,
        onTap: () => Get.toNamed(Routes.liveSessions),
      ),

      _ActionTileModel(
        title: "Results",
        subtitle: "Gradebook & approval",
        icon: Icons.workspace_premium_outlined,
        tone: _Tone.primary,
        onTap: () => Get.toNamed(Routes.results),
      ),

      /// ASSIGNMENTS
      _ActionTileModel(
        title: "Assignments",
        subtitle: "Student demo flow",
        icon: Icons.assignment_outlined,
        tone: _Tone.primary,
        onTap: () => Get.toNamed(
          Routes.assignments,
          arguments: {'actorRole': 'student'},
        ),
      ),

      /// TIMETABLE
      _ActionTileModel(
        title: "Timetable",
        subtitle: "Exams & lectures plan",
        icon: Icons.event_note_outlined,
        tone: _Tone.neutral,
        onTap: () => Get.toNamed(Routes.timetable),
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final isTablet = c.maxWidth >= 900;
        final columns = isTablet ? 3 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isTablet ? 2.8 : 3.2,
          ),
          itemBuilder: (_, i) => _ActionTile(cs: cs, item: items[i]),
        );
      },
    );
  }
}

enum _Tone { primary, secondary, neutral }

class _ActionTileModel {
  _ActionTileModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final _Tone tone;
  final VoidCallback? onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.cs, required this.item});
  final ColorScheme cs;
  final _ActionTileModel item;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onTap != null;
    final muted = cs.onSurface.withValues(alpha: 0.68);

    final accent = switch (item.tone) {
      _Tone.primary => cs.primary,
      _Tone.secondary => cs.secondary,
      _Tone.neutral => cs.onSurface.withValues(alpha: 0.78),
    };

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.55,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cs.onSurface.withValues(alpha: 0.03),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withValues(alpha: 0.04),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconBadge(cs: cs, accent: accent, icon: item.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: muted,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.cs,
    required this.accent,
    required this.icon,
  });

  final ColorScheme cs;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Icon(icon, color: accent),
    );
  }
}
