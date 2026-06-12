import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/services/student_profile_storage.dart';
import '../../../data/services/weekly_note_personal_storage.dart';
import '../../courses/view/weekly_note_reader_view.dart';

class RevisionView extends StatefulWidget {
  const RevisionView({super.key});

  @override
  State<RevisionView> createState() => _RevisionViewState();
}

class _RevisionViewState extends State<RevisionView> {
  late List<String> courseCodes;
  late List<_RevisionNoteItem> noteItems;

  @override
  void initState() {
    super.initState();
    _loadRevisionItems();
  }

  void _loadRevisionItems() {
    final profile = StudentProfileStorage.load();
    courseCodes = profile?.selectedCourses.isNotEmpty == true
        ? profile!.selectedCourses
        : const ['CSC 305'];
    noteItems = _collectWeeklyNoteItems(courseCodes);
  }

  List<_RevisionNoteItem> _collectWeeklyNoteItems(List<String> courses) {
    final items = <_RevisionNoteItem>[];
    for (final course in courses) {
      for (var week = 1; week <= 12; week++) {
        final record = WeeklyNotePersonalStorage.load(courseCode: course, week: week);
        final hasStudentWork = record.revisionMarked ||
            record.noteText.trim().isNotEmpty ||
            record.highlights.isNotEmpty;
        if (!hasStudentWork) continue;
        items.add(
          _RevisionNoteItem(
            courseCode: course,
            week: week,
            title: _weeklyTitle(course, week),
            record: record,
          ),
        );
      }
    }
    items.sort((a, b) {
      final courseCompare = a.courseCode.compareTo(b.courseCode);
      if (courseCompare != 0) return courseCompare;
      return a.week.compareTo(b.week);
    });
    return items;
  }

  String _weeklyTitle(String courseCode, int week) {
    final normalized = courseCode.trim().toUpperCase();
    final general = <String>[
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
    final csc = <String>[
      'Introduction to algorithms and data structures',
      'Arrays, linked lists and memory representation',
      'Stacks, queues and recursion notes',
      'Trees, binary search trees and traversal',
      'Graphs, BFS, DFS and shortest paths',
      'Sorting and searching revision guide',
      'Hashing, maps and collision handling',
      'Complexity analysis and Big-O practice',
      'CBT practice questions with explanations',
      'Past-question solution notes',
      'Final revision checklist',
      'Exam focus and common mistakes',
    ];
    final source = normalized.contains('CSC') ? csc : general;
    return source[(week - 1).clamp(0, source.length - 1)];
  }

  Future<void> _removeRevisionFocus(_RevisionNoteItem item) async {
    await WeeklyNotePersonalStorage.setRevisionMarked(
      courseCode: item.courseCode,
      week: item.week,
      marked: false,
    );
    setState(_loadRevisionItems);
    Get.snackbar('Updated', 'The note has been removed from revision focus.', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _openNote(_RevisionNoteItem item) async {
    await Get.to(
      () => WeeklyNoteReaderView(
        courseCode: item.courseCode,
        week: item.week,
        title: item.title,
        offlineReady: item.week <= 6,
        statusLabel: item.week < 6 ? 'Available' : item.week == 6 ? 'Current week' : 'Revision access',
      ),
    );
    if (mounted) setState(_loadRevisionItems);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final markedCount = noteItems.where((item) => item.record.revisionMarked).length;
    final highlightCount = noteItems.fold<int>(0, (sum, item) => sum + item.record.highlights.length);
    final noteCount = noteItems.where((item) => item.record.noteText.trim().isNotEmpty).length;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: RefreshIndicator(
          onRefresh: () async => setState(_loadRevisionItems),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              _RevisionHero(
                markedCount: markedCount,
                noteCount: noteCount,
                highlightCount: highlightCount,
                onBack: () => Get.back<void>(),
              ),
              const SizedBox(height: 12),
              _RecommendationCard(items: noteItems),
              const SizedBox(height: 12),
              _SectionHeader(
                title: 'Marked weekly notes',
                subtitle: noteItems.isEmpty
                    ? 'Notes you mark from course pages will appear here.'
                    : '${noteItems.length} weekly note${noteItems.length == 1 ? '' : 's'} with saved academic work.',
              ),
              const SizedBox(height: 10),
              if (noteItems.isEmpty)
                _EmptyRevisionState(courseCodes: courseCodes)
              else
                ...noteItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RevisionNoteCard(
                      item: item,
                      onOpen: () => _openNote(item),
                      onRemove: item.record.revisionMarked ? () => _removeRevisionFocus(item) : null,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              _StudyActionsCard(items: noteItems),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevisionHero extends StatelessWidget {
  const _RevisionHero({
    required this.markedCount,
    required this.noteCount,
    required this.highlightCount,
    required this.onBack,
  });

  final int markedCount;
  final int noteCount;
  final int highlightCount;
  final VoidCallback onBack;

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
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Revision Focus',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          const Icon(Icons.school_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 10),
        Text(
          'A professional study space for weekly notes, highlights, and personal academic revision.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.28),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: '$markedCount marked'),
          _HeroPill(label: '$noteCount personal notes'),
          _HeroPill(label: '$highlightCount highlights'),
        ]),
      ]),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.items});
  final List<_RevisionNoteItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = _steps();
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.secondary.withValues(alpha: 0.12), child: Icon(Icons.auto_awesome_outlined, color: cs.secondary)),
          const SizedBox(width: 10),
          Expanded(child: Text('Recommended study action', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 12),
        ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check_circle_outline_rounded, color: cs.secondary, size: 18),
                const SizedBox(width: 9),
                Expanded(child: Text(step, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.74), fontWeight: FontWeight.w700, height: 1.30))),
              ]),
            )),
      ]),
    );
  }

  List<String> _steps() {
    if (items.isEmpty) {
      return const [
        'Open a course and read the weekly study notes.',
        'Save personal notes and highlights for important lecturer points.',
        'Mark selected notes for revision so they appear here.',
      ];
    }
    final hasShortNotes = items.any((item) => item.record.noteText.trim().length < 80);
    final lowHighlights = items.any((item) => item.record.highlights.length < 3);
    if (hasShortNotes) {
      return const [
        'Expand short personal notes into clear summaries in your own words.',
        'Review the weekly note again after watching related videos.',
        'Use the final highlights as your quick pre-class revision list.',
      ];
    }
    if (lowHighlights) {
      return const [
        'Add more highlights for definitions, formulas, algorithms, or lecturer emphasis.',
        'Group similar highlights before weekly review.',
        'Attempt related practice tasks after reviewing the note.',
      ];
    }
    return const [
      'Spend 15 minutes reviewing the marked weekly notes.',
      'Attempt related practice tasks from the course page.',
      'Return tomorrow and refresh the revision focus list.',
    ];
  }
}

