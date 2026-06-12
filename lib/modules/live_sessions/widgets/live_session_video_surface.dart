import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../data/models/live_session_models.dart';

class LiveSessionVideoSurface extends StatelessWidget {
  const LiveSessionVideoSurface({
    super.key,
    required this.participant,
    required this.mediaParticipant,
    required this.borderRadius,
  });

  final LiveSessionParticipant participant;
  final lk.Participant? mediaParticipant;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final participantListenable = mediaParticipant;
    if (participantListenable == null) {
      return _VideoFallback(
        participant: participant,
        borderRadius: borderRadius,
        isSpeaking: false,
      );
    }

    return AnimatedBuilder(
      animation: participantListenable,
      builder: (context, _) {
        final track = liveSessionVideoTrackFor(participantListenable);
        if (track == null || track.muted) {
          return _VideoFallback(
            participant: participant,
            borderRadius: borderRadius,
            isSpeaking: participantListenable.isSpeaking,
          );
        }

        final accent = _accentForRole(participant.role);
        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.cover),
              if (participantListenable.isSpeaking)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.70),
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

lk.VideoTrack? liveSessionVideoTrackFor(lk.Participant? participant) {
  if (participant == null) return null;
  for (final publication in participant.videoTrackPublications) {
    if (publication.isScreenShare) continue;
    final track = publication.track;
    if (track is lk.VideoTrack) {
      return track;
    }
  }
  return null;
}

lk.VideoTrack? liveSessionScreenShareTrackFor(lk.Participant? participant) {
  if (participant == null) return null;
  for (final publication in participant.videoTrackPublications) {
    if (!publication.isScreenShare) continue;
    final track = publication.track;
    if (track is lk.VideoTrack) {
      return track;
    }
  }
  return null;
}

Color _accentForRole(String role) {
  return role == LiveSessionRole.lecturer
      ? Colors.blueAccent
      : Colors.tealAccent;
}

class _VideoFallback extends StatelessWidget {
  const _VideoFallback({
    required this.participant,
    required this.borderRadius,
    required this.isSpeaking,
  });

  final LiveSessionParticipant participant;
  final BorderRadius borderRadius;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForRole(participant.role);
    final icon = participant.cameraEnabled
        ? Icons.videocam_rounded
        : Icons.videocam_off_rounded;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: (isSpeaking ? accent : Colors.white).withValues(
            alpha: isSpeaking ? 0.55 : 0.08,
          ),
          width: isSpeaking ? 2.5 : 1.2,
        ),
      ),
      child: Center(child: Icon(icon, size: 44, color: accent)),
    );
  }
}
