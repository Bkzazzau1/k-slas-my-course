import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../../../data/models/video_lecture_models.dart';
import '../../../data/services/video_lecture_offline_storage.dart';
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
  late bool _savedOffline;

  @override
  void initState() {
    super.initState();
    _lecturesController = Get.find<VideoLecturesController>();
    _savedOffline = VideoLectureOfflineStorage.isSaved(widget.lecture.id);
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

  Future<void> _toggleOffline() async {
    if (_savedOffline) {
      await VideoLectureOfflineStorage.removeLecture(widget.lecture.id);
      if (!mounted) return;
      setState(() => _savedOffline = false);
      Get.snackbar(
        'Offline removed',
        '${widget.lecture.title} has been removed from offline videos.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await VideoLectureOfflineStorage.saveLecture(widget.lecture.id);
    if (!mounted) return;
    setState(() => _savedOffline = true);
    Get.snackbar(
      'Offline saved',
      '${widget.lecture.title} is ready for offline viewing.',
      snackPosition: SnackPosition.BOTTOM,
    );
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

  Future<void> _openNextLesson(VideoLectureModel nextLecture) async {
    await _playerController.pause();
    if (!mounted) return;
    Get.off(
      () => VideoLecturePlayerView(
        lecture: nextLecture,
        studentId: widget.studentId,
      ),
    );
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
                  Text(
                    _time(_playerController.value.position),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VideoProgressIndicator(
                      _playerController,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(playedColor: Colors.lightBlueAccent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _time(_playerController.value.duration),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: fullscreen ? 'Exit fullscreen' : 'Fullscreen',
                    onPressed: fullscreen ? Get.back : _openFullscreen,
                    icon: Icon(fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
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
    if (!value.isInitialized) return;

    if (!_didAutoMarkWatched && value.duration > Duration.zero) {
      final remaining = value.duration - value.position;
      final watchedEnough = value.position.inSeconds >= (value.duration.inSeconds * 0.85).round();
      if (remaining <= const Duration(seconds: 1) || watchedEnough) {
        _didAutoMarkWatched = true;
        _markWatched(true, showFeedback: false);
      }
    }

    if (mounted) setState(() {});
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
      watched ? 'This lecture is now cleared for your learning path.' : 'The lecture has been returned to your pending list.',
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
          IconButton(
            tooltip: _savedOffline ? 'Remove offline copy' : 'Save offline',
            onPressed: widget.lecture.allowDownloads ? _toggleOffline : null,
            icon: Icon(_savedOffline ? Icons.cloud_done_rounded : Icons.download_rounded),
          ),
          Obx(() {
            final lecture = _lecturesController.lectures.firstWhereOrNull((item) => item.id == widget.lecture.id);
            final isWatched = lecture?.isWatchedBy(widget.studentId) ?? widget.lecture.isWatchedBy(widget.studentId);
            return IconButton(
              tooltip: isWatched ? 'Mark unwatched' : 'Mark watched',
              onPressed: () => _markWatched(!isWatched),
              icon: Icon(isWatched ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded),
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
                  _playerController.value.errorDescription ?? 'Unable to load this lecture video.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w600),
                ),
              ),
            );
          }

          final currentLecture = _lecturesController.lectures.firstWhereOrNull((item) => item.id == widget.lecture.id) ?? widget.lecture;
          final isWatched = currentLecture.isWatchedBy(widget.studentId);
          final progress = _watchProgress;
          final nextLecture = _nextLecture;

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final stageHeight = wide
                  ? (constraints.maxHeight * 0.62).clamp(420.0, 680.0)
                  : (constraints.maxWidth * 0.62).clamp(240.0, 520.0);
              final sidePanel = _LessonSidePanel(
                lecture: widget.lecture,
                watched: isWatched,
                savedOffline: _savedOffline,
                progress: progress,
                nextLecture: nextLecture,
                onToggleOffline: _toggleOffline,
                onMarkWatched: () => _markWatched(!isWatched),
                onNextLesson: nextLecture == null ? null : () => _openNextLesson(nextLecture),
              );

              return ListView(
                padding: EdgeInsets.fromLTRB(wide ? 28 : 16, wide ? 22 : 16, wide ? 28 : 16, 24),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1380),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: SizedBox(height: stageHeight, child: _buildVideoStage(fullscreen: false)),
                                ),
                                const SizedBox(width: 18),
                                Expanded(flex: 4, child: sidePanel),
                              ],
                            )
                          : Column(
                              children: [
                                SizedBox(height: stageHeight, width: double.infinity, child: _buildVideoStage(fullscreen: false)),
                                const SizedBox(height: 14),
                                sidePanel,
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1380),
                      child: _LectureDetails(lecture: widget.lecture, colorScheme: cs),
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

  double get _watchProgress {
    final value = _playerController.value;
    if (!value.isInitialized || value.duration.inMilliseconds <= 0) return 0;
    return (value.position.inMilliseconds / value.duration.inMilliseconds).clamp(0.0, 1.0);
  }

  VideoLectureModel? get _nextLecture {
    final lectures = _lecturesController.lectures
        .where((item) => item.courseCode.toUpperCase() == widget.lecture.courseCode.toUpperCase())
        .toList();
    if (lectures.isEmpty) return null;
    final index = lectures.indexWhere((item) => item.id == widget.lecture.id);
    if (index < 0 || index + 1 >= lectures.length) return null;
    return lectures[index + 1];
  }

  static String _time(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = value.inHours;
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

class _LessonSidePanel extends StatelessWidget {
  const _LessonSidePanel({
    required this.lecture,
    required this.watched,
    required this.savedOffline,
    required this.progress,
    required this.nextLecture,
    required this.onToggleOffline,
    required this.onMarkWatched,
    required this.onNextLesson,
  });

  final VideoLectureModel lecture;
  final bool watched;
  final bool savedOffline;
  final double progress;
  final VideoLectureModel? nextLecture;
  final VoidCallback onToggleOffline;
  final VoidCallback onMarkWatched;
  final VoidCallback? onNextLesson;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _PanelCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lesson progress', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: watched ? 1.0 : progress, minHeight: 10),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _PlayerMetaPill(icon: watched ? Icons.check_circle_outline_rounded : Icons.play_circle_outline_rounded, text: watched ? 'Watched' : '${(progress * 100).round()}% watched'),
            _PlayerMetaPill(icon: savedOffline ? Icons.cloud_done_outlined : Icons.cloud_download_outlined, text: savedOffline ? 'Offline saved' : 'Not offline'),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onMarkWatched,
                icon: Icon(watched ? Icons.remove_done_outlined : Icons.check_circle_outline_rounded),
                label: Text(watched ? 'Unwatch' : 'Mark watched'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: lecture.allowDownloads ? onToggleOffline : null,
                icon: Icon(savedOffline ? Icons.cloud_off_outlined : Icons.download_rounded),
                label: Text(savedOffline ? 'Remove' : 'Offline'),
              ),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      _PanelCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Lesson notes', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 8),
          _Bullet(text: lecture.subtitle),
          _Bullet(text: 'Lecturer: ${lecture.lecturerName}'),
          _Bullet(text: 'Duration: ${lecture.durationMinutes} minutes'),
          if (lecture.tags.isNotEmpty) _Bullet(text: 'Focus: ${lecture.tags.join(', ')}'),
          const SizedBox(height: 8),
          Text(
            'Tip: watch the lesson, read the weekly note, then attempt the assessment practice.',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700, height: 1.28),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      _PanelCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Next lesson', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 8),
          if (nextLecture == null)
            Text('You are at the last available lesson for this course.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600))
          else ...[
            Text(nextLecture!.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(nextLecture!.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onNextLesson, icon: const Icon(Icons.skip_next_rounded), label: const Text('Open next lesson'))),
          ],
        ]),
      ),
    ]);
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 8), color: cs.shadow.withValues(alpha: 0.04))],
      ),
      child: child,
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(text, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w600, height: 1.30))),
      ]),
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
    return _PanelCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(lecture.subtitle, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          lecture.description,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.78), fontWeight: FontWeight.w600, height: 1.35),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _PlayerMetaPill(icon: Icons.schedule_rounded, text: '${lecture.durationMinutes} min'),
          _PlayerMetaPill(icon: Icons.person_outline_rounded, text: lecture.lecturerName),
          _PlayerMetaPill(icon: Icons.cloud_done_outlined, text: lecture.allowDownloads ? 'Download allowed' : 'Stream only'),
          for (final tag in lecture.tags) _PlayerMetaPill(icon: Icons.label_outline_rounded, text: tag),
        ]),
      ]),
    );
  }
}

class _FullscreenLecturePlayer extends StatelessWidget {
  const _FullscreenLecturePlayer({required this.controller, required this.title, required this.onTogglePlayback});

  final VideoPlayerController controller;
  final String title;
  final Future<void> Function() onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    final aspectRatio = controller.value.aspectRatio == 0 ? (16 / 9) : controller.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: Center(child: AspectRatio(aspectRatio: aspectRatio, child: VideoPlayer(controller)))),
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(children: [
                IconButton.filledTonal(tooltip: 'Exit fullscreen', onPressed: Get.back, icon: const Icon(Icons.close_fullscreen_rounded)),
                const SizedBox(width: 12),
                Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
              ]),
            ),
            Center(
              child: IconButton.filledTonal(
                onPressed: onTogglePlayback,
                iconSize: 56,
                icon: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: VideoProgressIndicator(controller, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.lightBlueAccent)),
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
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
