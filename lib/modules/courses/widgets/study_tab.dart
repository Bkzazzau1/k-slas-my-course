import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/models/course_model.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_material_model.dart';
import '../../../data/models/student_category.dart';
import '../../../data/models/student_profile_model.dart';
import '../../../data/models/video_lecture_models.dart';
import '../../../data/services/course_material_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../view/weekly_note_reader_view.dart';
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
    final weeklyNotes = _weeklyNotesFor(course.code);

    return Obx(() {
      final allLectures = controller.lecturesForCourse(course.code);
      final lectures = controller.lecturesForCourse(
        course.code,
        category: category,
      );

      if (allLectures.isEmpty && !controller.isLoading.value) {
        controller.loadLectures(courseCode: course.code);
      }

      return FutureBuilder<List<CourseMaterialModel>>(
        future: CourseMaterialService.gateway.fetchMaterials(courseCode: course.code),
        builder: (context, snapshot) {
          final materials = snapshot.data ?? const <CourseMaterialModel>[];
          final loadingMaterials = snapshot.connectionState == ConnectionState.waiting;
          final watched = lectures.where((lecture) => lecture.isWatchedBy(studentId)).length;
          final downloadable = materials.where((material) => material.allowDownload).length;
          final totalItems = materials.length + lectures.length + weeklyNotes.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              _StudyOverviewCard(
                course: course,
                materialCount: materials.length,
                lectureCount: lectures.length,
                watchedCount: watched,
                downloadableCount: downloadable + weeklyNotes.length,
                weeklyNoteCount: weeklyNotes.length,
              ),
              const SizedBox(height: 12),
              _StudyActionRow(course: course),
              const SizedBox(height: 16),
              if (controller.isLoading.value || loadingMaterials)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (totalItems == 0)
                _EmptyStudyState(courseCode: course.code)
              else ...[
                _SectionHeader(
                  title: 'Weekly study notes',
                  subtitle: '${weeklyNotes.length} weeks • structured notes for the semester',
                ),
                const SizedBox(height: 10),
                for (final note in weeklyNotes) _WeeklyNoteCard(note: note, courseCode: course.code),
                const SizedBox(height: 10),
                _SectionHeader(
                  title: 'Course materials',
                  subtitle: '${materials.length} item${materials.length == 1 ? '' : 's'} • $downloadable offline-ready',
                ),
                const SizedBox(height: 10),
                if (materials.isEmpty)
                  _MiniEmpty(message: 'No additional document or link material has been published yet.')
                else
                  for (final material in materials) _MaterialStudyTile(material: material),
                const SizedBox(height: 10),
                _SectionHeader(
                  title: 'Lecture videos',
                  subtitle: '${lectures.length} lecture${lectures.length == 1 ? '' : 's'} • $watched completed',
                ),
                const SizedBox(height: 10),
                if (lectures.isEmpty)
                  _MiniEmpty(message: 'No video lecture is available for your student category yet.')
                else
                  for (final lecture in lectures)
                    _LectureStudyTile(
                      lecture: lecture,
                      watched: lecture.isWatchedBy(studentId),
                    ),
              ],
            ],
          );
        },
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

  List<_WeeklyNote> _weeklyNotesFor(String courseCode) {
    final normalized = courseCode.trim().toUpperCase();
    final topics = <String>[
      'Course introduction and learning outcomes',
      'Core concepts and key definitions',
      'Worked examples and lecturer explanations',
      'Applied problem-solving session',
      'Case study and class discussion notes',
      'Mid-semester revision guide',
      'Advanced concepts and common mistakes',
      'Practice questions with explanations',
      'Assessment preparation notes',
      'Past-question review and solutions',
      'Final revision checklist',
      'Exam focus and summary notes',
    ];

    if (normalized.contains('CSC')) {
      topics[0] = 'Introduction to algorithms and data structures';
      topics[1] = 'Arrays, linked lists and memory representation';
      topics[2] = 'Stacks, queues and recursion notes';
      topics[3] = 'Trees, binary search trees and traversal';
      topics[4] = 'Graphs, BFS, DFS and shortest paths';
      topics[5] = 'Sorting and searching revision guide';
      topics[6] = 'Hashing, maps and collision handling';
      topics[7] = 'Complexity analysis and Big-O practice';
      topics[8] = 'CBT practice questions with explanations';
      topics[9] = 'Past-question solution notes';
      topics[10] = 'Final revision checklist';
      topics[11] = 'Exam focus and common mistakes';
    }

    return List.generate(
      topics.length,
      (index) => _WeeklyNote(
        week: index + 1,
        title: topics[index],
        status: index < 5 ? _WeekStatus.available : index == 5 ? _WeekStatus.current : _WeekStatus.locked,
        offlineReady: index < 6,
      ),
    );
  }
}

class _StudyOverviewCard extends StatelessWidget {
  const _StudyOverviewCard({
    required this.course,
    required this.materialCount,
    required this.lectureCount,
    required this.watchedCount,
    required this.downloadableCount,
    required this.weeklyNoteCount,
  });

