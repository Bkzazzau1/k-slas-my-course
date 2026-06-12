import 'package:flutter/material.dart';

class AcademicRevisionRecommendationPanel extends StatelessWidget {
  const AcademicRevisionRecommendationPanel({
    super.key,
    required this.title,
    required this.noteText,
    required this.highlights,
    required this.revisionMarked,
  });

  final String title;
  final String noteText;
  final List<String> highlights;
  final bool revisionMarked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = _steps();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: cs.secondary.withValues(alpha: 0.12),
            child: Icon(Icons.auto_awesome_outlined, color: cs.secondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Revision recommendation',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: cs.secondary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              revisionMarked ? 'Marked' : 'Suggested',
              style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Recommended next academic review action for "$title".',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600, height: 1.30),
        ),
        const SizedBox(height: 12),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle_outline_rounded, color: cs.secondary, size: 18),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    step,
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.74), fontWeight: FontWeight.w700, height: 1.30),
                  ),
                ),
              ]),
            )),
      ]),
    );
  }

  List<String> _steps() {
    final cleanNote = noteText.trim();
    if (cleanNote.isEmpty && highlights.isEmpty) {
      return const [
        'Read the weekly note once without interruption.',
        'Add at least three highlights: definition, example, and lecturer focus.',
        'Write a short personal summary before leaving this page.',
      ];
    }
    if (cleanNote.length < 80) {
      return const [
        'Expand your personal note into a short paragraph using your own words.',
        'Add one example from the lecturer note or video lecture.',
        'Review the saved highlights before attempting course practice.',
      ];
    }
    if (highlights.length < 3) {
      return const [
        'Add more highlights for definitions, rules, or formulas that must be remembered.',
        'Use your personal note as the main revision summary for this week.',
        'Attempt practice tasks after reviewing highlighted points.',
      ];
    }
    return const [
      'Use the highlights for a 15-minute focused revision session.',
      'Attempt related practice tasks and compare with the weekly note.',
      'Revisit this note before the next quiz, assessment, or class activity.',
    ];
  }
}
