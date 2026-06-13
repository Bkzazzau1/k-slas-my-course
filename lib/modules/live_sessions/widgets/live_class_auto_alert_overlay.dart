import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/live_class_malpractice_report_service.dart';
import '../../../data/services/live_class_suspicious_behaviour_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveClassAutoAlertOverlay extends StatefulWidget {
  const LiveClassAutoAlertOverlay({
    super.key,
    required this.child,
    required this.sessionId,
    required this.reviewerName,
    required this.reviewerRole,
    required this.enabled,
  });

  final Widget child;
  final String sessionId;
  final String reviewerName;
  final String reviewerRole;
  final bool enabled;

  @override
  State<LiveClassAutoAlertOverlay> createState() => _LiveClassAutoAlertOverlayState();
}

class _LiveClassAutoAlertOverlayState extends State<LiveClassAutoAlertOverlay> {
  late final LiveSessionsController _controller;
  Timer? _timer;
  List<LiveClassSuspiciousBehaviourAlert> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();
    _refreshAlerts();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshAlerts());
  }

  @override
  void didUpdateWidget(covariant LiveClassAutoAlertOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) _refreshAlerts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshAlerts() {
    if (!widget.enabled || widget.sessionId.trim().isEmpty) return;
    final room = _controller.room.value;
    if (room == null || room.session.id != widget.sessionId) return;
    final alerts = LiveClassSuspiciousBehaviourService.evaluateRoom(room: room);
    if (!mounted) return;
    setState(() => _alerts = alerts);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 18,
          bottom: 240,
          child: _AutoAlertFab(
            count: _alerts.length,
            onPressed: _showAlertsSheet,
          ),
        ),
      ],
    );
  }

  Future<void> _showAlertsSheet() async {
    await _controller.refreshRoom();
    _refreshAlerts();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.78;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: _AutoAlertSheet(
                alerts: _alerts,
                reviewerName: widget.reviewerName,
                reviewerRole: widget.reviewerRole,
                onDismissAlert: _dismissAlert,
                onCreateReport: _createReport,
                onRefresh: () async {
                  await _controller.refreshRoom();
                  _refreshAlerts();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _dismissAlert(LiveClassSuspiciousBehaviourAlert alert) async {
    await LiveClassSuspiciousBehaviourService.dismissAlert(
      sessionId: widget.sessionId,
      alertId: alert.id,
    );
    _refreshAlerts();
  }

  Future<void> _createReport(LiveClassSuspiciousBehaviourAlert alert) async {
    await LiveClassSuspiciousBehaviourService.createReportFromAlert(
      alert: alert,
      reportedBy: widget.reviewerName,
      reporterRole: widget.reviewerRole,
    );
    await LiveClassSuspiciousBehaviourService.dismissAlert(
      sessionId: widget.sessionId,
      alertId: alert.id,
    );
    _refreshAlerts();
  }
}

class _AutoAlertFab extends StatelessWidget {
  const _AutoAlertFab({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          heroTag: 'live-class-auto-alert-control',
          onPressed: onPressed,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Alerts'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        if (count > 0)
          Positioned(
            right: -4,
            top: -8,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Colors.redAccent,
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AutoAlertSheet extends StatelessWidget {
  const _AutoAlertSheet({
    required this.alerts,
    required this.reviewerName,
    required this.reviewerRole,
    required this.onDismissAlert,
    required this.onCreateReport,
    required this.onRefresh,
  });

  final List<LiveClassSuspiciousBehaviourAlert> alerts;
  final String reviewerName;
  final String reviewerRole;
  final ValueChanged<LiveClassSuspiciousBehaviourAlert> onDismissAlert;
  final ValueChanged<LiveClassSuspiciousBehaviourAlert> onCreateReport;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final highRisk = alerts
        .where((item) => item.severity == LiveClassIncidentSeverity.high || item.severity == LiveClassIncidentSeverity.critical)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Automatic suspicious behaviour alerts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'These are draft alerts. Review before converting any alert into an official incident report.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.notifications_active_rounded, size: 18),
              label: Text('${alerts.length} active alerts'),
            ),
            Chip(
              avatar: const Icon(Icons.priority_high_rounded, size: 18),
              label: Text('$highRisk high risk'),
            ),
            Chip(
              avatar: const Icon(Icons.person_rounded, size: 18),
              label: Text('Reviewer: $reviewerName'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: alerts.isEmpty
              ? const Center(child: Text('No automatic suspicious behaviour alert right now.'))
              : ListView.separated(
                  itemCount: alerts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _AutoAlertTile(
                    alert: alerts[index],
                    onDismiss: () => onDismissAlert(alerts[index]),
                    onCreateReport: () => onCreateReport(alerts[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AutoAlertTile extends StatelessWidget {
  const _AutoAlertTile({
    required this.alert,
    required this.onDismiss,
    required this.onCreateReport,
  });

  final LiveClassSuspiciousBehaviourAlert alert;
  final VoidCallback onDismiss;
  final VoidCallback onCreateReport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = _severityColor(alert.severity);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(_initials(alert.participantName))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.participantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(alert.registrationNumber ?? 'Student'),
                  ],
                ),
              ),
              Chip(
                label: Text(LiveClassIncidentSeverity.label(alert.severity)),
                backgroundColor: tone.withValues(alpha: 0.16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(alert.title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(alert.description),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(LiveClassIncidentCategory.label(alert.category))),
              Chip(label: Text('Draft alert')),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onCreateReport,
                icon: const Icon(Icons.gpp_maybe_rounded),
                label: const Text('Create incident report'),
              ),
              TextButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
                label: const Text('Dismiss alert'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _severityColor(String severity) {
    return switch (severity) {
      LiveClassIncidentSeverity.low => Colors.blueAccent,
      LiveClassIncidentSeverity.medium => Colors.orangeAccent,
      LiveClassIncidentSeverity.high => Colors.deepOrangeAccent,
      LiveClassIncidentSeverity.critical => Colors.redAccent,
      _ => Colors.orangeAccent,
    };
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
