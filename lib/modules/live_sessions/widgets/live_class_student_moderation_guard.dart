import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/live_class_moderation_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveClassStudentModerationGuard extends StatefulWidget {
  const LiveClassStudentModerationGuard({
    super.key,
    required this.child,
    required this.sessionId,
    required this.participantId,
    required this.enabled,
  });

  final Widget child;
  final String sessionId;
  final String participantId;
  final bool enabled;

  @override
  State<LiveClassStudentModerationGuard> createState() =>
      _LiveClassStudentModerationGuardState();
}

class _LiveClassStudentModerationGuardState
    extends State<LiveClassStudentModerationGuard> {
  late final LiveSessionsController _controller;
  Timer? _timer;
  bool _isLeaving = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _applyCommands());
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyCommands());
  }

  @override
  void didUpdateWidget(covariant LiveClassStudentModerationGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId ||
        oldWidget.participantId != widget.participantId) {
      unawaited(_applyCommands());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _applyCommands() async {
    if (!widget.enabled || _isLeaving) return;
    if (widget.sessionId.trim().isEmpty || widget.participantId.trim().isEmpty) {
      return;
    }

    final commands = LiveClassModerationService.pendingForParticipant(
      sessionId: widget.sessionId,
      participantId: widget.participantId,
    );
    if (commands.isEmpty) return;

    for (final command in commands.reversed) {
      switch (command.action) {
        case LiveClassModerationAction.muteMicrophone:
          await _controller.toggleMicrophone(false);
          await _markApplied(command);
          _notify('Your microphone was muted by the lecturer.');
          break;
        case LiveClassModerationAction.disableCamera:
          await _controller.toggleCamera(false);
          await _markApplied(command);
          _notify('Your camera was turned off by the lecturer.');
          break;
        case LiveClassModerationAction.removeParticipant:
          await _markApplied(command);
          await _leaveClass(command);
          return;
      }
    }
  }

  Future<void> _markApplied(LiveClassModerationCommand command) {
    return LiveClassModerationService.markApplied(
      sessionId: widget.sessionId,
      commandId: command.id,
    );
  }

  Future<void> _leaveClass(LiveClassModerationCommand command) async {
    if (_isLeaving) return;
    _isLeaving = true;
    await _controller.disconnectMediaRoom();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          command.reason?.trim().isNotEmpty == true
              ? command.reason!
              : 'You were removed from the live class by the lecturer.',
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) Get.back<void>();
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
