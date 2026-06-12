import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../../../data/models/student_category.dart';
import '../../../data/models/video_lecture_models.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../features/dashboard/controller/dashboard_controller.dart';
import '../../video_lectures/controller/video_lectures_controller.dart';
import '../../video_lectures/view/video_lecture_player_view.dart';

class VideoLecturesTab extends StatelessWidget {
  const VideoLecturesTab({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<VideoLecturesController>();
    final dashboard = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : null;

    return Obx(() {
      final category =
          dashboard?.studentCategory.value ?? _storedStudentCategory();
      final studentId = _studentId();
      final allLectures = controller.lecturesForCourse(course.code);
      final visibleLectures = controller.lecturesForCourse(
        course.code,
        category: category,
      );

      if (allLectures.isEmpty && !controller.isLoading.value) {
        controller.loadLectures(courseCode: course.code);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        children: [
          Row(
            children: [
              Expanded(
                child: _Header(
                  title: 'Video lectures',
                  subtitle:
                      'Lecturer uploads from the backend appear here with per-student watched tracking.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      category.label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    _Badge(text: category.pathTitle),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${course.code} follows this lecture-delivery path for the current student category.',
                  style: _mutedStyle(context),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  icon: Icons.route_outlined,
                  text: category.lectureDeliverySummary,
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.done_all_outlined,
                  text: category.watchExpectation,
                ),
                const SizedBox(height: 10),
                _InfoLine(
                  icon: Icons.fact_check_outlined,
                  text: category.attendanceRule,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  title: 'Learner paths',
                  subtitle:
                      'All six student paths are now mapped so lecture publishing can target the right audience.',
                ),
                const SizedBox(height: 14),
                for (
                  int index = 0;
                  index < StudentCategory.values.length;
                  index++
                )
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: index == StudentCategory.values.length - 1
                          ? 0
                          : 10,
                    ),
                    child: _LearnerPathTile(
                      category: StudentCategory.values[index],
                      isActive: StudentCategory.values[index] == category,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            child: controller.isLoading.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(
                        title: 'Published lectures',
                        subtitle:
                            'Students watch these uploads and manually mark each lecture watched.',
                      ),
                      const SizedBox(height: 14),
                      if (visibleLectures.isEmpty)
                        Text(
                          allLectures.isEmpty
                              ? 'No lecture has been uploaded for ${course.code} yet.'
                              : 'Lectures exist for ${course.code}, but none are targeted at the ${category.shortLabel.toLowerCase()} path yet.',
                          style: _mutedStyle(context),
                        )
                      else
                        for (
                          int index = 0;
                          index < visibleLectures.length;
                          index++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleLectures.length - 1
                                  ? 0
                                  : 10,
                            ),
                            child: _LectureTile(
                              lecture: visibleLectures[index],
                              studentId: studentId,
                              currentCategory: category,
                              onWatch: () => Get.to(
                                () => VideoLecturePlayerView(
                                  lecture: visibleLectures[index],
                                  studentId: studentId,
                                ),
                              ),
                              onToggleWatched: () async {
                                final watched = visibleLectures[index]
                                    .isWatchedBy(studentId);
                                await controller.markLectureWatched(
                                  lectureId: visibleLectures[index].id,
                                  studentId: studentId,
                                  watched: !watched,
                                );
                              },
                            ),
                          ),
                    ],
                  ),
          ),
        ],
      );
    });
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

class _LectureTile extends StatelessWidget {
  const _LectureTile({
    required this.lecture,
    required this.studentId,
    required this.currentCategory,
    required this.onWatch,
    required this.onToggleWatched,
  });

  final VideoLectureModel lecture;
  final String studentId;
  final StudentCategory currentCategory;
  final VoidCallback onWatch;
  final VoidCallback onToggleWatched;

  @override
  Widget build(BuildContext context) {
    final watched = lecture.isWatchedBy(studentId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lecture.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              _Badge(text: watched ? 'Watched' : 'Pending'),
            ],
          ),
          const SizedBox(height: 6),
          Text(lecture.subtitle, style: _mutedStyle(context)),
          const SizedBox(height: 10),
          Text(lecture.description, style: _mutedStyle(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(text: '${lecture.durationMinutes} min'),
              _Badge(text: lecture.lecturerName),
              _Badge(
                text: lecture.allowDownloads ? 'Downloadable' : 'Stream only',
              ),
              for (final audience in lecture.audiences)
                _Badge(
                  text: audience.shortLabel,
                  active: audience == currentCategory,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onWatch,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(watched ? 'Watch again' : 'Watch now'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleWatched,
                  icon: Icon(
                    watched
                        ? Icons.remove_done_outlined
                        : Icons.check_circle_outline_rounded,
                  ),
                  label: Text(watched ? 'Mark unwatched' : 'Mark watched'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LearnerPathTile extends StatelessWidget {
  const _LearnerPathTile({required this.category, required this.isActive});

  final StudentCategory category;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
            : null,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (isActive) const _Badge(text: 'Current path', active: true),
            ],
          ),
          const SizedBox(height: 6),
          Text(category.lectureDeliverySummary, style: _mutedStyle(context)),
          const SizedBox(height: 8),
          Text(category.watchExpectation, style: _mutedStyle(context)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle, style: _mutedStyle(context)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: child,
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _mutedStyle(context))),
      ],
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
        color: active
            ? cs.primary.withValues(alpha: 0.12)
            : cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? cs.primary : cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

TextStyle _mutedStyle(BuildContext context) {
  return TextStyle(
    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}
