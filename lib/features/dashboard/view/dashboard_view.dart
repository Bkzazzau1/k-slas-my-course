import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/student_category.dart';
import '../../../modules/proctoring/controller/proctoring_controller.dart';
import '../../../modules/settings/controller/settings_controller.dart';
import '../controller/dashboard_controller.dart';
import '../widgets/dashboard_assessments_lux.dart';
import '../widgets/dashboard_assignments_lux.dart';
import '../widgets/dashboard_continue_lux.dart';
import '../widgets/dashboard_daily_goal_lux.dart';
import '../widgets/dashboard_focus_lux.dart';
import '../widgets/dashboard_grades_lux.dart';
import '../widgets/dashboard_hero_focus_card.dart';
import '../widgets/dashboard_integrity_status_card.dart';
import '../widgets/dashboard_low_data_offline_lux.dart';
import '../widgets/dashboard_next_exam_lux.dart';
import '../widgets/dashboard_noticeboard_lux.dart';
import '../widgets/dashboard_performance_lux.dart';
import '../widgets/dashboard_quick_actions_lux.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/responsive_row.dart';
import '../widgets/section_card.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = Get.find<SettingsController>();

    final proctor = Get.isRegistered<ProctoringController>()
        ? Get.find<ProctoringController>()
        : Get.put(ProctoringController(), permanent: true);

    final showIntegrity = controller.shouldShowIntegrityCard;
    final showExams = controller.canSeeExams;
    final showQuizzes = controller.canSeeQuizzes;
    final lowDataTitle = controller.lowDataSectionTitle;
    final lowDataIcon = controller.studentCategory.value.requiresIntegritySync
        ? Icons.sync_lock_outlined
        : Icons.cloud_off_outlined;

    return Scaffold(
      body: LuxuryScaffold(
        child: LayoutBuilder(
          builder: (context, c) {
            final isTablet = c.maxWidth >= 900;
            final maxWidth = isTablet ? 1100.0 : double.infinity;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: CustomScrollView(
                  slivers: [
                    /// TOP BAR
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: DashboardTopBar(cs: cs, isTablet: isTablet),
                      ),
                    ),

                    /// INTEGRITY STATUS (Distance Only)
                    if (showIntegrity)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: DashboardIntegrityStatusCard(
                            cs: cs,
                            proctor: proctor,
                          ),
                        ),
                      ),

                    /// HERO
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: DashboardHeroFocusCard(cs: cs),
                          right: showExams
                              ? SectionCard(
                                  title: "Next exam",
                                  icon: Icons.event_available_outlined,
                                  iconColor: cs.primary,
                                  trailingText: "Setup",
                                  onTrailingTap: () =>
                                      Get.toNamed(Routes.examSetup),
                                  child: DashboardNextExamLux(cs: cs),
                                )
                              : SectionCard(
                                  title: "My Courses",
                                  icon: Icons.menu_book_outlined,
                                  iconColor: cs.primary,
                                  trailingText: "Open",
                                  onTrailingTap: () =>
                                      Get.toNamed(Routes.courses),
                                  child: _MiniHint(
                                    title:
                                        "Access lecture notes and course materials.",
                                    cs: cs,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    /// CONTINUE + GOAL
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: SectionCard(
                            title: "Continue studying",
                            icon: Icons.play_circle_outline,
                            iconColor: cs.secondary,
                            trailingText: "Resume",
                            onTrailingTap: () => Get.toNamed(Routes.courses),
                            child: DashboardContinueLux(cs: cs),
                          ),
                          right: SectionCard(
                            title: "Daily study goal",
                            icon: Icons.flag_outlined,
                            iconColor: cs.primary,
                            trailingText: "Goal",
                            child: DashboardDailyGoalLux(
                              cs: cs,
                              settings: settings,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// QUICK ACTIONS
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: SectionCard(
                          title: "Quick actions",
                          icon: Icons.grid_view_rounded,
                          iconColor: cs.primary,
                          trailingText: "Fast",
                          child: DashboardQuickActionsLux(cs: cs),
                        ),
                      ),
                    ),

                    /// COURSES + QUIZZES
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: SectionCard(
                            title: "My Courses",
                            icon: Icons.menu_book_outlined,
                            iconColor: cs.primary,
                            trailingText: "Open",
                            onTrailingTap: () => Get.toNamed(Routes.courses),
                            child: _MiniHint(
                              title: "View registered courses and materials.",
                              cs: cs,
                            ),
                          ),
                          right: showQuizzes
                              ? SectionCard(
                                  title: "CBT Practice",
                                  icon: Icons.quiz_outlined,
                                  iconColor: cs.secondary,
                                  trailingText: "Start",
                                  onTrailingTap: () =>
                                      Get.toNamed(Routes.cbtSetup),
                                  child: _MiniHint(
                                    title: "Practice quizzes and CBT tests.",
                                    cs: cs,
                                  ),
                                )
                              : SectionCard(
                                  title: "Messages",
                                  icon: Icons.chat_bubble_outline,
                                  iconColor: cs.secondary,
                                  trailingText: "Open",
                                  onTrailingTap: () => Get.toNamed(Routes.chat),
                                  child: _MiniHint(
                                    title:
                                        "Chat with lecturers and classmates.",
                                    cs: cs,
                                  ),
                                ),
                        ),
                      ),
                    ),

                    /// ASSIGNMENTS
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: SectionCard(
                          title: "Assignments",
                          icon: Icons.assignment_outlined,
                          iconColor: cs.primary,
                          trailingText: "Deadlines",
                          onTrailingTap: () => Get.toNamed(Routes.assignments),
                          child: DashboardAssignmentsLux(cs: cs),
                        ),
                      ),
                    ),

                    /// COURSE ASSESSMENTS
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: SectionCard(
                          title: "Course assessments",
                          icon: Icons.fact_check_outlined,
                          iconColor: cs.secondary,
                          trailingText: "Open",
                          onTrailingTap: () => Get.toNamed(Routes.courses),
                          child: DashboardAssessmentsLux(cs: cs),
                        ),
                      ),
                    ),

                    /// PERFORMANCE
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: SectionCard(
                            title: "Performance snapshot",
                            icon: Icons.insights_outlined,
                            iconColor: cs.primary,
                            trailingText: "Live",
                            child: DashboardPerformanceLux(cs: cs),
                          ),
                          right: SectionCard(
                            title: "Focus & motivation",
                            icon: Icons.bolt_outlined,
                            iconColor: cs.secondary,
                            trailingText: "Tip",
                            child: DashboardFocusLux(cs: cs),
                          ),
                        ),
                      ),
                    ),

                    /// NOTICEBOARD + RESULTS
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: SectionCard(
                            title: "Course noticeboard",
                            icon: Icons.campaign_outlined,
                            iconColor: cs.primary,
                            trailingText: "New",
                            onTrailingTap: () =>
                                Get.toNamed(Routes.noticeboard),
                            child: DashboardNoticeboardLux(cs: cs),
                          ),
                          right: SectionCard(
                            title: "CBT Results",
                            icon: Icons.grade_outlined,
                            iconColor: cs.secondary,
                            trailingText: "Open",
                            onTrailingTap: () => Get.toNamed(Routes.cbtResult),
                            child: DashboardGradesLux(cs: cs),
                          ),
                        ),
                      ),
                    ),

                    /// SUPPORT + PROFILE
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: SectionCard(
                            title: "Help & Support",
                            icon: Icons.support_agent_outlined,
                            iconColor: cs.primary,
                            trailingText: "Help",
                            onTrailingTap: () => Get.toNamed(Routes.settings),
                            child: _MiniHint(
                              title: "Platform help and support.",
                              cs: cs,
                            ),
                          ),
                          right: SectionCard(
                            title: "Profile & Settings",
                            icon: Icons.manage_accounts_outlined,
                            iconColor: cs.secondary,
                            trailingText: "Settings",
                            onTrailingTap: () => Get.toNamed(Routes.settings),
                            child: _MiniHint(
                              title: "Account and security settings.",
                              cs: cs,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// LOW DATA
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      sliver: SliverToBoxAdapter(
                        child: SectionCard(
                          title: lowDataTitle,
                          icon: lowDataIcon,
                          iconColor: cs.primary,
                          trailingText: "Secure",
                          child: DashboardLowDataOfflineLux(
                            cs: cs,
                            settings: settings,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniHint extends StatelessWidget {
  const _MiniHint({required this.title, required this.cs});

  final String title;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: cs.onSurface.withValues(alpha: 0.72),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
