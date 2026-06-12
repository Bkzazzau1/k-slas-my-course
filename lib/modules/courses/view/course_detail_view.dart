import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/course_model.dart';
import '../widgets/assessments_tab.dart';
import '../widgets/chat_tab.dart';
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

class _CourseDetailViewState extends State<CourseDetailView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _coursePanelCollapsed = false;

  CourseModel get course {
    final args = (Get.arguments ?? {}) as Map;
    return args['course'] as CourseModel;
  }

  @override
  void initState() {
    super.initState();
    final args = (Get.arguments ?? {}) as Map;
    final initialTab = (args['initialTab'] as int?)?.clamp(0, 6) ?? 0;
    _tabController = TabController(length: 7, vsync: this, initialIndex: initialTab);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _CourseHeroHeader(
                course: c,
                collapsed: _coursePanelCollapsed,
                onBack: () => Get.back(),
                onToggleCollapsed: () => setState(() => _coursePanelCollapsed = !_coursePanelCollapsed),
                onStudy: () => _tabController.animateTo(0),
                onAskAi: () => Get.toNamed(Routes.chat, arguments: {'course': c}),
                onCbt: () => _tabController.animateTo(3),
                onVideoLectures: () => _tabController.animateTo(1),
                onLiveClass: () => _tabController.animateTo(2),
                onPastQs: () => _tabController.animateTo(4),
                onRevision: () => _tabController.animateTo(6),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _coursePanelCollapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _NextBestActionCard(
                      course: c,
                      onPrimary: () => _openRecommendedTab(c),
                      onAssessment: () => _tabController.animateTo(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _GlassTabBar(controller: _tabController),
                  ),
                ],
              ),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _FoldedCoursePanelStrip(onUnfold: () => setState(() => _coursePanelCollapsed = false)),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StudyTab(course: c, chromeCollapsed: _coursePanelCollapsed),
                  VideoLecturesTab(course: c),
                  LiveClassTab(course: c),
                  AssessmentsTab(course: c),
                  PastQuestionsTab(course: c),
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

  void _openRecommendedTab(CourseModel course) {
    if (course.progress < 45) {
      _tabController.animateTo(0);
      return;
    }
    if (course.pastQuestions) {
      _tabController.animateTo(4);
      return;
    }
    _tabController.animateTo(1);
  }
}

class _FoldedCoursePanelStrip extends StatelessWidget {
  const _FoldedCoursePanelStrip({required this.onUnfold});
  final VoidCallback onUnfold;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onUnfold,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
        ),
        child: Row(children: [
          Icon(Icons.unfold_more_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Course controls folded. Tap here or the arrow above to show tabs and actions.',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w800),
            ),
          ),
          Text('Show', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _NextBestActionCard extends StatelessWidget {
  const _NextBestActionCard({required this.course, required this.onPrimary, required this.onAssessment});

  final CourseModel course;
  final VoidCallback onPrimary;
  final VoidCallback onAssessment;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final recommended = _recommendation(course);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 8), color: cs.shadow.withValues(alpha: 0.04))],
      ),
      child: Row(children: [
        CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(recommended.icon, color: cs.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Next best action', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.58), fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(height: 3),
          Text(recommended.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 3),
          Text(recommended.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 10),
        Column(children: [
          FilledButton(onPressed: onPrimary, child: Text(recommended.action)),
          const SizedBox(height: 6),
          TextButton(onPressed: onAssessment, child: const Text('Assessment')),
        ]),
      ]),
    );
  }

  _Recommendation _recommendation(CourseModel course) {
    if (course.progress < 45) {
      return const _Recommendation(title: 'Continue studying this course', subtitle: 'Build your foundation before attempting graded assessments.', action: 'Study', icon: Icons.menu_book_outlined);
    }
    if (course.pastQuestions) {
      return const _Recommendation(title: 'Practice past questions', subtitle: 'Use past questions to prepare before your next assessment.', action: 'Practice', icon: Icons.history_edu_outlined);
    }
    return const _Recommendation(title: 'Watch lecture materials', subtitle: 'Review available video lectures and course materials.', action: 'Open', icon: Icons.play_circle_outline_rounded);
  }
}

class _Recommendation {
  const _Recommendation({required this.title, required this.subtitle, required this.action, required this.icon});
  final String title;
  final String subtitle;
  final String action;
  final IconData icon;
}

