import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_moderation_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveClassModerationOverlay extends StatefulWidget {
  const LiveClassModerationOverlay({
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
  State<LiveClassModerationOverlay> createState() =>
      _LiveClassModerationOverlayState();
}

class _LiveClassModerationOverlayState extends State<LiveClassModerationOverlay> {
  late final LiveSessionsController _controller;
  Timer? _timer;
  List<LiveClassModerationCommand> _commands = const [];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();
    _reload();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _reload());
  }

  @override
  void didUpdateWidget(covariant LiveClassModerationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId) _reload();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reload() {
    if (!widget.enabled || widget.sessionId.trim().isEmpty) return;
    final commands = LiveClassModerationService.loadCommands(widget.sessionId);
    if (!mounted) return;
    setState(() => _commands = commands);
  }

  int get _pendingCount => _commands.where((item) => !item.isApplied).length;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 18,
          bottom: 92,
          child: _ModerationButton(
            count: _pendingCount,
            onPressed: _showModerationSheet,
          ),
        ),
      ],
    );
  }

  Future<void> _showModerationSheet() async {
    await _controller.refreshRoom();
    _reload();
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
              child: Obx(() {
                final room = _controller.room.value;
                final students = (room?.participants ?? const <LiveSessionParticipant>[])
                    .where((item) => item.role == LiveSessionRole.student)
                    .toList()
                  ..sort((a, b) => a.displayName.compareTo(b.displayName));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Class moderation control',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () async {
                            await _controller.refreshRoom();
                            _reload();
                          },
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lecturer can mute microphone, turn camera off, or remove a disruptive student from the live class.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: students.isEmpty
                          ? const Center(child: Text('No student participant yet.'))
                          : ListView.separated(
                              itemCount: students.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final student = students[index];
                                return _ModerationStudentTile(
                                  student: student,
                                  onMute: () => _issue(
                                    student,
                                    LiveClassModerationAction.muteMicrophone,
                                  ),
                                  onCameraOff: () => _issue(
                                    student,
                                    LiveClassModerationAction.disableCamera,
                                  ),
                                  onRemove: () => _confirmRemove(context, student),
                                );
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

  Future<void> _issue(LiveSessionParticipant participant, String action) async {
    await LiveClassModerationService.issueCommand(
      sessionId: widget.sessionId,
      participantId: participant.id,
      participantName: participant.displayName,
      action: action,
      issuedBy: widget.lecturerName,
    );
    _reload();
    if (!mounted) return;
    final label = switch (action) {
      LiveClassModerationAction.muteMicrophone => 'Mute command sent',
      LiveClassModerationAction.disableCamera => 'Camera-off command sent',
      LiveClassModerationAction.removeParticipant => 'Remove command sent',
      _ => 'Command sent',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  Future<void> _confirmRemove(
    BuildContext context,
    LiveSessionParticipant participant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text(
          'This will remove ${participant.displayName} from the current live class on their next sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.person_remove_rounded),
            label: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _issue(participant, LiveClassModerationAction.removeParticipant);
    }
  }
}

class _ModerationButton extends StatelessWidget {
  const _ModerationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.extended(
          heroTag: 'class-moderation-control',
          onPressed: onPressed,
          icon: const Icon(Icons.admin_panel_settings_rounded),
          label: const Text('Moderate'),
          backgroundColor: cs.secondary,
          foregroundColor: cs.onSecondary,
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

class _ModerationStudentTile extends StatelessWidget {
  const _ModerationStudentTile({
    required this.student,
    required this.onMute,
    required this.onCameraOff,
    required this.onRemove,
  });

  final LiveSessionParticipant student;
  final VoidCallback onMute;
  final VoidCallback onCameraOff;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(_initials(student.displayName))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      student.registrationNumber ?? 'Student',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 5,
                children: [
                  Icon(student.micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
                  Icon(student.cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: student.micEnabled ? onMute : null,
                icon: const Icon(Icons.mic_off_rounded),
                label: const Text('Mute'),
              ),
              FilledButton.tonalIcon(
                onPressed: student.cameraEnabled ? onCameraOff : null,
                icon: const Icon(Icons.videocam_off_rounded),
                label: const Text('Camera off'),
              ),
              OutlinedButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.person_remove_rounded),
                label: const Text('Remove'),
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
