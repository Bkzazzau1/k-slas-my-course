import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/live_screen_share_control_service.dart';

class LiveScreenShareApprovalOverlay extends StatefulWidget {
  const LiveScreenShareApprovalOverlay({
    super.key,
    required this.child,
    required this.sessionId,
    required this.lecturerName,
    required this.enabled,
  });

  final Widget child;
  final String sessionId;
  final String lecturerName;
  final bool enabled;

  @override
  State<LiveScreenShareApprovalOverlay> createState() =>
      _LiveScreenShareApprovalOverlayState();
}

class _LiveScreenShareApprovalOverlayState
    extends State<LiveScreenShareApprovalOverlay> {
  Timer? _timer;
  List<LiveScreenShareRequest> _requests = const [];

  List<LiveScreenShareRequest> get _pending =>
      _requests.where((item) => item.isPending).toList();

  List<LiveScreenShareRequest> get _active =>
      _requests.where((item) => item.isActive || item.isApproved).toList();

  @override
  void initState() {
    super.initState();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _reload());
  }

  @override
  void didUpdateWidget(covariant LiveScreenShareApprovalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) {
      _reload();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!widget.enabled || widget.sessionId.trim().isEmpty) return;
    final items = LiveScreenShareControlService.loadRequests(widget.sessionId);
    if (!mounted) return;
    setState(() => _requests = items);
  }

  Future<void> _approve(LiveScreenShareRequest request) async {
    await LiveScreenShareControlService.approve(
      sessionId: widget.sessionId,
      requestId: request.id,
      lecturerName: widget.lecturerName,
    );
    _reload();
  }

  Future<void> _deny(LiveScreenShareRequest request) async {
    await LiveScreenShareControlService.deny(
      sessionId: widget.sessionId,
      requestId: request.id,
      lecturerName: widget.lecturerName,
    );
    _reload();
  }

  Future<void> _stop(LiveScreenShareRequest request) async {
    await LiveScreenShareControlService.stop(
      sessionId: widget.sessionId,
      participantId: request.participantId,
      stoppedBy: widget.lecturerName,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final count = _pending.length + _active.length;
    return Stack(
      children: [
        widget.child,
        Positioned(
          right: 18,
          bottom: 92,
          child: _ApprovalButton(
            count: count,
            hasPending: _pending.isNotEmpty,
            onPressed: _showApprovalSheet,
          ),
        ),
      ],
    );
  }

  Future<void> _showApprovalSheet() async {
    _reload();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final height = MediaQuery.sizeOf(context).height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.screen_share_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Student screen-share control',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Students must request approval before their screen becomes visible in class.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _requests.isEmpty
                        ? const Center(child: Text('No screen-share request yet.'))
                        : ListView.separated(
                            itemCount: _requests.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final request = _requests[index];
                              return _ScreenShareRequestTile(
                                request: request,
                                onApprove: request.isPending
                                    ? () => _approve(request)
                                    : null,
                                onDeny: request.isPending ? () => _deny(request) : null,
                                onStop: (request.isApproved || request.isActive)
                                    ? () => _stop(request)
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ApprovalButton extends StatelessWidget {
  const _ApprovalButton({
    required this.count,
    required this.hasPending,
    required this.onPressed,
  });

  final int count;
  final bool hasPending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          heroTag: 'screen-share-approval-control',
          onPressed: onPressed,
          icon: Icon(hasPending ? Icons.notification_important_rounded : Icons.screen_share_rounded),
          label: Text(hasPending ? 'Approve share' : 'Screen control'),
          backgroundColor: hasPending ? Colors.orangeAccent : cs.primary,
          foregroundColor: hasPending ? Colors.black : cs.onPrimary,
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

class _ScreenShareRequestTile extends StatelessWidget {
  const _ScreenShareRequestTile({
    required this.request,
    required this.onApprove,
    required this.onDeny,
    required this.onStop,
  });

  final LiveScreenShareRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = switch (request.status) {
      LiveScreenShareStatus.pending => Colors.orangeAccent,
      LiveScreenShareStatus.approved => Colors.lightGreenAccent,
      LiveScreenShareStatus.active => Colors.greenAccent,
      LiveScreenShareStatus.denied => Colors.redAccent,
      LiveScreenShareStatus.stopped => cs.onSurfaceVariant,
      _ => cs.primary,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Text(_initials(request.studentName)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.studentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      request.registrationNumber.isEmpty
                          ? 'Student'
                          : request.registrationNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(request.status.toUpperCase()),
                avatar: Icon(_statusIcon(request.status), size: 18),
                backgroundColor: statusColor.withValues(alpha: 0.16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.reason,
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onApprove != null)
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Approve'),
                ),
              if (onDeny != null)
                OutlinedButton.icon(
                  onPressed: onDeny,
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Deny'),
                ),
              if (onStop != null)
                FilledButton.tonalIcon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop_screen_share_rounded),
                  label: const Text('Stop share'),
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

  static IconData _statusIcon(String status) {
    return switch (status) {
      LiveScreenShareStatus.pending => Icons.hourglass_top_rounded,
      LiveScreenShareStatus.approved => Icons.verified_rounded,
      LiveScreenShareStatus.active => Icons.screen_share_rounded,
      LiveScreenShareStatus.denied => Icons.block_rounded,
      LiveScreenShareStatus.stopped => Icons.stop_circle_outlined,
      _ => Icons.screen_share_rounded,
    };
  }
}