class _CourseHeroHeader extends StatelessWidget {
  const _CourseHeroHeader({
    required this.course,
    required this.collapsed,
    required this.onBack,
    required this.onToggleCollapsed,
    required this.onStudy,
    required this.onAskAi,
    required this.onCbt,
    required this.onVideoLectures,
    required this.onLiveClass,
    required this.onPastQs,
    required this.onRevision,
  });

  final CourseModel course;
  final bool collapsed;
  final VoidCallback onBack;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onStudy;
  final VoidCallback onAskAi;
  final VoidCallback onCbt;
  final VoidCallback onVideoLectures;
  final VoidCallback onLiveClass;
  final VoidCallback onPastQs;
  final VoidCallback onRevision;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cs.primary.withValues(alpha: 0.95), cs.secondary.withValues(alpha: 0.80)]),
        boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 14), color: cs.primary.withValues(alpha: 0.18))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _BackBtn(onTap: onBack),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(course.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.2)),
            const SizedBox(height: 4),
            Text(course.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.2)),
          ])),
          const SizedBox(width: 10),
          _ProgressPill(progress: course.progress),
          const SizedBox(width: 8),
          _FoldBtn(collapsed: collapsed, onTap: onToggleCollapsed),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: (course.progress / 100).clamp(0.0, 1.0), minHeight: collapsed ? 7 : 10, backgroundColor: Colors.white.withValues(alpha: 0.18)),
        ),
        if (!collapsed) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              _HeroPill(text: course.notes ? 'Notes ready' : 'Notes pending', icon: course.notes ? Icons.check_circle_outline : Icons.info_outline),
              _HeroPill(text: course.pastQuestions ? 'Past Qs ready' : 'Past Qs pending', icon: course.pastQuestions ? Icons.task_alt_outlined : Icons.hourglass_bottom_outlined),
              const _HeroPill(text: 'AI citation mode', icon: Icons.verified_outlined),
              const _HeroPill(text: 'Offline friendly', icon: Icons.cloud_off_outlined),
            ]),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            const spacing = 10.0;
            final columns = constraints.maxWidth >= 960 ? 6 : 2;
            final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;
            return Wrap(spacing: spacing, runSpacing: spacing, children: [
              SizedBox(width: itemWidth, child: _HeroAction(icon: Icons.menu_book_outlined, label: 'Study', onTap: onStudy)),
              SizedBox(width: itemWidth, child: _HeroAction(icon: Icons.play_circle_outline_rounded, label: 'Video', onTap: onVideoLectures)),
              SizedBox(width: itemWidth, child: _HeroAction(icon: Icons.videocam_outlined, label: 'Live', onTap: onLiveClass)),
              SizedBox(width: itemWidth, child: _HeroAction(icon: Icons.task_alt_outlined, label: 'Tests', onTap: onCbt)),
              SizedBox(width: itemWidth, child: _HeroAction(icon: Icons.history_edu_outlined, label: 'Past Qs', onTap: onPastQs)),
              SizedBox(width: itemWidth, child: _HeroAction(icon: Icons.psychology_outlined, label: 'Revise', onTap: onRevision)),
            ]);
          }),
        ],
      ]),
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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
          child: Icon(collapsed ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded, color: Colors.white),
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
      child: Text('$progress% done', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      ]),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.icon, required this.label, required this.onTap});
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.20))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

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
          decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.03), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)), borderRadius: BorderRadius.circular(18)),
          child: TabBar(
            controller: controller,
            isScrollable: true,
            labelStyle: const TextStyle(fontWeight: FontWeight.w900),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: cs.primary.withValues(alpha: 0.16))),
            tabs: const [
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'Study'),
              Tab(icon: Icon(Icons.play_circle_outline_rounded), text: 'Video'),
              Tab(icon: Icon(Icons.live_tv_outlined), text: 'Live'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Tests'),
              Tab(icon: Icon(Icons.history_edu_outlined), text: 'Qs'),
              Tab(icon: Icon(Icons.smart_toy_outlined), text: 'AI'),
              Tab(icon: Icon(Icons.psychology_outlined), text: 'Revise'),
            ],
          ),
        ),
      ),
    );
  }
}