  final CourseModel course;
  final int materialCount;
  final int lectureCount;
  final int watchedCount;
  final int downloadableCount;
  final int weeklyNoteCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progress = (course.progress / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.15),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: const Icon(Icons.menu_book_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(course.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
              const SizedBox(height: 3),
              Text('Study workspace', style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700)),
            ]),
          ),
          Text('${course.progress}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.20),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: '$weeklyNoteCount weekly notes'),
          _HeroPill(label: '$materialCount materials'),
          _HeroPill(label: '$lectureCount videos'),
          _HeroPill(label: '$watchedCount watched'),
          _HeroPill(label: '$downloadableCount offline-ready'),
        ]),
      ]),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _WeeklyNoteCard extends StatelessWidget {
  const _WeeklyNoteCard({required this.note, required this.courseCode});
  final _WeeklyNote note;
  final String courseCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (note.status) {
      _WeekStatus.available => Colors.green.shade700,
      _WeekStatus.current => Colors.orange.shade700,
      _WeekStatus.locked => cs.onSurface.withValues(alpha: 0.48),
    };
    final statusText = switch (note.status) {
      _WeekStatus.available => 'Available',
      _WeekStatus.current => 'Current week',
      _WeekStatus.locked => 'Locked',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: cs.shadow.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('W${note.week}', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(note.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 5),
              Text(
                'Weekly lecturer note with key points, examples, and revision focus.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600, height: 1.30),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Badge(text: statusText, color: color),
          _Badge(text: note.offlineReady ? 'Offline ready' : 'Online only', color: note.offlineReady ? Colors.green.shade700 : cs.primary),
          _Badge(text: 'Study note', color: cs.secondary),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: note.status == _WeekStatus.locked
                  ? null
                  : () => Get.to(
                        () => WeeklyNoteReaderView(
                          courseCode: courseCode,
                          week: note.week,
                          title: note.title,
                          offlineReady: note.offlineReady,
                          statusLabel: statusText,
                        ),
                      ),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('Open note'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: note.offlineReady
                  ? () => Get.snackbar('Offline saved', 'Week ${note.week} note is ready offline.', snackPosition: SnackPosition.BOTTOM)
                  : null,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Save offline'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StudyActionRow extends StatelessWidget {
  const _StudyActionRow({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.fact_check_outlined,
          label: 'Assessment',
          onTap: () => Get.toNamed(Routes.cbtSetup, arguments: {'courseCode': course.code}),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ActionButton(
          icon: Icons.live_tv_outlined,
          label: 'Live class',
          onTap: () => Get.toNamed(Routes.liveSessions),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ActionButton(
          icon: Icons.receipt_long_outlined,
          label: 'Receipts',
          onTap: () => Get.toNamed(Routes.results),
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
        ),
        child: Column(children: [
          Icon(icon, color: cs.primary),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _MaterialStudyTile extends StatelessWidget {
  const _MaterialStudyTile({required this.material});

  final CourseMaterialModel material;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);
    final type = material.materialType.toLowerCase();
    final isLink = type == 'link';
    final isPdf = type.contains('pdf') || type.contains('document');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: cs.shadow.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(isLink ? Icons.link_rounded : isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(material.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 5),
              Text(material.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, height: 1.30)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _Badge(text: material.materialType.toUpperCase(), color: cs.secondary),
          _Badge(text: material.allowDownload ? 'Download allowed' : 'View only', color: cs.primary),
          if (material.allowDownload) _Badge(text: 'Offline access', color: Colors.green.shade700),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Get.snackbar('Material', 'Opening ${material.title}', snackPosition: SnackPosition.BOTTOM),
              icon: Icon(isLink ? Icons.open_in_new_rounded : Icons.visibility_outlined),
              label: const Text('Open'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: material.allowDownload
                  ? () => Get.snackbar('Offline saved', '${material.title} is ready for offline reading.', snackPosition: SnackPosition.BOTTOM)
                  : null,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Save offline'),
            ),
          ),
        ]),
      ]),
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
    final color = watched ? Colors.green.shade700 : cs.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: cs.shadow.withValues(alpha: 0.035),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(watched ? Icons.check_circle_outline_rounded : Icons.play_circle_outline_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(lecture.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 5),
              Text(watched ? 'Completed • ${lecture.durationMinutes} min' : 'Pending • ${lecture.durationMinutes} min', style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 7),
              Text(lecture.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted, fontWeight: FontWeight.w600, height: 1.30)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            backgroundColor: cs.onSurface.withValues(alpha: 0.06),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Get.toNamed(Routes.liveSessions),
              icon: Icon(watched ? Icons.replay_rounded : Icons.play_arrow_rounded),
              label: Text(watched ? 'Replay' : 'Watch'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Get.snackbar('Offline video', 'Lecture download will sync when backend storage is connected.', snackPosition: SnackPosition.BOTTOM),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Offline'),
            ),
          ),
        ]),
      ]),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Icon(Icons.menu_book_outlined, size: 42, color: cs.primary),
        const SizedBox(height: 12),
        Text('No study material yet', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 7),
        Text(
          'No lecturer-published study material is available for $courseCode yet. Check again later or open live classes and assessments.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600, height: 1.30),
        ),
      ]),
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Text(message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700)),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _WeeklyNote {
  const _WeeklyNote({
    required this.week,
    required this.title,
    required this.status,
    required this.offlineReady,
  });

  final int week;
  final String title;
  final _WeekStatus status;
  final bool offlineReady;
}

enum _WeekStatus { available, current, locked }
