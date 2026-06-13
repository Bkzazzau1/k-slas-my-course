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
        final screenTrack = liveSessionScreenShareTrackFor(participantListenable);
        final cameraTrack = liveSessionVideoTrackFor(participantListenable);
        final useScreenShare = screenTrack != null && !screenTrack.muted;
        final track = useScreenShare ? screenTrack : cameraTrack;
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
              lk.VideoTrackRenderer(
                track,
                fit: useScreenShare ? lk.VideoViewFit.contain : lk.VideoViewFit.cover,
              ),
              if (useScreenShare)
                Positioned(
                  left: 12,
                  top: 12,
                  child: _SurfaceLabel(
                    icon: Icons.screen_share_rounded,
                    label: '${participant.displayName} screen',
                  ),
                ),
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

class LiveSessionScreenShareSurface extends StatelessWidget {
  const LiveSessionScreenShareSurface({
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
      return _ScreenShareFallback(
        participant: participant,
        borderRadius: borderRadius,
      );
    }

    return AnimatedBuilder(
      animation: participantListenable,
      builder: (context, _) {
        final track = liveSessionScreenShareTrackFor(participantListenable);
        if (track == null || track.muted) {
          return _ScreenShareFallback(
            participant: participant,
            borderRadius: borderRadius,
          );
        }

        return ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              lk.VideoTrackRenderer(track, fit: lk.VideoViewFit.contain),
              Positioned(
                left: 12,
                top: 12,
                child: _SurfaceLabel(
                  icon: Icons.screen_share_rounded,
                  label: '${participant.displayName} screen',
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

class _ScreenShareFallback extends StatelessWidget {
  const _ScreenShareFallback({required this.participant, required this.borderRadius});

  final LiveSessionParticipant participant;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.26),
            Colors.black.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_share_rounded, color: cs.primary, size: 52),
            const SizedBox(height: 10),
            Text(
              '${participant.displayName} screen share',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Waiting for shared screen stream...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceLabel extends StatelessWidget {
  const _SurfaceLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
