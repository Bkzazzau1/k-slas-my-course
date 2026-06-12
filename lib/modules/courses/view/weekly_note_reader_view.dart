import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/services/weekly_note_personal_storage.dart';
import '../widgets/academic_revision_recommendation_panel.dart';

class WeeklyNoteReaderView extends StatefulWidget {
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
  State<WeeklyNoteReaderView> createState() => _WeeklyNoteReaderViewState();
}

class _WeeklyNoteReaderViewState extends State<WeeklyNoteReaderView> {
  late final TextEditingController _noteController;
  late final TextEditingController _highlightController;
  late WeeklyNotePersonalRecord personal;

  @override
  void initState() {
    super.initState();
    personal = WeeklyNotePersonalStorage.load(courseCode: widget.courseCode, week: widget.week);
    _noteController = TextEditingController(text: personal.noteText);
    _highlightController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  Future<void> _savePersonalNote() async {
    await WeeklyNotePersonalStorage.saveNote(
      courseCode: widget.courseCode,
      week: widget.week,
      noteText: _noteController.text,
    );
    await _reload();
    Get.snackbar('Saved', 'Your personal note has been saved.', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> _addHighlight() async {
    final text = _highlightController.text.trim();
    if (text.isEmpty) return;
    await WeeklyNotePersonalStorage.addHighlight(
      courseCode: widget.courseCode,
      week: widget.week,
      highlight: text,
    );
    _highlightController.clear();
    await _reload();
  }

  Future<void> _removeHighlight(String highlight) async {
    await WeeklyNotePersonalStorage.removeHighlight(
      courseCode: widget.courseCode,
      week: widget.week,
      highlight: highlight,
    );
    await _reload();
  }

  Future<void> _toggleRevisionFocus() async {
    await WeeklyNotePersonalStorage.setRevisionMarked(
      courseCode: widget.courseCode,
      week: widget.week,
      marked: !personal.revisionMarked,
    );
    await _reload();
    Get.snackbar(
      personal.revisionMarked ? 'Revision focus added' : 'Revision focus removed',
      personal.revisionMarked ? 'This note is now part of your academic revision list.' : 'This note has been removed from revision focus.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _reload() async {
    setState(() {
      personal = WeeklyNotePersonalStorage.load(courseCode: widget.courseCode, week: widget.week);
      _noteController.text = personal.noteText;
      _noteController.selection = TextSelection.collapsed(offset: _noteController.text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sectionsFor(widget.title);

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _ReaderHero(
                  courseCode: widget.courseCode,
                  week: widget.week,
                  title: widget.title,
                  statusLabel: widget.statusLabel,
                  offlineReady: widget.offlineReady,
                  highlightCount: personal.highlights.length,
                  hasPersonalNote: personal.noteText.trim().isNotEmpty,
                  revisionMarked: personal.revisionMarked,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _ActionStrip(
                  offlineReady: widget.offlineReady,
                  revisionMarked: personal.revisionMarked,
                  onRevision: _toggleRevisionFocus,
                  onSave: () => Get.snackbar(
                    'Offline saved',
                    'Week ${widget.week} note is ready for offline reading.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _PersonalNotePanel(
                  noteController: _noteController,
                  highlightController: _highlightController,
                  highlights: personal.highlights,
                  updatedAt: personal.updatedAt,
                  onSaveNote: _savePersonalNote,
                  onAddHighlight: _addHighlight,
                  onRemoveHighlight: _removeHighlight,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: AcademicRevisionRecommendationPanel(
                  title: widget.title,
                  noteText: personal.noteText,
                  highlights: personal.highlights,
                  revisionMarked: personal.revisionMarked,
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
    required this.highlightCount,
    required this.hasPersonalNote,
    required this.revisionMarked,
  });

  final String courseCode;
  final int week;
  final String title;
  final String statusLabel;
  final bool offlineReady;
  final int highlightCount;
  final bool hasPersonalNote;
  final bool revisionMarked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(blurRadius: 24, offset: const Offset(0, 14), color: cs.primary.withValues(alpha: 0.16)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: () => Get.back<void>(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          Expanded(
            child: Text('$courseCode • Week $week', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
          const Icon(Icons.menu_book_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 23, height: 1.12)),
        const SizedBox(height: 10),
        Text(
          'Weekly lecturer note with objectives, explanations, personal notes, highlights, and revision recommendation.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.30),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: statusLabel),
          _HeroPill(label: offlineReady ? 'Offline ready' : 'Online only'),
          _HeroPill(label: hasPersonalNote ? 'Personal note saved' : 'No personal note'),
          _HeroPill(label: '$highlightCount highlights'),
          _HeroPill(label: revisionMarked ? 'Revision focus' : 'Not marked'),
        ]),
      ]),
    );
  }
}

class _PersonalNotePanel extends StatelessWidget {
  const _PersonalNotePanel({
    required this.noteController,
    required this.highlightController,
    required this.highlights,
    required this.updatedAt,
    required this.onSaveNote,
    required this.onAddHighlight,
    required this.onRemoveHighlight,
  });

  final TextEditingController noteController;
  final TextEditingController highlightController;
  final List<String> highlights;
  final DateTime updatedAt;
  final VoidCallback onSaveNote;
  final VoidCallback onAddHighlight;
  final ValueChanged<String> onRemoveHighlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 8), color: cs.shadow.withValues(alpha: 0.04))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(Icons.edit_note_outlined, color: cs.primary)),
          const SizedBox(width: 10),
          Expanded(child: Text('My notes & highlights', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
          Text('Updated ${_shortDate(updatedAt)}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.54), fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          minLines: 3,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'Write your own explanation, questions, or reminder for this week...',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onSaveNote, icon: const Icon(Icons.save_outlined), label: const Text('Save personal note'))),
        const SizedBox(height: 14),
        TextField(
          controller: highlightController,
          decoration: InputDecoration(
            hintText: 'Add a highlight or key point...',
            suffixIcon: IconButton(onPressed: onAddHighlight, icon: const Icon(Icons.add_rounded)),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onSubmitted: (_) => onAddHighlight(),
        ),
        const SizedBox(height: 10),
        if (highlights.isEmpty)
          Text('No highlight yet. Add key definitions, formulas, or important lecturer points.', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65), fontWeight: FontWeight.w600))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: highlights
                .map((item) => InputChip(
                      label: Text(item),
                      onDeleted: () => onRemoveHighlight(item),
                    ))
                .toList(),
          ),
      ]),
    );
  }

  static String _shortDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
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

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.offlineReady, required this.revisionMarked, required this.onSave, required this.onRevision});
  final bool offlineReady;
  final bool revisionMarked;
  final VoidCallback onSave;
  final VoidCallback onRevision;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(child: FilledButton.icon(onPressed: offlineReady ? onSave : null, icon: const Icon(Icons.download_rounded), label: const Text('Save offline'))),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onRevision,
          icon: Icon(revisionMarked ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined),
          label: Text(revisionMarked ? 'Revision marked' : 'Mark revision'),
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
        boxShadow: [BoxShadow(blurRadius: 16, offset: const Offset(0, 8), color: cs.shadow.withValues(alpha: 0.04))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), child: Icon(section.icon, color: cs.primary)),
          const SizedBox(width: 10),
          Expanded(child: Text(section.heading, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 12),
        ...section.bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(bullet, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72), fontWeight: FontWeight.w600, height: 1.35))),
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
