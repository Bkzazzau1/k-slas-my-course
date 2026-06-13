import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/services/draft_sync_service.dart';
import '../../../data/services/submission_history_service.dart';

class ResultsView extends StatefulWidget {
  const ResultsView({super.key});

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  late List<SubmissionHistoryRecord> records;
  late List<OfflineDraftRecord> drafts;
  late List<PendingSyncRecord> pendingSync;

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() {
    records = SubmissionHistoryService.load();
    drafts = DraftSyncService.loadDrafts();
    pendingSync = DraftSyncService.loadPendingSync();
  }

  Future<void> refresh() async {
    setState(load);
  }

  @override
  Widget build(BuildContext context) {
    final graded = records.where((e) => e.gradingType == GradingType.graded).length;
    final proctored = records.where((e) => e.proctored).length;
    final liveAttendance = records.where((e) => e.isLiveClassAttendance).length;
    final hasAny = records.isNotEmpty || drafts.isNotEmpty || pendingSync.isNotEmpty;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _Header(
                total: records.length,
                graded: graded,
                proctored: proctored,
                drafts: drafts.length,
                pending: pendingSync.length,
                liveAttendance: liveAttendance,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: !hasAny
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          _EmptyCard(onStart: () => Get.toNamed('/cbt/setup', arguments: {'courseCode': 'CSC 305'})),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          if (drafts.isNotEmpty) ...[
                            _SectionLabel(title: 'Offline drafts', subtitle: 'Saved locally. Continue when ready.'),
                            const SizedBox(height: 8),
                            ...drafts.map((draft) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _DraftCard(draft: draft))),
                          ],
                          if (pendingSync.isNotEmpty) ...[
                            _SectionLabel(title: 'Pending sync', subtitle: 'Waiting to upload when network is available.'),
                            const SizedBox(height: 8),
                            ...pendingSync.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _PendingSyncCard(item: item))),
                          ],
                          if (records.isNotEmpty) ...[
                            _SectionLabel(title: 'Receipts and attendance history', subtitle: 'Completed submissions, live-class attendance, and receipt numbers.'),
                            const SizedBox(height: 8),
                            ...records.map((record) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _SubmissionCard(record: record))),
                          ],
                        ],
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
  const _Header({required this.total, required this.graded, required this.proctored, required this.drafts, required this.pending, required this.liveAttendance});
  final int total;
  final int graded;
  final int proctored;
  final int drafts;
  final int pending;
  final int liveAttendance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: LinearGradient(colors: [cs.primary, cs.secondary])),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: () => Get.back<void>(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Submission & Offline Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
          const Icon(Icons.cloud_done_rounded, color: Colors.white),
        ]),
        const SizedBox(height: 12),
        Text('Your receipts, live-class attendance, saved drafts, and pending sync items are kept here.', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: '$total receipts'),
          _HeroPill(label: '$liveAttendance attendance'),
          _HeroPill(label: '$drafts drafts'),
          _HeroPill(label: '$pending pending sync'),
          _HeroPill(label: '$graded graded'),
          _HeroPill(label: '$proctored proctored'),
        ]),
      ]),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w600)),
      ]),
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
      child: Column(children: [
        Icon(Icons.cloud_off_rounded, size: 46, color: cs.primary),
        const SizedBox(height: 12),
        const Text('No local record yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 8),
        Text('Drafts, pending sync items, live-class attendance, and submission receipts will appear here automatically.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Start assessment')),
      ]),
    );
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.draft});
  final OfflineDraftRecord draft;

  @override
  Widget build(BuildContext context) {
    final remaining = draft.secondsLeft <= 0 ? 'Untimed / expired' : '${(draft.secondsLeft ~/ 60).toString().padLeft(2, '0')}:${(draft.secondsLeft % 60).toString().padLeft(2, '0')} left';
    return _glass(
      context,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.save_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(draft.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          _StatusChip(label: 'Draft', color: Colors.orange.shade700),
        ]),
        const SizedBox(height: 10),
        _InfoRow(label: 'Course', value: draft.courseCode),
        _InfoRow(label: 'Answered', value: '${draft.answered}/${draft.total}'),
        _InfoRow(label: 'Saved', value: _formatDate(draft.savedAt)),
        _InfoRow(label: 'Time', value: remaining),
        const SizedBox(height: 8),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Get.toNamed('/cbt/setup', arguments: {'courseCode': draft.courseCode}), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Continue assessment'))),
      ]),
    );
  }
}

class _PendingSyncCard extends StatelessWidget {
  const _PendingSyncCard({required this.item});
  final PendingSyncRecord item;

  @override
  Widget build(BuildContext context) {
    return _glass(
      context,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.sync_problem_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
          _StatusChip(label: 'Pending', color: Colors.orange.shade700),
        ]),
        const SizedBox(height: 10),
        _InfoRow(label: 'Course', value: item.courseCode),
        _InfoRow(label: 'Status', value: item.status),
        _InfoRow(label: 'Created', value: _formatDate(item.createdAt)),
      ]),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({required this.record});
  final SubmissionHistoryRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLive = record.isLiveClassAttendance;
    final statusColor = isLive
        ? cs.primary
        : record.status.contains('Review') || record.status.contains('Warning')
            ? Colors.orange.shade700
            : Colors.green.shade700;

    return _glass(
      context,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: (isLive ? cs.secondary : cs.primary).withValues(alpha: 0.11), borderRadius: BorderRadius.circular(18)),
            child: isLive ? Icon(Icons.live_tv_outlined, color: cs.secondary) : Text('${record.percentage}%', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(record.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text('${record.courseCode} • ${_formatDate(record.submittedAt)}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.66), fontWeight: FontWeight.w700)),
          ])),
          _StatusChip(label: record.status, color: statusColor),
        ]),
        const SizedBox(height: 12),
        _InfoRow(label: 'Receipt', value: record.receiptNumber),
        _InfoRow(label: isLive ? 'Attendance' : 'Score', value: record.scoreLabel),
        _InfoRow(label: isLive ? 'Attendance rate' : 'Score rate', value: '${record.percentage}%'),
        _InfoRow(label: isLive ? 'Record type' : 'Mode', value: isLive ? 'Live Class Attendance' : record.gradingType == GradingType.graded ? 'Graded' : 'Ungraded'),
        if (!isLive) _InfoRow(label: 'Proctoring', value: record.proctored ? 'Proctored' : 'Normal'),
        if (record.proctored) ...[
          _InfoRow(label: 'Integrity score', value: record.integrityScore?.toString() ?? 'Not available'),
          _InfoRow(label: 'Warnings', value: '${record.warningCount}'),
        ],
      ]),
    );
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
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900))),
      ]),
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

String _formatDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

Widget _glass(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      boxShadow: [BoxShadow(blurRadius: 18, offset: const Offset(0, 10), color: cs.shadow.withValues(alpha: 0.05))],
    ),
    child: child,
  );
}
