import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/live_class_attendance_enforcement_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveClassAttendanceReportOverlay extends StatefulWidget {
  const LiveClassAttendanceReportOverlay({
    super.key,
    required this.child,
    required this.sessionId,
    required this.enabled,
  });

  final Widget child;
  final String sessionId;
  final bool enabled;

  @override
  State<LiveClassAttendanceReportOverlay> createState() =>
      _LiveClassAttendanceReportOverlayState();
}

class _LiveClassAttendanceReportOverlayState
    extends State<LiveClassAttendanceReportOverlay> {
  late final LiveSessionsController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 18,
          bottom: 166,
          child: FloatingActionButton.extended(
            heroTag: 'class-attendance-report-control',
            onPressed: _showReport,
            icon: const Icon(Icons.fact_check_rounded),
            label: const Text('Attendance'),
          ),
        ),
      ],
    );
  }

  Future<void> _showReport() async {
    await _controller.refreshRoom();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.82;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Obx(() {
                final room = _controller.room.value;
                if (room == null || room.session.id != widget.sessionId) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = LiveClassAttendanceEnforcementService.reportFor(room: room);
                final summary = LiveClassAttendanceEnforcementService.summaryFor(room: room);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fact_check_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Live attendance report',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () async {
                            await _controller.refreshRoom();
                            if (mounted) setState(() {});
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${room.session.courseCode} • Minimum attendance ${summary.minimumPercentage}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 14),
                    _AttendanceSummaryGrid(summary: summary),
                    const SizedBox(height: 14),
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(child: Text('No student attendance yet.'))
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                return _AttendanceRowTile(status: rows[index]);
                              },
                            ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _AttendanceSummaryGrid extends StatelessWidget {
  const _AttendanceSummaryGrid({required this.summary});

  final LiveClassAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryCard(label: 'Students', value: '${summary.totalStudents}', icon: Icons.groups_rounded),
        _SummaryCard(label: 'Qualified', value: '${summary.qualifiedStudents}', icon: Icons.verified_rounded),
        _SummaryCard(label: 'Below min.', value: '${summary.belowMinimumStudents}', icon: Icons.warning_amber_rounded),
        _SummaryCard(label: 'Late join', value: '${summary.lateStudents}', icon: Icons.schedule_rounded),
        _SummaryCard(label: 'Average', value: '${summary.averagePercentage}%', icon: Icons.analytics_rounded),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AttendanceRowTile extends StatelessWidget {
  const _AttendanceRowTile({required this.status});

  final LiveClassAttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = status.isQualified ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(_initials(status.participant.displayName))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.participant.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  status.participant.registrationNumber ?? 'Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 3),
                Text(
                  status.receiptNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${status.attendancePercentage}%',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              Text('${status.attendanceMinutes} min'),
              Chip(
                label: Text(status.statusLabel),
                avatar: Icon(
                  status.isQualified ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  size: 18,
                ),
                backgroundColor: tone.withValues(alpha: 0.16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    final first = parts.first.substring(0, 1);
    final last = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last.substring(0, 1)
        : '';
    return '$first$last'.toUpperCase();
  }
}
