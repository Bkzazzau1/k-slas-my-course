import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/student_academic_record_service.dart';
import '../../../data/services/student_profile_storage.dart';

class StudentAcademicRecordView extends StatelessWidget {
  const StudentAcademicRecordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: FutureBuilder<StudentAcademicRecordSnapshot>(
          future: StudentAcademicRecordService.load(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
              children: [
                _AcademicHero(snapshot: data),
                const SizedBox(height: 14),
                _CgpaSummaryCard(summary: data.summary),
                const SizedBox(height: 14),
                _SectionHeader(
                  title: 'Currently enrolled courses',
                  subtitle: '${data.summary.currentCredits} registered credit units',
                ),
                const SizedBox(height: 10),
                if (data.enrolled.isEmpty)
                  const _EmptyAcademicState(message: 'No enrolled course found yet.')
                else
                  ...data.enrolled.map((course) => _AcademicCourseCard(course: course)),
                const SizedBox(height: 16),
                _SectionHeader(
                  title: 'Completed courses',
                  subtitle: '${data.summary.completedCredits} earned credit units',
                ),
                const SizedBox(height: 10),
                if (data.completed.isEmpty)
                  const _EmptyAcademicState(message: 'No completed course record found yet.')
                else
                  ...data.completed.map((course) => _AcademicCourseCard(course: course)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AcademicHero extends StatelessWidget {
  const _AcademicHero({required this.snapshot});

  final StudentAcademicRecordSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final profile = StudentProfileStorage.load();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Academic Record',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          const Icon(Icons.workspace_premium_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 10),
        Text(
          profile == null
              ? 'Courses, grades, credits and CGPA summary.'
              : '${profile.fullName} • ${profile.level} Level • Semester ${profile.semester}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w800, height: 1.25),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: snapshot.providerLabel),
          _HeroPill(label: '${snapshot.summary.enrolledCourses} enrolled'),
          _HeroPill(label: '${snapshot.summary.completedCourses} completed'),
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

class _CgpaSummaryCard extends StatelessWidget {
  const _CgpaSummaryCard({required this.summary});

  final AcademicProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.analytics_outlined, color: cs.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Academic progress summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryTile(label: 'CGPA', value: summary.cgpa.toStringAsFixed(2), icon: Icons.school_outlined),
              _SummaryTile(label: 'Current GPA', value: summary.currentGpa.toStringAsFixed(2), icon: Icons.trending_up_rounded),
              _SummaryTile(label: 'Credits earned', value: summary.completedCredits.toString(), icon: Icons.verified_rounded),
              _SummaryTile(label: 'Registered credits', value: summary.currentCredits.toString(), icon: Icons.menu_book_outlined),
              _SummaryTile(label: 'Core courses', value: summary.coreCourses.toString(), icon: Icons.lock_outline_rounded),
              _SummaryTile(label: 'Electives', value: summary.electiveCourses.toString(), icon: Icons.tune_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: cs.primary),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
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
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 3),
          Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        ]),
      ),
    ]);
  }
}

class _AcademicCourseCard extends StatelessWidget {
  const _AcademicCourseCard({required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = course.isCompleted ? cs.primary : cs.secondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(course.isCompleted ? Icons.verified_rounded : Icons.menu_book_rounded, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${course.code} • ${course.title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                '${course.creditUnits} credit unit${course.creditUnits == 1 ? '' : 's'} • ${course.academicSession ?? 'Current session'}',
                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          _CourseBadge(text: course.isCore ? 'Core' : 'Elective', color: course.isCore ? cs.primary : cs.tertiary),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _CourseBadge(text: course.status, color: tone),
          if (course.level != null) _CourseBadge(text: '${course.level} Level', color: cs.secondary),
          if (course.semester != null) _CourseBadge(text: 'Semester ${course.semester}', color: cs.secondary),
          if (course.grade != null) _CourseBadge(text: 'Grade ${course.grade}', color: cs.primary),
          if (course.gradePoint != null) _CourseBadge(text: '${course.gradePoint!.toStringAsFixed(1)} pts', color: cs.primary),
        ]),
        if (!course.isCompleted) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: course.progress.clamp(0, 100) / 100,
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.06),
            ),
          ),
        ],
      ]),
    );
  }
}

class _CourseBadge extends StatelessWidget {
  const _CourseBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _EmptyAcademicState extends StatelessWidget {
  const _EmptyAcademicState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Icon(Icons.school_outlined, color: cs.primary, size: 40),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}
