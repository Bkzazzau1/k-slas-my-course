import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../../../data/models/student_category.dart';
import '../../../data/models/video_lecture_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/video_lecture_offline_storage.dart';
import '../../../features/dashboard/controller/dashboard_controller.dart';
import '../../video_lectures/controller/video_lectures_controller.dart';
import '../../video_lectures/view/video_lecture_player_view.dart';

class VideoLecturesTab extends StatefulWidget {
  const VideoLecturesTab({super.key, required this.course});

  final CourseModel course;

  @override
  State<VideoLecturesTab> createState() => _VideoLecturesTabState();
}

class _VideoLecturesTabState extends State<VideoLecturesTab> {
  String selectedFilter = 'All';
  Set<String> offlineIds = <String>{};

  @override
  void initState() {
    super.initState();
    offlineIds = VideoLectureOfflineStorage.loadIds();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VideoLecturesController>()
        ? Get.find<VideoLecturesController>()
        : Get.put(VideoLecturesController());
    final dashboard = Get.isRegistered<DashboardController>() ? Get.find<DashboardController>() : null;

    return Obx(() {
      final category = dashboard?.studentCategory.value ?? _storedStudentCategory();
      final studentId = _studentId();
      final allLectures = controller.lecturesForCourse(widget.course.code);
      final visibleLectures = controller.lecturesForCourse(widget.course.code, category: category);

      if (allLectures.isEmpty && !controller.isLoading.value) {
        controller.loadLectures(courseCode: widget.course.code);
      }

      final filters = _filtersFor(visibleLectures);
      final filteredLectures = selectedFilter == 'All'
          ? visibleLectures
          : visibleLectures.where((lecture) => lecture.tags.contains(selectedFilter)).toList();
      final watchedCount = visibleLectures.where((lecture) => lecture.isWatchedBy(studentId)).length;
      final offlineCount = visibleLectures.where((lecture) => offlineIds.contains(lecture.id)).length;
      final totalMinutes = visibleLectures.fold<int>(0, (sum, lecture) => sum + lecture.durationMinutes);

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        children: [
          _VideoHero(
            courseCode: widget.course.code,
            category: category,
            totalLectures: visibleLectures.length,
            watchedCount: watchedCount,
            offlineCount: offlineCount,
            totalMinutes: totalMinutes,
          ),
          const SizedBox(height: 12),
          _LearningPathCard(category: category),
          const SizedBox(height: 12),
          _CategoryFilterBar(
            filters: filters,
            selected: selectedFilter,
            onSelected: (value) => setState(() => selectedFilter = value),
          ),
          const SizedBox(height: 12),
          _SectionHeader(
            title: 'Video lessons',
            subtitle: '${filteredLectures.length} lesson${filteredLectures.length == 1 ? '' : 's'} shown • progress is tracked per student',
          ),
          const SizedBox(height: 10),
          if (controller.isLoading.value)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (visibleLectures.isEmpty)
            _EmptyVideoState(
              message: allLectures.isEmpty
                  ? 'No lecture has been uploaded for ${widget.course.code} yet.'
                  : 'Lectures exist for ${widget.course.code}, but none are targeted at the ${category.shortLabel.toLowerCase()} path yet.',
            )
          else if (filteredLectures.isEmpty)
            const _EmptyVideoState(message: 'No lecture found under this category yet.')
          else
            for (final lecture in filteredLectures)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LectureCard(
                  lecture: lecture,
                  studentId: studentId,
                  currentCategory: category,
                  savedOffline: offlineIds.contains(lecture.id),
                  onWatch: () => Get.to(
                    () => VideoLecturePlayerView(lecture: lecture, studentId: studentId),
                  ),
                  onToggleWatched: () async {
                    final watched = lecture.isWatchedBy(studentId);
                    await controller.markLectureWatched(
                      lectureId: lecture.id,
                      studentId: studentId,
                      watched: !watched,
                    );
                  },
                  onToggleOffline: () async {
                    if (offlineIds.contains(lecture.id)) {
                      await VideoLectureOfflineStorage.removeLecture(lecture.id);
                      Get.snackbar('Offline removed', '${lecture.title} removed from offline videos.', snackPosition: SnackPosition.BOTTOM);
                    } else {
                      await VideoLectureOfflineStorage.saveLecture(lecture.id);
                      Get.snackbar('Offline saved', '${lecture.title} is ready for offline viewing.', snackPosition: SnackPosition.BOTTOM);
                    }
                    setState(() => offlineIds = VideoLectureOfflineStorage.loadIds());
                  },
                ),
              ),
        ],
      );
    });
  }

  List<String> _filtersFor(List<VideoLectureModel> lectures) {
    final tags = <String>{'All'};
    for (final lecture in lectures) {
      tags.addAll(lecture.tags.where((tag) => tag.trim().isNotEmpty));
    }
    if (tags.length == 1) {
      tags.addAll(['Core', 'Revision', 'Assessment']);
    }
    return tags.toList();
  }

  StudentCategory _storedStudentCategory() {
    final profile = StudentProfileStorage.load();
    return studentCategoryFromStorage(profile?.studentCategoryKey);
  }

  String _studentId() {
    final profile = StudentProfileStorage.load();
    final matric = profile?.matricNo?.trim() ?? '';
    if (matric.isNotEmpty) return matric;
    final email = profile?.email?.trim() ?? '';
    if (email.isNotEmpty) return email.toLowerCase();
    return 'student-demo';
  }
}

