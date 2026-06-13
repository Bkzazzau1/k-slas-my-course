import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_attendance_enforcement_service.dart';
import '../controller/live_sessions_controller.dart';

class LiveClassStudentAttendanceOverlay extends StatefulWidget {
  const LiveClassStudentAttendanceOverlay({
    super.key,
    required this.child,
    required this.sessionId,
    required this.enabled,
  });

  final Widget child;
  final String sessionId;
  final bool enabled;

  @override
  State<LiveClassStudentAttendanceOverlay> createState() =>
      _LiveClassStudentAttendanceOverlayState();
}

class _LiveClassStudentAttendanceOverlayState
    extends State<LiveClassStudentAttendanceOverlay> {
  late final LiveSessionsController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LiveSessionsController>();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
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
        Obx(() {
          final room = _controller.room.value;
          if (room == null || room.session.id != widget.sessionId) {
            return const SizedBox.shrink();
          }
          final participantId = _controller.activeParticipantId.value;
          if (participantId == null || participantId.trim().isEmpty) {
            return const SizedBox.shrink();
          }
          final participant = room.participants.firstWhereOrNull(
            (item) => item.id == participantId && item.role == LiveSessionRole.student,
          );
          if (participant == null || !room.session.attendanceEnabled) {
            return const SizedBox.shrink();
          }
          final status = LiveClassAttendanceEnforcementService.statusFor(
            session: room.session,
            participant: participant,
          );
          return Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: _StudentAttendanceCard(status: status),
          );
        }),
      ],
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  const _StudentAttendanceCard({required this.status});

  final LiveClassAttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = status.isQualified ? Colors.greenAccent : Colors.orangeAccent;
    return Material(
      elevation: 12,
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tone.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: status.attendancePercentage / 100,
                    strokeWidth: 6,
                  ),
                ),
                Text(
                  '${status.attendancePercentage}%',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${status.attendanceMinutes} minutes attended • Minimum ${status.minimumPercentage}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  if (status.isLateJoin)
                    Text(
                      'Late join flagged',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              status.isQualified ? Icons.verified_rounded : Icons.warning_amber_rounded,
              color: tone,
            ),
          ],
        ),
      ),
    );
  }
}
