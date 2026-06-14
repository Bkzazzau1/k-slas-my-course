import 'package:flutter/material.dart';

import '../../../core/widgets/luxury_scaffold.dart';

class GraduationMappingView extends StatelessWidget {
  const GraduationMappingView({super.key});

  static const _summary = _GraduationSummary(
    programme: 'B.Sc Software Engineering',
    level: '300 Level',
    creditsRequired: 144,
    creditsEarned: 96,
    creditsInProgress: 18,
    creditsRemaining: 30,
    coursesCompleted: 42,
    coursesRemaining: 11,
    carryovers: 1,
    progressPercent: 67,
    expectedGraduation: '2027 Academic Session',
  );

  static const _levels = [
    _GraduationLevel('100 Level', 'Completed', 44, 44, 0, Icons.check_circle_outline),
    _GraduationLevel('200 Level', 'Completed', 46, 46, 0, Icons.check_circle_outline),
    _GraduationLevel('300 Level', 'In progress', 38, 18, 20, Icons.auto_graph_outlined),
    _GraduationLevel('400 Level', 'Remaining', 16, 0, 16, Icons.flag_outlined),
  ];

  static const _remaining = [
    _CourseRequirement('CSC 309', 'Artificial Intelligence', 'Carryover / pending result', 3, 'Action needed'),
    _CourseRequirement('SEN 401', 'Software Project Management', 'Required', 3, 'Upcoming'),
    _CourseRequirement('SEN 405', 'Final Year Project I', 'Required', 6, 'Upcoming'),
    _CourseRequirement('SEN 499', 'Final Year Project II', 'Required', 6, 'Upcoming'),
    _CourseRequirement('CSC 421', 'Cloud Computing', 'Elective', 3, 'Choose elective'),
    _CourseRequirement('GST 401', 'Entrepreneurship', 'Required', 2, 'Upcoming'),
  ];

  static const _achievements = [
    _Achievement('Strong foundation completed', 'You have completed all 100 and 200 level credit requirements.'),
    _Achievement('SIWES progress counted', 'Industrial training credits are already visible in your academic map.'),
    _Achievement('One issue to resolve', 'CSC 309 needs Records/Result follow-up before graduation clearance.'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverToBoxAdapter(child: _Header(summary: _summary, cs: cs)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(child: _ProgressCard(summary: _summary, cs: cs)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Graduation pathway', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverList.separated(
                itemCount: _levels.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _LevelTile(level: _levels[index], isLast: index == _levels.length - 1),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Remaining course map', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverList.separated(
                itemCount: _remaining.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _CourseRequirementTile(course: _remaining[index]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Motivation & alerts', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _achievements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _AchievementTile(item: _achievements[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.summary, required this.cs});
  final _GraduationSummary summary;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 14), color: cs.primary.withValues(alpha: 0.16))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Graduation Mapping', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'See what you have completed, what remains, and the exact academic path left before graduation.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.25),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeaderPill(label: summary.programme),
          _HeaderPill(label: summary.level),
          _HeaderPill(label: '${summary.progressPercent}% complete'),
          _HeaderPill(label: summary.expectedGraduation),
        ]),
      ]),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.summary, required this.cs});
  final _GraduationSummary summary;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final progress = summary.progressPercent / 100;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), foregroundColor: cs.primary, child: const Icon(Icons.school_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('You are ${summary.progressPercent}% on the way to graduation', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Text('${summary.coursesCompleted} courses done • ${summary.coursesRemaining} courses remaining', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        LinearProgressIndicator(value: progress, minHeight: 10, borderRadius: BorderRadius.circular(999)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _InfoPill(label: '${summary.creditsEarned}/${summary.creditsRequired} credits earned'),
          _InfoPill(label: '${summary.creditsInProgress} credits in progress'),
          _InfoPill(label: '${summary.creditsRemaining} credits remaining'),
          _InfoPill(label: '${summary.carryovers} carryover/pending'),
        ]),
      ]),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.level, required this.isLast});
  final _GraduationLevel level;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final done = level.remainingCredits == 0;
    final color = done ? cs.primary : level.status == 'In progress' ? cs.secondary : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outlineVariant)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), foregroundColor: color, child: Icon(level.icon)),
          if (!isLast) Container(width: 2, height: 36, color: color.withValues(alpha: 0.25)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(level.level, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${level.earnedCredits}/${level.requiredCredits} credits earned • ${level.remainingCredits} remaining', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: level.requiredCredits == 0 ? 0 : level.earnedCredits / level.requiredCredits,
              minHeight: 6,
              borderRadius: BorderRadius.circular(999),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        Chip(label: Text(level.status)),
      ]),
    );
  }
}

class _CourseRequirementTile extends StatelessWidget {
  const _CourseRequirementTile({required this.course});
  final _CourseRequirement course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final needsAction = course.status == 'Action needed';
    final color = needsAction ? cs.error : course.type == 'Elective' ? cs.secondary : cs.primary;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: needsAction ? cs.error.withValues(alpha: 0.35) : cs.outlineVariant)),
      tileColor: cs.surface,
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.10), foregroundColor: color, child: Icon(needsAction ? Icons.priority_high_outlined : Icons.menu_book_outlined)),
      title: Text('${course.code} • ${course.title}', style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text('${course.type} • ${course.credits} credit units'),
      trailing: Chip(label: Text(course.status)),
      onTap: () {},
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item});
  final _Achievement item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant)),
      tileColor: cs.surface,
      leading: CircleAvatar(backgroundColor: cs.secondary.withValues(alpha: 0.10), foregroundColor: cs.secondary, child: const Icon(Icons.emoji_events_outlined)),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(item.detail),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.primary.withValues(alpha: 0.12))),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800))),
    );
  }
}

class _GraduationSummary {
  const _GraduationSummary({
    required this.programme,
    required this.level,
    required this.creditsRequired,
    required this.creditsEarned,
    required this.creditsInProgress,
    required this.creditsRemaining,
    required this.coursesCompleted,
    required this.coursesRemaining,
    required this.carryovers,
    required this.progressPercent,
    required this.expectedGraduation,
  });
  final String programme;
  final String level;
  final int creditsRequired;
  final int creditsEarned;
  final int creditsInProgress;
  final int creditsRemaining;
  final int coursesCompleted;
  final int coursesRemaining;
  final int carryovers;
  final int progressPercent;
  final String expectedGraduation;
}

class _GraduationLevel {
  const _GraduationLevel(this.level, this.status, this.requiredCredits, this.earnedCredits, this.remainingCredits, this.icon);
  final String level;
  final String status;
  final int requiredCredits;
  final int earnedCredits;
  final int remainingCredits;
  final IconData icon;
}

class _CourseRequirement {
  const _CourseRequirement(this.code, this.title, this.type, this.credits, this.status);
  final String code;
  final String title;
  final String type;
  final int credits;
  final String status;
}

class _Achievement {
  const _Achievement(this.title, this.detail);
  final String title;
  final String detail;
}