class _VideoHero extends StatelessWidget {
  const _VideoHero({
    required this.courseCode,
    required this.category,
    required this.totalLectures,
    required this.watchedCount,
    required this.offlineCount,
    required this.totalMinutes,
  });

  final String courseCode;
  final StudentCategory category;
  final int totalLectures;
  final int watchedCount;
  final int offlineCount;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = totalLectures == 0 ? 0.0 : watchedCount / totalLectures;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 14), color: cs.primary.withValues(alpha: 0.15))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 26, backgroundColor: Colors.white.withValues(alpha: 0.18), child: const Icon(Icons.play_circle_outline_rounded, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$courseCode video lectures', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
              const SizedBox(height: 4),
              Text(category.label, style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
            ]),
          ),
          Text('${(progress * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white.withValues(alpha: 0.20)),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: '$totalLectures lessons'),
          _HeroPill(label: '$watchedCount watched'),
          _HeroPill(label: '$offlineCount offline'),
          _HeroPill(label: '$totalMinutes min'),
        ]),
      ]),
    );
  }
}

class _LearningPathCard extends StatelessWidget {
  const _LearningPathCard({required this.category});
  final StudentCategory category;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.route_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text('Learning path', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
          _Badge(text: category.shortLabel, active: true),
        ]),
        const SizedBox(height: 10),
        _InfoLine(icon: Icons.video_library_outlined, text: category.lectureDeliverySummary),
        const SizedBox(height: 8),
        _InfoLine(icon: Icons.done_all_outlined, text: category.watchExpectation),
        const SizedBox(height: 8),
        _InfoLine(icon: Icons.fact_check_outlined, text: category.attendanceRule),
      ]),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.filters, required this.selected, required this.onSelected});
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: filter == selected,
                  onSelected: (_) => onSelected(filter),
                  selectedColor: cs.primary.withValues(alpha: 0.14),
                  labelStyle: TextStyle(color: filter == selected ? cs.primary : cs.onSurface, fontWeight: FontWeight.w900),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LectureCard extends StatelessWidget {
  const _LectureCard({
    required this.lecture,
    required this.studentId,
    required this.currentCategory,
    required this.savedOffline,
    required this.onWatch,
    required this.onToggleWatched,
    required this.onToggleOffline,
  });

  final VideoLectureModel lecture;
  final String studentId;
  final StudentCategory currentCategory;
  final bool savedOffline;
  final VoidCallback onWatch;
  final VoidCallback onToggleWatched;
  final VoidCallback onToggleOffline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final watched = lecture.isWatchedBy(studentId);
    final color = watched ? Colors.green.shade700 : cs.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 8), color: cs.shadow.withValues(alpha: 0.035))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(18)),
            child: Icon(watched ? Icons.check_circle_outline_rounded : Icons.play_circle_outline_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lecture.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 5),
              Text(lecture.subtitle, style: _mutedStyle(context)),
              const SizedBox(height: 7),
              Text(lecture.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: _mutedStyle(context)),
            ]),
          ),
          _Badge(text: watched ? 'Watched' : 'Pending', active: watched),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: watched ? 1.0 : 0.0, minHeight: 9, backgroundColor: cs.onSurface.withValues(alpha: 0.06)),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Badge(text: '${lecture.durationMinutes} min'),
          _Badge(text: lecture.lecturerName),
          _Badge(text: lecture.allowDownloads ? 'Downloadable' : 'Stream only'),
          _Badge(text: savedOffline ? 'Offline saved' : 'Not offline', active: savedOffline),
          for (final tag in lecture.tags) _Badge(text: tag),
          for (final audience in lecture.audiences) _Badge(text: audience.shortLabel, active: audience == currentCategory),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: onWatch, icon: const Icon(Icons.play_arrow_rounded), label: Text(watched ? 'Watch again' : 'Watch now'))),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onToggleWatched,
              icon: Icon(watched ? Icons.remove_done_outlined : Icons.check_circle_outline_rounded),
              label: Text(watched ? 'Unwatch' : 'Mark watched'),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: lecture.allowDownloads ? onToggleOffline : null,
            icon: Icon(savedOffline ? Icons.cloud_done_outlined : Icons.download_rounded),
            label: Text(savedOffline ? 'Remove offline copy' : 'Save for offline viewing'),
          ),
        ),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 6),
      Text(subtitle, style: _mutedStyle(context)),
    ]);
  }
}

class _EmptyVideoState extends StatelessWidget {
  const _EmptyVideoState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: cs.onSurface.withValues(alpha: 0.06))),
      child: Text(message, style: _mutedStyle(context)),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: _mutedStyle(context))),
    ]);
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.active = false});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? cs.primary.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: active ? cs.primary : cs.onSurface, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

TextStyle _mutedStyle(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
    fontWeight: FontWeight.w600,
    height: 1.30,
  );
}
