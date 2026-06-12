import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/submission_history_service.dart';

class ResultsView extends StatefulWidget {
  const ResultsView({super.key});

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  late List<SubmissionHistoryRecord> records;

  @override
  void initState() {
    super.initState();
    records = SubmissionHistoryService.load();
  }

  Future<void> refresh() async {
    setState(() => records = SubmissionHistoryService.load());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final graded = records.where((e) => e.gradingType == GradingType.graded).length;
    final proctored = records.where((e) => e.proctored).length;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _Header(total: records.length, graded: graded, proctored: proctored),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: records.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          _EmptyCard(onStart: () => Get.toNamed('/cbt/setup', arguments: {'courseCode': 'CSC 305'})),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _SubmissionCard(record: records[index]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total, required this.graded, required this.proctored});
  final int total;
  final int graded;
  final int proctored;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Submission History',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
              ),
              const Icon(Icons.receipt_long_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your exam and assessment receipts are saved here for personal record.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(label: '$total total'),
              _HeroPill(label: '$graded graded'),
              _HeroPill(label: '$proctored proctored'),
            ],
          ),
        ],
      ),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _glass(
      context,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 46, color: cs.primary),
          const SizedBox(height: 12),
          const Text('No submission receipt yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'After you submit an assessment or examination, the receipt will appear here automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start assessment')),
        ],
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.record});
  final SubmissionHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = record.status.contains('Review') || record.status.contains('Warning')
        ? Colors.orange.shade700
        : Colors.green.shade700;

    return _glass(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text('${record.percentage}%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(record.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${record.courseCode} • ${_formatDate(record.submittedAt)}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w700)),
                ]),
              ),
              _StatusChip(label: record.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Receipt', value: record.receiptNumber),
          _InfoRow(label: 'Score', value: record.scoreLabel),
          _InfoRow(label: 'Mode', value: record.gradingType == GradingType.graded ? 'Graded' : 'Ungraded'),
          _InfoRow(label: 'Proctoring', value: record.proctored ? 'Proctored' : 'Normal'),
          if (record.proctored) ...[
            _InfoRow(label: 'Integrity score', value: record.integrityScore?.toString() ?? 'Not available'),
            _InfoRow(label: 'Warnings', value: '${record.warningCount}'),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

Widget _glass(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(
          blurRadius: 18,
          offset: const Offset(0, 10),
          color: cs.shadow.withValues(alpha: 0.05),
        ),
      ],
    ),
    child: child,
  );
}
