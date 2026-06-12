import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/models/course_model.dart';

import '../../../data/models/course_material_model.dart';
import '../../../data/models/student_category.dart';
import '../../../data/models/student_profile_model.dart';
import '../../../data/models/video_lecture_models.dart';
import '../../../data/services/course_material_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../video_lectures/controller/video_lectures_controller.dart';

class StudyTab extends StatelessWidget {
  const StudyTab({super.key, required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<VideoLecturesController>()
        ? Get.find<VideoLecturesController>()
        : Get.put(VideoLecturesController());
    final profile = StudentProfileStorage.load();
    final category = studentCategoryFromStorage(profile?.studentCategoryKey);
    final studentId = _studentId(profile);

    return Obx(() {
      final allLectures = controller.lecturesForCourse(course.code);
      final lectures = controller.lecturesForCourse(
        course.code,
        category: category,
      );

      if (allLectures.isEmpty && !controller.isLoading.value) {
        controller.loadLectures(courseCode: course.code);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        children: [
          _SectionHeader(
            title: 'Study plan',
            subtitle:
                'Follow lecturer-published materials and lectures for ${course.code}.',
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<CourseMaterialModel>>(
            future: CourseMaterialService.gateway.fetchMaterials(
              courseCode: course.code,
            ),
            builder: (context, snapshot) {
              final materials = snapshot.data ?? const <CourseMaterialModel>[];
              final loadingMaterials =
                  snapshot.connectionState == ConnectionState.waiting;

              if (controller.isLoading.value || loadingMaterials) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (lectures.isEmpty && materials.isEmpty) {
                return _EmptyStudyState(courseCode: course.code);
              }

              return Column(
                children: [
                  for (final material in materials)
                    _MaterialStudyTile(material: material),
                  for (final lecture in lectures)
                    _LectureStudyTile(
                      lecture: lecture,
                      watched: lecture.isWatchedBy(studentId),
                    ),
                ],
              );
            },
          ),
        ],
      );
    });
  }

  String _studentId(StudentProfileModel? profile) {
    final matric = profile?.matricNo?.trim() ?? '';
    if (matric.isNotEmpty) return matric;
    final email = profile?.email?.trim() ?? '';
    if (email.isNotEmpty) return email.toLowerCase();
    return 'student-demo';
  }
}

class _MaterialStudyTile extends StatelessWidget {
  const _MaterialStudyTile({required this.material});

  final CourseMaterialModel material;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);
    final isLink = material.materialType.toLowerCase() == 'link';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            isLink ? Icons.link_rounded : Icons.description_outlined,
            color: cs.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  material.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            material.allowDownload
                ? Icons.download_done_outlined
                : Icons.visibility_outlined,
            color: cs.onSurface.withValues(alpha: 0.42),
          ),
        ],
      ),
    );
  }
}

class _LectureStudyTile extends StatelessWidget {
  const _LectureStudyTile({required this.lecture, required this.watched});

  final VideoLectureModel lecture;
  final bool watched;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);
    final progress = watched ? 1.0 : 0.0;
    final tone = watched ? _Tone2.good : _Tone2.neutral;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _StatusDot(tone: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lecture.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  watched
                      ? 'Completed • ${lecture.durationMinutes} min'
                      : 'Pending • ${lecture.durationMinutes} min',
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  lecture.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            watched ? Icons.check_circle_rounded : Icons.play_circle_outline,
            color: watched
                ? cs.secondary
                : cs.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

class _EmptyStudyState extends StatelessWidget {
  const _EmptyStudyState({required this.courseCode});

  final String courseCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Text(
        'No lecturer-published study lecture is available for $courseCode yet.',
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.70),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: muted, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

enum _Tone2 { good, neutral }

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.tone});
  final _Tone2 tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (tone) {
      _Tone2.good => cs.secondary,
      _Tone2.neutral => cs.onSurface.withValues(alpha: 0.35),
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
