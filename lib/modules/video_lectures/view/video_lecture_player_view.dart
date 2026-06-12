import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../data/models/video_lecture_models.dart';
import '../controller/video_lectures_controller.dart';

class VideoLecturePlayerView extends StatefulWidget {
  const VideoLecturePlayerView({
    super.key,
    required this.lecture,
    required this.studentId,
  });

  final VideoLectureModel lecture;
  final String studentId;

  @override
  State<VideoLecturePlayerView> createState() => _VideoLecturePlayerViewState();
}

class _VideoLecturePlayerViewState extends State<VideoLecturePlayerView> {
  late final VideoPlayerController _playerController;
  late final Future<void> _initializeFuture;
  late final VideoLecturesController _lecturesController;
  bool _didAutoMarkWatched = false;

  @override
  void initState() {
    super.initState();
    _lecturesController = Get.find<VideoLecturesController>();
    _playerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.lecture.videoUrl),
    )..addListener(_handlePlaybackState);
    _initializeFuture = _playerController.initialize();
  }

  @override
  void dispose() {
    _playerController
      ..removeListener(_handlePlaybackState)
      ..dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_playerController.value.isPlaying) {
      await _playerController.pause();
      return;
    }
    await _playerController.play();
  }

  Future<void> _openFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await Get.to(
      () => _FullscreenLecturePlayer(
        controller: _playerController,
        title: widget.lecture.title,
        onTogglePlayback: _togglePlayback,
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  Widget _buildVideoStage({required bool fullscreen}) {
    final aspectRatio = _playerController.value.aspectRatio == 0
        ? (16 / 9)
        : _playerController.value.aspectRatio;
    return ClipRRect(
      borderRadius: BorderRadius.circular(fullscreen ? 0 : 22),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: VideoPlayer(_playerController),
              ),
            ),
            IconButton.filledTonal(
              onPressed: _togglePlayback,
              iconSize: fullscreen ? 54 : 46,
              icon: Icon(
                _playerController.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            Positioned(
              left: fullscreen ? 24 : 14,
              right: fullscreen ? 24 : 14,
              bottom: fullscreen ? 24 : 14,
              child: Row(
                children: [
                  Expanded(
                    child: VideoProgressIndicator(
                      _playerController,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                    onPressed: fullscreen ? Get.back : _openFullscreen,
                    icon: Icon(
                      fullscreen
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePlaybackState() {
    final value = _playerController.value;
    if (!value.isInitialized || _didAutoMarkWatched) return;
    if (value.duration <= Duration.zero) return;

    final remaining = value.duration - value.position;
    if (remaining <= const Duration(seconds: 1)) {
      _didAutoMarkWatched = true;
      _markWatched(true, showFeedback: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _markWatched(bool watched, {bool showFeedback = true}) async {
    await _lecturesController.markLectureWatched(
      lectureId: widget.lecture.id,
      studentId: widget.studentId,
      watched: watched,
    );
    if (!mounted || !showFeedback) return;
    Get.snackbar(
      watched ? 'Lecture marked watched' : 'Lecture marked unwatched',
      watched
          ? 'This lecture is now cleared for your learning path.'
          : 'The lecture has been returned to your pending list.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lecture.title),
        actions: [
          Obx(() {
            final lecture = _lecturesController.lectures.firstWhereOrNull(
              (item) => item.id == widget.lecture.id,
            );
            final isWatched =
                lecture?.isWatchedBy(widget.studentId) ??
                widget.lecture.isWatchedBy(widget.studentId);
            return IconButton(
              tooltip: isWatched ? 'Mark unwatched' : 'Mark watched',
              onPressed: () => _markWatched(!isWatched),
              icon: Icon(
                isWatched
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
              ),
            );
          }),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_playerController.value.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _playerController.value.errorDescription ??
                      'Unable to load this lecture video.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final stageHeight = wide
                  ? (constraints.maxHeight * 0.70).clamp(460.0, 760.0)
                  : (constraints.maxWidth * 0.62).clamp(260.0, 520.0);
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  wide ? 28 : 16,
                  wide ? 22 : 16,
                  wide ? 28 : 16,
                  24,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: SizedBox(
                        height: stageHeight,
                        width: double.infinity,
                        child: _buildVideoStage(fullscreen: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: _LectureDetails(
                        lecture: widget.lecture,
                        colorScheme: cs,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LectureDetails extends StatelessWidget {
  const _LectureDetails({required this.lecture, required this.colorScheme});

  final VideoLectureModel lecture;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lecture.subtitle,
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          lecture.description,
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.78),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PlayerMetaPill(
              icon: Icons.schedule_rounded,
              text: '${lecture.durationMinutes} min',
            ),
            _PlayerMetaPill(
              icon: Icons.person_outline_rounded,
              text: lecture.lecturerName,
            ),
            _PlayerMetaPill(
              icon: Icons.cloud_done_outlined,
              text: lecture.allowDownloads ? 'Download allowed' : 'Stream only',
            ),
          ],
        ),
      ],
    );
  }
}

class _FullscreenLecturePlayer extends StatelessWidget {
  const _FullscreenLecturePlayer({
    required this.controller,
    required this.title,
    required this.onTogglePlayback,
  });

  final VideoPlayerController controller;
  final String title;
  final Future<void> Function() onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = controller.value.aspectRatio == 0
        ? (16 / 9)
        : controller.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Exit fullscreen',
                    onPressed: Get.back,
                    icon: const Icon(Icons.close_fullscreen_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: IconButton.filledTonal(
                onPressed: onTogglePlayback,
                iconSize: 56,
                icon: Icon(
                  controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.lightBlueAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerMetaPill extends StatelessWidget {
  const _PlayerMetaPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
