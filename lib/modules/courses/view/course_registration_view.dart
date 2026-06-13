import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/course_registration_service.dart';
import '../../../data/services/course_registration_storage.dart';
import '../../../data/services/student_profile_storage.dart';

class CourseRegistrationView extends StatefulWidget {
  const CourseRegistrationView({super.key});

  @override
  State<CourseRegistrationView> createState() => _CourseRegistrationViewState();
}

class _CourseRegistrationViewState extends State<CourseRegistrationView> {
  late Set<String> _selectedElectives;
  late Set<String> _selectedCarryovers;

  @override
  void initState() {
    super.initState();
    _selectedElectives = CourseRegistrationStorage.loadSelectedElectives();
    _selectedCarryovers = CourseRegistrationStorage.loadSelectedCarryovers();
  }

  Future<void> _toggleElective(CourseModel course, bool selected) async {
    setState(() {
      if (selected) {
        _selectedElectives.add(course.code);
      } else {
        _selectedElectives.remove(course.code);
      }
    });
    await CourseRegistrationStorage.saveSelectedElectives(_selectedElectives);
  }

  Future<void> _toggleCarryover(CourseModel course, bool selected) async {
    setState(() {
      if (selected) {
        _selectedCarryovers.add(course.code);
      } else {
        _selectedCarryovers.remove(course.code);
      }
    });
    await CourseRegistrationStorage.saveSelectedCarryovers(_selectedCarryovers);
  }