class _RevisionNoteCard extends StatelessWidget {
  const _RevisionNoteCard({required this.item, required this.onOpen, required this.onRemove});

  final _RevisionNoteItem item;
  final VoidCallback onOpen;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final noteText = item.record.noteText.trim();
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('W${item.week}', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${item.courseCode} • ${item.title}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 15)),
            const SizedBox(height: 5),
            Text(
              noteText.isEmpty ? 'No personal note yet. Open this weekly note and add your own summary.' : noteText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600, height: 1.30),
            ),
          ])),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _MiniBadge(text: item.record.revisionMarked ? 'Revision focus' : 'Saved note', active: item.record.revisionMarked),
          _MiniBadge(text: '${item.record.highlights.length} highlights'),
          if (item.record.noteText.trim().isNotEmpty) const _MiniBadge(text: 'Personal note'),
        ]),
        if (item.record.highlights.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.record.highlights.take(5).map((item) => Chip(label: Text(item))).toList(),
          ),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: onOpen, icon: const Icon(Icons.menu_book_outlined), label: const Text('Open note'))),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.bookmark_remove_outlined),
              label: const Text('Unmark'),
            ),
          ),
        ]),
      ]),
    );
  }
}

class _StudyActionsCard extends StatelessWidget {
  const _StudyActionsCard({required this.items});
  final List<_RevisionNoteItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Today\'s academic revision routine', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 12),
        _RoutineLine(number: 1, text: items.isEmpty ? 'Select one weekly note from My Courses.' : 'Review the first marked weekly note for 10 minutes.'),
        _RoutineLine(number: 2, text: 'Add or improve at least three highlights.'),
        _RoutineLine(number: 3, text: 'Write one paragraph summary in your own words.'),
        _RoutineLine(number: 4, text: 'Attempt related practice questions after revision.'),
      ]),
    );
  }
}

class _RoutineLine extends StatelessWidget {
  const _RoutineLine({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(radius: 14, backgroundColor: cs.primary.withValues(alpha: 0.12), child: Text('$number', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.74), fontWeight: FontWeight.w700, height: 1.30))),
      ]),
    );
  }
}

class _EmptyRevisionState extends StatelessWidget {
  const _EmptyRevisionState({required this.courseCodes});
  final List<String> courseCodes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GlassCard(
      child: Column(children: [
        Icon(Icons.auto_stories_outlined, size: 44, color: cs.primary),
        const SizedBox(height: 10),
        Text('No revision focus yet', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          'Open ${courseCodes.first} from My Courses, read weekly notes, add highlights, and mark important notes for revision.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600, height: 1.30),
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
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600)),
    ]);
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 8), color: cs.shadow.withValues(alpha: 0.035))],
          ),
          child: child,
        ),
      ),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, this.active = false});
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: active ? cs.primary.withValues(alpha: 0.11) : cs.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: active ? cs.primary : cs.onSurface, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _RevisionNoteItem {
  const _RevisionNoteItem({required this.courseCode, required this.week, required this.title, required this.record});
  final String courseCode;
  final int week;
  final String title;
  final WeeklyNotePersonalRecord record;
}
