import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../controller/weak_areas_controller.dart';

class WeakAreasView extends StatefulWidget {
  const WeakAreasView({super.key});

  @override
  State<WeakAreasView> createState() => _WeakAreasViewState();
}

class _WeakAreasViewState extends State<WeakAreasView> {
  _WeakFilter _filter = _WeakFilter.all;
  _WeakSort _sort = _WeakSort.lowestScore;
  String? _course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = Get.find<WeakAreasController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Weak Areas')),
      body: LuxuryScaffold(
        safeArea: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final s = controller.summary.value;
          if (s == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _glassCard(
                  context,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.insights_outlined,
                        size: 40,
                        color: cs.primary,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No weak areas yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Take a short CBT or theory practice to generate insights.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final items = _applyFilters(s.weakestFirst);
          final courses =
              s.weakestFirst.map((t) => t.courseCode).toSet().toList()..sort();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            children: [
              _hero(
                context,
                title: 'Your Weak Areas',
                subtitle:
                    'Computed from CBT and theory attempts. The lower the score, the weaker the topic.',
              ),
              const SizedBox(height: 12),

              _glassCard(
                context,
                child: Text(
                  'These weak areas are computed from your attempts. The more mistakes you make in a topic, the lower its score.',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.8)),
                ),
              ),
              const SizedBox(height: 12),

              _filterBar(context, courses),
              const SizedBox(height: 12),

              if (items.isEmpty)
                _glassCard(
                  context,
                  child: Text(
                    'No topics match your filters.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),

              ...items.map(
                (t) => _glassCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.topic,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          _ScorePill(cs: cs, score: t.score0to100),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: (t.score0to100 / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Evidence: ${t.evidenceCount}',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...t.reasons.map((r) => _ReasonRow(text: r)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Get.toNamed(
                                '/cbt/setup',
                                arguments: {
                                  'courseCode': t.courseCode,
                                  'topic': t.topic,
                                },
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Practice CBT'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.toNamed('/exam/setup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: cs.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(
                                  color: cs.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              child: const Text('Take Exam'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _filterBar(BuildContext context, List<String> courses) {
    final cs = Theme.of(context).colorScheme;
    return _glassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter and sort',
            style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == _WeakFilter.all,
                onTap: () => setState(() => _filter = _WeakFilter.all),
              ),
              _FilterChip(
                label: 'Severe',
                selected: _filter == _WeakFilter.severe,
                onTap: () => setState(() => _filter = _WeakFilter.severe),
              ),
              _FilterChip(
                label: 'Moderate',
                selected: _filter == _WeakFilter.moderate,
                onTap: () => setState(() => _filter = _WeakFilter.moderate),
              ),
              _FilterChip(
                label: 'Mild',
                selected: _filter == _WeakFilter.mild,
                onTap: () => setState(() => _filter = _WeakFilter.mild),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DropdownPill<String?>(
                  label: 'Course',
                  value: _course,
                  items: [null, ...courses],
                  itemLabel: (v) => v ?? 'All courses',
                  onChanged: (v) => setState(() => _course = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownPill<_WeakSort>(
                  label: 'Sort',
                  value: _sort,
                  items: const [
                    _WeakSort.lowestScore,
                    _WeakSort.highestScore,
                    _WeakSort.mostEvidence,
                    _WeakSort.leastEvidence,
                  ],
                  itemLabel: _sortLabel,
                  onChanged: (v) =>
                      setState(() => _sort = v ?? _WeakSort.lowestScore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<dynamic> _applyFilters(List<dynamic> input) {
    var items = input;
    if (_course != null) {
      items = items.where((t) => t.courseCode == _course).toList();
    }
    items = items.where((t) {
      switch (_filter) {
        case _WeakFilter.severe:
          return t.score0to100 < 40;
        case _WeakFilter.moderate:
          return t.score0to100 >= 40 && t.score0to100 < 70;
        case _WeakFilter.mild:
          return t.score0to100 >= 70;
        case _WeakFilter.all:
          return true;
      }
    }).toList();

    items.sort((a, b) {
      switch (_sort) {
        case _WeakSort.highestScore:
          return b.score0to100.compareTo(a.score0to100);
        case _WeakSort.mostEvidence:
          return b.evidenceCount.compareTo(a.evidenceCount);
        case _WeakSort.leastEvidence:
          return a.evidenceCount.compareTo(b.evidenceCount);
        case _WeakSort.lowestScore:
          return a.score0to100.compareTo(b.score0to100);
      }
    });

    return items;
  }

  String _sortLabel(_WeakSort? s) {
    switch (s ?? _WeakSort.lowestScore) {
      case _WeakSort.highestScore:
        return 'Highest score';
      case _WeakSort.mostEvidence:
        return 'Most evidence';
      case _WeakSort.leastEvidence:
        return 'Least evidence';
      case _WeakSort.lowestScore:
        return 'Lowest score';
    }
  }

  Widget _hero(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: cs.onSurface.withValues(alpha: 0.04),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.cs, required this.score});
  final ColorScheme cs;
  final int score;

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(cs, score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$score/100',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }

  Color _scoreColor(ColorScheme cs, int score) {
    if (score < 40) return cs.error;
    if (score < 70) return const Color(0xFFF59E0B);
    return cs.primary;
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

enum _WeakFilter { all, severe, moderate, mild }

enum _WeakSort { lowestScore, highestScore, mostEvidence, leastEvidence }

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected
        ? cs.primary.withValues(alpha: 0.12)
        : cs.onSurface.withValues(alpha: 0.04);
    final fg = selected ? cs.primary : cs.onSurface;
    final br = selected
        ? cs.primary.withValues(alpha: 0.18)
        : cs.onSurface.withValues(alpha: 0.08);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: br),
        ),
        child: Text(
          label,
          style: TextStyle(color: fg, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DropdownPill<T> extends StatelessWidget {
  const _DropdownPill({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T?> items;
  final String Function(T?) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items
                    .map(
                      (v) => DropdownMenuItem<T>(
                        value: v,
                        child: Text(itemLabel(v)),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
