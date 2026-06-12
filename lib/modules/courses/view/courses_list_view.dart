import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/draft_sync_service.dart';
import '../../../data/services/submission_history_service.dart';
import '../controller/courses_controller.dart';
import '../widgets/course_tile.dart';

class CoursesListView extends GetView<CoursesController> {
  const CoursesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final drafts = DraftSyncService.loadDrafts();
    final receipts = SubmissionHistoryService.load();

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(
          () {
            final courses = controller.courses;
            final avgProgress = courses.isEmpty
                ? 0
                : (courses.fold<int>(0, (sum, course) => sum + course.progress) / courses.length).round();
            final materialsReady = courses.where((course) => course.notes || course.pastQuestions).length;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _LearningHubHeader(
                      providerLabel: controller.providerLabel,
                      courseCount: courses.length,
                      avgProgress: avgProgress,
                      materialsReady: materialsReady,
                      draftCount: drafts.length,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _PriorityStrip(
                      drafts: drafts.length,
                      receipts: receipts.length,
                      onOffline: () => Get.toNamed(Routes.results),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _QuickCourseActions(
                      onLive: () => Get.toNamed(Routes.liveSessions),
                      onCalendar: () => Get.toNamed(Routes.timetable),
                      onReceipts: () => Get.toNamed(Routes.results),
                    ),
                  ),
                ),
                if (controller.errorMessage.value != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    sliver: SliverToBoxAdapter(
                      child: _InfoBanner(
                        message: controller.errorMessage.value!,
                        onRetry: controller.loadCourses,
                      ),
                    ),
                  ),
                if (controller.isLoading.value)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.courses.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onReload: controller.loadCourses),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Registered courses',
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                    sliver: SliverList.separated(
                      itemCount: controller.courses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final course = controller.courses[i];
                        return _CourseShell(
                          course: course,
                          child: CourseTile(
                            course: course,
                            onTap: () => Get.toNamed(
                              Routes.courseDetail,
                              arguments: {'course': course},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LearningHubHeader extends StatelessWidget {
  const _LearningHubHeader({
    required this.providerLabel,
    required this.courseCount,
    required this.avgProgress,
    required this.materialsReady,
    required this.draftCount,
  });

  final String providerLabel;
  final int courseCount;
  final int avgProgress;
  final int materialsReady;
  final int draftCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'My Learning Hub',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          _ProviderPill(label: providerLabel),
        ]),
        const SizedBox(height: 10),
        Text(
          'Courses, materials, assessments and learning tools organized in one student workspace.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.25),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: '$courseCount courses'),
          _HeroPill(label: '$avgProgress% average progress'),
          _HeroPill(label: '$materialsReady materials ready'),
          _HeroPill(label: '$draftCount saved drafts'),
        ]),
      ]),
    );
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _PriorityStrip extends StatelessWidget {
  const _PriorityStrip({required this.drafts, required this.receipts, required this.onOffline});
  final int drafts;
  final int receipts;
  final VoidCallback onOffline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDraft = drafts > 0;
    return InkWell(
      onTap: onOffline,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasDraft ? Colors.orange.withValues(alpha: 0.10) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hasDraft ? Colors.orange.withValues(alpha: 0.22) : cs.onSurface.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          Icon(hasDraft ? Icons.save_rounded : Icons.check_circle_outline_rounded, color: hasDraft ? Colors.orange.shade700 : cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasDraft
                  ? '$drafts saved assessment draft${drafts == 1 ? '' : 's'} waiting for you.'
                  : '$receipts submission receipt${receipts == 1 ? '' : 's'} saved. No urgent course action.',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ]),
      ),
    );
  }
}

class _QuickCourseActions extends StatelessWidget {
  const _QuickCourseActions({required this.onLive, required this.onCalendar, required this.onReceipts});
  final VoidCallback onLive;
  final VoidCallback onCalendar;
  final VoidCallback onReceipts;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _MiniAction(icon: Icons.live_tv_outlined, label: 'Live', onTap: onLive)),
      const SizedBox(width: 8),
      Expanded(child: _MiniAction(icon: Icons.calendar_month_outlined, label: 'Calendar', onTap: onCalendar)),
      const SizedBox(width: 8),
      Expanded(child: _MiniAction(icon: Icons.receipt_long_outlined, label: 'Receipts', onTap: onReceipts)),
    ]);
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        ),
        child: Column(children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _CourseShell extends StatelessWidget {
  const _CourseShell({required this.course, required this.child});
  final CourseModel course;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final needsAttention = course.progress < 50;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: needsAttention ? Colors.orange.withValues(alpha: 0.22) : cs.onSurface.withValues(alpha: 0.04)),
      ),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReload});

  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: cs.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              'No courses available right now.',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The app will keep your demo path safe until backend data is ready.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onReload(),
              child: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }
}
