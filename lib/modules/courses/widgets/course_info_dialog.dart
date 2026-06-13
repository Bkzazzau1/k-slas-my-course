import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/course_model.dart';
import '../../../data/models/exam_models.dart';
import '../../../data/models/student_category.dart';
import '../../../data/services/course_material_service.dart';
import '../../../data/services/graded_session_template_service.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../video_lectures/controller/video_lectures_controller.dart';

class CourseInfoDialog extends StatelessWidget {
  const CourseInfoDialog({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = StudentProfileStorage.load();
    final category = studentCategoryFromStorage(profile?.studentCategoryKey);
    final examTemplate = GradedSessionTemplateService.templateFor(
      courseCode: course.code,
      sessionType: SessionType.examination,
    );
    final assessmentTemplate = GradedSessionTemplateService.templateFor(
      courseCode: course.code,
      sessionType: SessionType.assessment,
    );
    final lectureCount = _lectureCount(category);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Material(
            color: cs.surface,
            child: FutureBuilder<int>(
              future: _materialCount(),
              builder: (context, snapshot) {
                final materialCount = snapshot.data ?? 0;
                final loading = snapshot.connectionState == ConnectionState.waiting;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: cs.primary.withValues(alpha: 0.11),
                        child: Icon(Icons.info_outline_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(course.code, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(course.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 22, height: 1.14)),
                        const SizedBox(height: 6),
                        Text('Course information summary for quick student reference.', style: _muted(context)),
                      ])),
                      IconButton(onPressed: () => Get.back<void>(), icon: const Icon(Icons.close_rounded)),
                    ]),
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      _InfoMetric(icon: Icons.workspace_premium_outlined, label: 'Credit unit', value: '${_creditUnit()} units'),
                      _InfoMetric(icon: Icons.calendar_month_outlined, label: 'Semester', value: _semester()),
                      _InfoMetric(icon: Icons.folder_copy_outlined, label: 'Materials', value: loading ? 'Loading...' : '$materialCount items'),
                      _InfoMetric(icon: Icons.play_circle_outline_rounded, label: 'Video lessons', value: '$lectureCount lessons'),
                    ]),
                    const SizedBox(height: 14),
                    _InfoSection(
                      title: 'Academic ownership',
                      icon: Icons.person_outline_rounded,
                      children: [
                        _InfoLine(label: 'Lecturer', value: _lecturerName()),
                        _InfoLine(label: 'Student path', value: category.label),
                        _InfoLine(label: 'Attendance rule', value: category.attendanceRule),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoSection(
                      title: 'Assessment structure',
                      icon: Icons.fact_check_outlined,
                      children: [
                        _InfoLine(label: 'Graded assessment', value: _templateSummary(assessmentTemplate)),
                        _InfoLine(label: 'Examination', value: _templateSummary(examTemplate)),
                        _InfoLine(label: 'Question source', value: 'Lecturer-published for protected sessions; practice uses student-local demo bank.'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoSection(
                      title: 'Distance-learning rules',
                      icon: Icons.cast_for_education_outlined,
                      children: [
                        _InfoLine(label: 'Lecture delivery', value: category.lectureDeliverySummary),
                        _InfoLine(label: 'Watch expectation', value: category.watchExpectation),
                        _InfoLine(label: 'Offline mode', value: 'Weekly notes and supported lecture items can be saved for low-network study.'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Get.back<void>(),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Close course info'),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<int> _materialCount() async {
    final materials = await CourseMaterialService.gateway.fetchMaterials(courseCode: course.code);
    return materials.length;
  }

  int _lectureCount(StudentCategory category) {
    if (!Get.isRegistered<VideoLecturesController>()) return 0;
    final controller = Get.find<VideoLecturesController>();
    return controller.lecturesForCourse(course.code, category: category).length;
  }

  int _creditUnit() {
    final code = course.code.toUpperCase();
    if (code.startsWith('GST')) return 2;
    if (code.startsWith('MTH')) return 3;
    if (code.startsWith('CSC')) return 3;
    return 3;
  }

  String _semester() {
    final code = course.code.toUpperCase();
    final match = RegExp(r'(\d{3})').firstMatch(code);
    if (match == null) return 'Current semester';
    final number = int.tryParse(match.group(1) ?? '') ?? 0;
    if (number >= 500) return 'Final-year semester';
    if (number >= 300) return 'Upper-level semester';
    if (number >= 200) return 'Second-year semester';
    return 'First-year semester';
  }

  String _lecturerName() {
    final code = course.code.toUpperCase();
    if (code.startsWith('CSC')) return 'Department-appointed course lecturer';
    if (code.startsWith('MTH')) return 'Mathematics course lecturer';
    if (code.startsWith('GST')) return 'General Studies course lecturer';
    return 'Assigned course lecturer';
  }

  String _templateSummary(GradedSessionTemplate? template) {
    if (template == null) return 'Not published yet';
    final parts = <String>[
      if (template.hasObjective) '${template.objectiveQuestions} objective',
      if (template.hasFillBlank) '${template.fillBlankQuestions} fill blank',
      if (template.hasTheory) '${template.theoryQuestions} theory',
      '${template.durationMinutes} min',
      template.deliveryMode == ExamDeliveryMode.remoteProctored ? 'remote proctored' : 'center based',
    ];
    return parts.join(' • ');
  }
}

class _InfoMetric extends StatelessWidget {
  const _InfoMetric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: cs.primary),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.62), fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 128,
          child: Text(label, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.60), fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, height: 1.30))),
      ]),
    );
  }
}

TextStyle _muted(BuildContext context) {
  return TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600, height: 1.30);
}
