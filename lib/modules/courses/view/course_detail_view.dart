import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/course_model.dart';
import '../widgets/assessments_tab.dart';
import '../widgets/chat_tab.dart';
import '../widgets/forum_tab.dart';
import '../widgets/live_class_tab.dart';
import '../widgets/past_questions_tab.dart';
import '../widgets/revision_tab.dart';
import '../widgets/study_tab.dart';
import '../widgets/video_lectures_tab.dart';

class CourseDetailView extends StatefulWidget {
  const CourseDetailView({super.key});

  @override
  State<CourseDetailView> createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends State<CourseDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _heroCollapsed = false;

  CourseModel get course {
    final args = (Get.arguments ?? {}) as Map;
    return args['course'] as CourseModel;
  }

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments ?? {}) as Map;
    final initialTab = (args['initialTab'] as int?)?.clamp(0, 7) ?? 0;
    _tabController = TabController(
      length: 8,
      vsync: this,
      initialIndex: initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = course;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            // Premium hero header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _CourseHeroHeader(
                course: c,
                collapsed: _heroCollapsed,
                onBack: () => Get.back(),
                onToggleCollapsed: () =>
                    setState(() => _heroCollapsed = !_heroCollapsed),
                onAskAi: () =>
                    Get.toNamed(Routes.chat, arguments: {'course': c}),
                onCbt: () => _tabController.animateTo(3),
                onVideoLectures: () => _tabController.animateTo(1),
                onLiveClass: () => _tabController.animateTo(2),
                onPastQs: () => _tabController.animateTo(4),
              ),
            ),

            // Premium glass tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _GlassTabBar(controller: _tabController),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StudyTab(course: c),
                  VideoLecturesTab(course: c),
                  LiveClassTab(course: c),
                  AssessmentsTab(course: c),
                  PastQuestionsTab(course: c),
                  ForumTab(course: c),
                  ChatTab(course: c),
                  RevisionTab(course: c),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               Premium Header                               */
/* -------------------------------------------------------------------------- */

class _CourseHeroHeader extends StatelessWidget {
  const _CourseHeroHeader({
    required this.course,
    required this.collapsed,
    required this.onBack,
    required this.onToggleCollapsed,
    required this.onAskAi,
    required this.onCbt,
    required this.onVideoLectures,
    required this.onLiveClass,
    required this.onPastQs,
  });

  final CourseModel course;
  final bool collapsed;
  final VoidCallback onBack;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onAskAi;
  final VoidCallback onCbt;
  final VoidCallback onVideoLectures;
  final VoidCallback onLiveClass;
  final VoidCallback onPastQs;

  @override
  Widget build(BuildContext context) {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _BackBtn(onTap: onBack),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _ProgressPill(progress: course.progress),
              const SizedBox(width: 8),
              _FoldBtn(collapsed: collapsed, onTap: onToggleCollapsed),
            ],
          ),

          if (collapsed) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (course.progress / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ],

          if (collapsed)
            const SizedBox.shrink()
          else ...[
            const SizedBox(height: 12),

            // availability pills
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroPill(
                    text: course.notes ? "Notes available" : "No notes yet",
                    icon: course.notes
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                  ),
                  _HeroPill(
                    text: course.pastQuestions
                        ? "Past Qs ready"
                        : "No past Qs yet",
                    icon: course.pastQuestions
                        ? Icons.task_alt_outlined
                        : Icons.hourglass_bottom_outlined,
                  ),
                  _HeroPill(
                    text: "Citations enabled",
                    icon: Icons.verified_outlined,
                  ),
                  const _HeroPill(
                    text: "Video lecture uploads ready",
                    icon: Icons.play_circle_outline_rounded,
                  ),
                  const _HeroPill(
                    text: "Live class lesson ready",
                    icon: Icons.videocam_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (course.progress / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),

            const SizedBox(height: 12),

            // quick actions
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final columns = constraints.maxWidth >= 960 ? 5 : 2;
                final itemWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) /
                    columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _HeroAction(
                        icon: Icons.chat_bubble_outline,
                        label: "Ask AI",
                        onTap: onAskAi,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HeroAction(
                        icon: Icons.play_circle_outline_rounded,
                        label: "Lectures",
                        onTap: onVideoLectures,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HeroAction(
                        icon: Icons.videocam_outlined,
                        label: "Live Class",
                        onTap: onLiveClass,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HeroAction(
                        icon: Icons.task_alt_outlined,
                        label: "CBT",
                        onTap: onCbt,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _HeroAction(
                        icon: Icons.history_edu_outlined,
                        label: "Past Qs",
                        onTap: onPastQs,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Academic rule: answers outside your materials will return "Not in your materials".',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FoldBtn extends StatelessWidget {
  const _FoldBtn({required this.collapsed, required this.onTap});
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? 'Unfold course panel' : 'Fold course panel',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
          ),
          child: Icon(
            collapsed
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.progress});
  final int progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Text(
        "$progress% done",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                Glass TabBar                                */
/* -------------------------------------------------------------------------- */

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: TabBar(
            controller: controller,
            isScrollable: true,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
            ),
            tabs: const [
              Tab(text: 'Study'),
              Tab(text: 'Lectures'),
              Tab(text: 'Live Class'),
              Tab(text: 'Assessments'),
              Tab(text: 'Past Qs'),
              Tab(text: 'Forum'),
              Tab(text: 'Chat'),
              Tab(text: 'Revision'),
            ],
          ),
        ),
      ),
    );
  }
}
