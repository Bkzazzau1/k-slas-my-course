import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/services/draft_sync_service.dart';
import '../../../data/services/submission_history_service.dart';
import '../controller/dashboard_controller.dart';
import '../widgets/dashboard_next_exam_lux.dart';
import '../widgets/dashboard_performance_lux.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/responsive_row.dart';
import '../widgets/section_card.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final receipts = SubmissionHistoryService.load();
    final drafts = DraftSyncService.loadDrafts();
    final pending = DraftSyncService.loadPendingSync();
    final latest = receipts.isEmpty ? null : receipts.first;

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
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      sliver: SliverToBoxAdapter(
                        child: DashboardTopBar(cs: cs, isTablet: isTablet),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: _PriorityHero(
                          draftCount: drafts.length,
                          pendingCount: pending.length,
                          latest: latest,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: ResponsiveRow(
                          isTablet: isTablet,
                          left: SectionCard(
                            title: 'Next exam',
                            icon: Icons.event_available_outlined,
                            iconColor: cs.primary,
                            trailingText: 'Setup',
                            onTrailingTap: () => Get.toNamed(Routes.examSetup),
                            child: DashboardNextExamLux(cs: cs),
                          ),
                          right: SectionCard(
                            title: 'Academic progress',
                            icon: Icons.insights_outlined,
                            iconColor: cs.secondary,
                            trailingText: 'Live',
                            child: DashboardPerformanceLux(cs: cs),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ActionPanel(
                          title: 'Study actions',
                          actions: [
                            _DashAction(
                              'My courses',
                              Icons.menu_book_outlined,
                              Routes.courses,
                            ),
                            _DashAction(
                              'Live classes',
                              Icons.live_tv_outlined,
                              Routes.liveSessions,
                            ),
                            _DashAction(
                              'Assignments',
                              Icons.assignment_outlined,
                              Routes.assignments,
                            ),
                            _DashAction(
                              'Noticeboard',
                              Icons.campaign_outlined,
                              Routes.noticeboard,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: _ActionPanel(
                          title: 'Assessment actions',
                          actions: [
                            _DashAction(
                              'Practice CBT',
                              Icons.quiz_outlined,
                              Routes.cbtSetup,
                            ),
                            _DashAction(
                              'Examination',
                              Icons.verified_user_outlined,
                              Routes.examSetup,
                            ),
                            _DashAction(
                              'Face ID setup',
                              Icons.face_retouching_natural_outlined,
                              Routes.faceEnrollment,
                            ),
                            _DashAction(
                              'Receipts & offline',
                              Icons.receipt_long_outlined,
                              Routes.results,
                            ),
                            _DashAction(
                              'Revision focus',
                              Icons.psychology_outlined,
                              Routes.revision,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      sliver: SliverToBoxAdapter(
                        child: _LatestReceiptCard(latest: latest),
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

class _PriorityHero extends StatelessWidget {
  const _PriorityHero({
    required this.draftCount,
    required this.pendingCount,
    required this.latest,
  });
  final int draftCount;
  final int pendingCount;
  final SubmissionHistoryRecord? latest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAction = draftCount > 0 || pendingCount > 0;
    final title = hasAction ? 'Action needed' : 'You are up to date';
    final subtitle = hasAction
        ? '$draftCount saved draft${draftCount == 1 ? '' : 's'} • $pendingCount pending sync item${pendingCount == 1 ? '' : 's'}'
        : latest == null
            ? 'Start a course, assessment, or live class from the actions below.'
            : 'Latest receipt: ${latest!.courseCode} • ${latest!.status}';

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Icon(
              hasAction ? Icons.priority_high_rounded : Icons.verified_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => Get.toNamed(Routes.results),
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text('Open'),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({required this.title, required this.actions});
  final String title;
  final List<_DashAction> actions;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= 680;
              final itemWidth = wide
                  ? (box.maxWidth - 24) / 4
                  : (box.maxWidth - 12) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width: itemWidth,
                        child: _ActionTile(action: action),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});
  final _DashAction action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => Get.toNamed(action.route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(action.icon, color: cs.primary),
            const SizedBox(height: 10),
            Text(
              action.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LatestReceiptCard extends StatelessWidget {
  const _LatestReceiptCard({required this.latest});
  final SubmissionHistoryRecord? latest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SectionCard(
      title: 'Latest submission',
      icon: Icons.receipt_long_outlined,
      iconColor: cs.primary,
      trailingText: 'History',
      onTrailingTap: () => Get.toNamed(Routes.results),
      child: latest == null
          ? Text(
              'No submitted assessment yet. Your receipts will appear here after submission.',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        latest!.courseCode,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${latest!.percentage}%',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  latest!.title,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  latest!.status,
                  style: TextStyle(
                    color: latest!.status.contains('Review')
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }
}

class _DashAction {
  const _DashAction(this.title, this.icon, this.route);
  final String title;
  final IconData icon;
  final String route;
}
