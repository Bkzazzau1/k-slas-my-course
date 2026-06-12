import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/result_model.dart';
import '../controller/results_controller.dart';

class ResultsView extends GetView<ResultsController> {
  const ResultsView({super.key});

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
                  pending: controller.pendingApprovalCount,
                  ready: controller.readyToPublishCount,
                  provider: controller.providerLabel,
                  onRoleChanged: controller.switchRole,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = switch (controller.role.value) {
                  ResultsRole.student => controller.studentResults,
                  ResultsRole.lecturer => controller.lecturerResults,
                  ResultsRole.officer => controller.officerResults,
                };
                return RefreshIndicator(
                  onRefresh: controller.refreshResults,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const SizedBox(height: 48);
                      }
                      return _ResultCard(
                        cs: cs,
                        result: items[index],
                        role: controller.role.value,
                        onComment: () => _showCommentSheet(
                          context,
                          items[index],
                          controller.saveLecturerComment,
                        ),
                        onApprove: () => controller.approve(items[index]),
                        onPublish: () => controller.publish(items[index]),
                      );
                    },
                  ),
                );
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
    required this.pending,
    required this.ready,
    required this.provider,
    required this.onRoleChanged,
  });

  final ColorScheme cs;
  final ResultsRole role;
  final int pending;
  final int ready;
  final String provider;
  final ValueChanged<ResultsRole> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.94),
            cs.secondary.withValues(alpha: 0.76),
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
                      'Results & Gradebook',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role == ResultsRole.student
                          ? 'Published results from approved records.'
                          : '$pending awaiting approval, $ready ready to publish.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: provider,
                child: Icon(Icons.cloud_sync_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ResultsRole>(
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
              segments: ResultsRole.values
                  .map(
                    (item) => ButtonSegment<ResultsRole>(
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.cs,
    required this.result,
    required this.role,
    required this.onComment,
    required this.onApprove,
    required this.onPublish,
  });

  final ColorScheme cs;
  final ResultModel result;
  final ResultsRole role;
  final VoidCallback onComment;
  final VoidCallback onApprove;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (result.status) {
      ResultWorkflowStatus.submitted => Colors.orange.shade700,
      ResultWorkflowStatus.approved => Colors.blue.shade700,
      ResultWorkflowStatus.published => Colors.green.shade700,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScoreBadge(cs: cs, result: result),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.courseCode} • ${result.studentName}',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.66),
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(label: result.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.remark.isEmpty ? result.passFailRemark : result.remark,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ComponentScores(cs: cs, result: result),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (role == ResultsRole.lecturer)
                FilledButton.tonalIcon(
                  onPressed: onComment,
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                    result.status == ResultWorkflowStatus.published
                        ? 'Comment only'
                        : 'Update comment',
                  ),
                ),
              if (role == ResultsRole.officer &&
                  result.status == ResultWorkflowStatus.submitted)
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve'),
                ),
              if (role == ResultsRole.officer &&
                  result.status == ResultWorkflowStatus.approved)
                FilledButton.icon(
                  onPressed: onPublish,
                  icon: const Icon(Icons.publish_outlined),
                  label: const Text('Publish'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.cs, required this.result});

  final ColorScheme cs;
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.primaryContainer,
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            result.grade,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          Text(
            '${result.effectiveTotalScore.toStringAsFixed(0)}/${result.maxScore.toStringAsFixed(0)}',
            style: TextStyle(
              color: cs.onPrimaryContainer.withValues(alpha: 0.76),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentScores extends StatelessWidget {
  const _ComponentScores({required this.cs, required this.result});

  final ColorScheme cs;
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Assessment', result.gradedAssessmentScore),
      ('Assignment', result.assignmentScore),
      ('Group', result.groupAssignmentScore),
      ('Peer', result.peerReviewScore),
      ('Exam', result.examinationScore),
      ('Total', result.effectiveTotalScore),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => _ScoreChip(
              label: item.$1,
              score: item.$2,
              cs: cs,
              strong: item.$1 == 'Total',
            ),
          )
          .toList(),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.cs,
    this.strong = false,
  });

  final String label;
  final double score;
  final ColorScheme cs;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final color = strong ? cs.primary : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: strong ? 0.12 : 0.06),
        border: Border.all(
          color: color.withValues(alpha: strong ? 0.20 : 0.10),
        ),
      ),
      child: Text(
        '$label ${score.toStringAsFixed(0)}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 136),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

Future<void> _showCommentSheet(
  BuildContext context,
  ResultModel result,
  Future<void> Function(ResultModel result, String comment) onSave,
) async {
  final controller = TextEditingController(text: result.remark);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lecturer Comment',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await onSave(result, controller.text);
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      );
    },
  );
  controller.dispose();
}