  Future<void> _submit(CourseRegistrationDraft draft) async {
    if (!draft.validation.isValid) {
      Get.snackbar(
        'Registration blocked',
        draft.validation.messages.join('\n'),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await CourseRegistrationStorage.submitRegistration(
      draft.selectedCourses.map((course) => course.code).toList(),
    );
    await CourseRegistrationStorage.clearDraft();
    if (!mounted) return;
    setState(() {
      _selectedElectives = <String>{};
      _selectedCarryovers = <String>{};
    });
    Get.snackbar(
      draft.validation.approvalRequired ? 'Submitted for approval' : 'Registration submitted',
      draft.validation.approvalRequired
          ? 'Your registration includes carryover/repeat courses and needs academic office confirmation.'
          : 'Your course registration has been saved for approval.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = CourseRegistrationService.buildDraft(
      _selectedElectives,
      selectedCarryoverCodes: _selectedCarryovers,
    );
    final submittedAt = CourseRegistrationStorage.loadSubmittedAt();
    final submittedCourses = CourseRegistrationStorage.loadSubmittedCourses();

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            _RegistrationHero(ruleSet: draft.ruleSet),
            const SizedBox(height: 14),
            _RegistrationSummary(
              draft: draft,
              submittedAt: submittedAt,
              submittedCourses: submittedCourses,
            ),
            const SizedBox(height: 14),
            _SectionHeader(
              title: 'Compulsory core courses',
              subtitle: 'These are automatically included and cannot be removed.',
            ),
            const SizedBox(height: 10),
            ...draft.ruleSet.requiredCoreCourses.map(
              (course) => _RegistrationCourseCard(
                course: course,
                selected: true,
                locked: true,
              ),
            ),
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'Available electives',
              subtitle: 'Choose electives until your credit load is valid.',
            ),
            const SizedBox(height: 10),
            ...draft.ruleSet.availableElectives.map(
              (course) => _RegistrationCourseCard(
                course: course,
                selected: _selectedElectives.contains(course.code),
                locked: false,
                onChanged: (value) => _toggleElective(course, value),
              ),
            ),
            if (draft.ruleSet.availableCarryovers.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Carryover / repeat courses',
                subtitle: 'Select failed, missing, or repeat courses that must be confirmed by the academic office.',
              ),
              const SizedBox(height: 10),
              ...draft.ruleSet.availableCarryovers.map(
                (course) => _RegistrationCourseCard(
                  course: course,
                  selected: _selectedCarryovers.contains(course.code),
                  locked: false,
                  onChanged: (value) => _toggleCarryover(course, value),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _ValidationPanel(validation: draft.validation),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _submit(draft),
              icon: const Icon(Icons.send_rounded),
              label: Text(draft.validation.approvalRequired ? 'Submit for academic approval' : 'Submit course registration'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationHero extends StatelessWidget {
  const _RegistrationHero({required this.ruleSet});

  final CourseRegistrationRuleSet ruleSet;

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
              'Course Registration',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          const Icon(Icons.fact_check_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 10),
        Text(
          profile == null
              ? 'Register valid core, elective, carryover, and repeat courses.'
              : '${profile.departmentName} • ${profile.level} Level • Semester ${profile.semester}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: ruleSet.academicSession),
          _HeroPill(label: 'Min ${ruleSet.minCreditUnits} credits'),
          _HeroPill(label: 'Max ${ruleSet.maxCreditUnits} credits'),
          if (ruleSet.availableCarryovers.isNotEmpty)
            _HeroPill(label: '${ruleSet.availableCarryovers.length} carryover candidate(s)'),
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

class _RegistrationSummary extends StatelessWidget {
  const _RegistrationSummary({
    required this.draft,
    required this.submittedAt,
    required this.submittedCourses,
  });

  final CourseRegistrationDraft draft;
  final DateTime? submittedAt;
  final List<String> submittedCourses;

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.analytics_outlined, color: cs.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Registration summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _SummaryTile(label: 'Total credits', value: draft.validation.totalCredits.toString(), icon: Icons.calculate_outlined),
          _SummaryTile(label: 'Core credits', value: draft.validation.coreCredits.toString(), icon: Icons.lock_outline),
          _SummaryTile(label: 'Elective credits', value: draft.validation.electiveCredits.toString(), icon: Icons.tune_rounded),
          _SummaryTile(label: 'Carryover credits', value: draft.validation.carryoverCredits.toString(), icon: Icons.replay_circle_filled_outlined),
          _SummaryTile(label: 'Selected courses', value: draft.selectedCourses.length.toString(), icon: Icons.library_books_outlined),
        ]),
        if (draft.validation.approvalRequired) ...[
          const SizedBox(height: 12),
          Text(
            'Academic office confirmation is required because this registration includes carryover/repeat or special approval courses.',
            style: TextStyle(color: cs.error, fontWeight: FontWeight.w800),
          ),
        ],
        if (submittedAt != null) ...[
          const SizedBox(height: 12),
          Text(
            'Last submitted: ${submittedAt!.toLocal()} • ${submittedCourses.length} courses',
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800),
          ),
        ],
      ]),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
      const SizedBox(height: 3),
      Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _RegistrationCourseCard extends StatelessWidget {
  const _RegistrationCourseCard({
    required this.course,
    required this.selected,
    required this.locked,
    this.onChanged,
  });

  final CourseModel course;
  final bool selected;
  final bool locked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tone = course.isCarryover || course.isRepeat
        ? cs.error
        : course.isCore
            ? cs.primary
            : cs.tertiary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: selected ? tone.withValues(alpha: 0.06) : cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? tone.withValues(alpha: 0.20) : cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(
          value: selected,
          onChanged: locked ? null : (value) => onChanged?.call(value ?? false),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${course.code} • ${course.title}', style: const TextStyle(fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Wrap(spacing: 7, runSpacing: 7, children: [
              _CoursePill(text: '${course.creditUnits} credits', color: cs.secondary),
              _CoursePill(text: course.isCore ? 'Core' : 'Elective', color: tone),
              if (course.isCarryover) _CoursePill(text: 'Carryover', color: cs.error),
              if (course.isRepeat) _CoursePill(text: 'Repeat', color: cs.error),
              if (course.previousGrade != null) _CoursePill(text: 'Prev ${course.previousGrade}', color: cs.error),
              if (course.level != null) _CoursePill(text: '${course.level} Level', color: cs.primary),
              if (course.semester != null) _CoursePill(text: 'Semester ${course.semester}', color: cs.primary),
              if (locked) _CoursePill(text: 'Compulsory', color: cs.error),
              if (course.requiresApproval) _CoursePill(text: 'Approval required', color: cs.error),
            ]),
            if (course.repeatReason != null) ...[
              const SizedBox(height: 6),
              Text(
                course.repeatReason!,
                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _CoursePill extends StatelessWidget {
  const _CoursePill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel({required this.validation});

  final CourseRegistrationValidationResult validation;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = validation.isValid ? cs.primary : cs.error;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(validation.isValid ? Icons.verified_rounded : Icons.warning_amber_rounded, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            validation.isValid
                ? (validation.approvalRequired
                    ? 'Registration is valid, but carryover/repeat courses require academic office confirmation.'
                    : 'Registration is valid. You can submit for approval.')
                : validation.messages.join('\n'),
            style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, height: 1.35),
          ),
        ),
      ]),
    );
  }
}
