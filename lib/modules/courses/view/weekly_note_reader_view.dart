import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';

class WeeklyNoteReaderView extends StatelessWidget {
  const WeeklyNoteReaderView({
    super.key,
    required this.courseCode,
    required this.week,
    required this.title,
    required this.offlineReady,
    required this.statusLabel,
  });

  final String courseCode;
  final int week;
  final String title;
  final bool offlineReady;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sections = _sectionsFor(title);

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _ReaderHero(
                  courseCode: courseCode,
                  week: week,
                  title: title,
                  statusLabel: statusLabel,
                  offlineReady: offlineReady,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _ActionStrip(
                  offlineReady: offlineReady,
                  onSave: () => Get.snackbar(
                    'Offline saved',
                    'Week $week note is ready for offline reading.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _NoteSection(section: sections[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ReaderSection> _sectionsFor(String title) {
    return [
      _ReaderSection(
        icon: Icons.flag_outlined,
        heading: 'Learning objectives',
        bullets: [
          'Understand the main ideas in $title.',
          'Connect this week\'s topic with previous course materials.',
          'Identify the concepts likely to appear in assessment or CBT questions.',
        ],
      ),
      const _ReaderSection(
        icon: Icons.lightbulb_outline_rounded,
        heading: 'Key points',
        bullets: [
          'Read the lecturer note first before watching related videos.',
          'Write down definitions, formulas, algorithms, or rules that repeat often.',
          'Focus on examples because they show how the theory is applied.',
        ],
      ),
      const _ReaderSection(
        icon: Icons.task_alt_outlined,
        heading: 'Practice tasks',
        bullets: [
          'Attempt five short questions from this topic.',
          'Mark any confusing area for revision.',
          'Use the AI chat only for clarification within your course materials.',
        ],
      ),
      const _ReaderSection(
        icon: Icons.quiz_outlined,
        heading: 'Assessment focus',
        bullets: [
          'Know the definitions and common mistakes.',
          'Practice objective questions before graded assessment.',
          'Review this note again before your exam or weekly quiz.',
        ],
      ),
    ];
  }
}

class _ReaderHero extends StatelessWidget {
  const _ReaderHero({
    required this.courseCode,
    required this.week,
    required this.title,
    required this.statusLabel,
    required this.offlineReady,
  });

  final String courseCode;
  final int week;
  final String title;
  final String statusLabel;
  final bool offlineReady;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          Expanded(
            child: Text(
              '$courseCode • Week $week',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          const Icon(Icons.menu_book_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23, height: 1.12),
        ),
        const SizedBox(height: 10),
        Text(
          'Weekly lecturer note with objectives, explanations, practice tasks, and assessment focus.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.30),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: statusLabel),
          _HeroPill(label: offlineReady ? 'Offline ready' : 'Online only'),
          const _HeroPill(label: 'Study note'),
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

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.offlineReady, required this.onSave});
  final bool offlineReady;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(
        child: FilledButton.icon(
          onPressed: offlineReady ? onSave : null,
          icon: const Icon(Icons.download_rounded),
          label: const Text('Save offline'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => Get.snackbar(
            'Revision marked',
            'This note has been added to your revision focus.',
            snackPosition: SnackPosition.BOTTOM,
          ),
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Mark revision'),
          style: OutlinedButton.styleFrom(foregroundColor: cs.primary),
        ),
      ),
    ]);
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({required this.section});
  final _ReaderSection section;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: cs.shadow.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: cs.primary.withValues(alpha: 0.10),
            child: Icon(section.icon, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              section.heading,
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ...section.bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bullet,
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w600, height: 1.35),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _ReaderSection {
  const _ReaderSection({required this.icon, required this.heading, required this.bullets});
  final IconData icon;
  final String heading;
  final List<String> bullets;
}
