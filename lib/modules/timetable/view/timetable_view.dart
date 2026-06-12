import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/timetable_models.dart';
import '../controller/timetable_controller.dart';
import '../timetable_form_view.dart';

class TimetableView extends GetView<TimetableController> {
  const TimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(() {
          final items = _buildCalendarItems(controller);
          final selected = controller.tabIndex.value;
          final filtered = selected == 0
              ? items
              : items.where((item) => item.filterIndex == selected).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _CalendarHero(
                    total: items.length,
                    exams: items.where((e) => e.filterIndex == 2).length,
                    deadlines: items.where((e) => e.filterIndex == 3).length,
                    live: items.where((e) => e.filterIndex == 4).length,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _FilterBar(selected: selected, onSelect: (value) => controller.tabIndex.value = value),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyCalendar(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _CalendarCard(item: filtered[index]),
                  ),
                ),
            ],
          );
        }),
      ),
      floatingActionButton: Obx(() {
        final selected = controller.tabIndex.value;
        final type = selected == 2 ? TimetableType.exams : TimetableType.classes;
        final showAdd = selected == 0 || selected == 1 || selected == 2;
        if (!showAdd) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: () => Get.to(() => TimetableFormView(type: type)),
          icon: const Icon(Icons.add_rounded),
          label: Text(selected == 2 ? 'Add exam' : 'Add class'),
        );
      }),
    );
  }

  List<_CalendarItem> _buildCalendarItems(TimetableController controller) {
    final now = DateTime.now();
    final items = <_CalendarItem>[];

    for (final event in controller.classEvents) {
      items.add(_CalendarItem.fromTimetable(event, filterIndex: 1));
    }
    for (final event in controller.examEvents) {
      items.add(_CalendarItem.fromTimetable(event, filterIndex: 2));
    }

    items.addAll([
      _CalendarItem(
        id: 'assignment-csc305',
        filterIndex: 3,
        title: 'Data structures assignment deadline',
        courseCode: 'CSC 305',
        category: 'Assignment',
        start: DateTime(now.year, now.month, now.day + 2, 23, 59),
        end: DateTime(now.year, now.month, now.day + 2, 23, 59),
        location: 'Online submission',
        actionLabel: 'Open assignment',
        route: Routes.assignments,
        icon: Icons.assignment_outlined,
        isReadOnly: true,
      ),
      _CalendarItem(
        id: 'graded-assessment-csc305',
        filterIndex: 3,
        title: 'Graded assessment window closes',
        courseCode: 'CSC 305',
        category: 'Assessment',
        start: DateTime(now.year, now.month, now.day + 4, 18, 0),
        end: DateTime(now.year, now.month, now.day + 4, 18, 0),
        location: 'K-SLAS assessment center',
        actionLabel: 'Open assessment',
        route: Routes.cbtSetup,
        icon: Icons.fact_check_outlined,
        isReadOnly: true,
      ),
      _CalendarItem(
        id: 'live-csc305',
        filterIndex: 4,
        title: 'Live revision class',
        courseCode: 'CSC 305',
        category: 'Live Class',
        start: DateTime(now.year, now.month, now.day + 1, 16, 0),
        end: DateTime(now.year, now.month, now.day + 1, 17, 30),
        location: 'Live classroom',
        actionLabel: 'Join live class',
        route: Routes.liveSessions,
        icon: Icons.live_tv_outlined,
        isReadOnly: true,
      ),
    ]);

    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }
}

class _CalendarHero extends StatelessWidget {
  const _CalendarHero({required this.total, required this.exams, required this.deadlines, required this.live});
  final int total;
  final int exams;
  final int deadlines;
  final int live;

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
          const Expanded(
            child: Text(
              'Academic Calendar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
            ),
          ),
          const Icon(Icons.calendar_month_rounded, color: Colors.white),
        ]),
        const SizedBox(height: 10),
        Text(
          'Classes, exams, deadlines, and live classes in one student calendar.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _HeroPill(label: '$total events'),
          _HeroPill(label: '$exams exams'),
          _HeroPill(label: '$deadlines deadlines'),
          _HeroPill(label: '$live live'),
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
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final filters = const [
      (0, 'All', Icons.dashboard_outlined),
      (1, 'Classes', Icons.class_outlined),
      (2, 'Exams', Icons.verified_user_outlined),
      (3, 'Deadlines', Icons.flag_outlined),
      (4, 'Live', Icons.live_tv_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map((filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChipButton(
                    label: filter.$2,
                    icon: filter.$3,
                    selected: selected == filter.$1,
                    onTap: () => onSelect(filter.$1),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.14) : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? cs.primary.withValues(alpha: 0.24) : cs.onSurface.withValues(alpha: 0.07)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.70)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? cs.primary : cs.onSurface, fontWeight: FontWeight.w900)),
        ]),
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.item});
  final _CalendarItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = item.statusText;
    final statusColor = item.statusColor;

    return _glassCard(
      context,
      child: InkWell(
        onTap: item.isEditable
            ? () => Get.to(() => TimetableFormView(type: item.sourceEvent!.type, editing: item.sourceEvent))
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
                ),
                child: Icon(item.icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.courseCode, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(item.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('${_dateTime(item.start)} - ${_time(item.end)}', style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item.location, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.62), fontWeight: FontWeight.w600)),
                ]),
              ),
              _StatusBadge(label: status, color: statusColor),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _MiniBadge(text: item.category, color: cs.secondary),
              _MiniBadge(text: item.isReadOnly ? 'School' : 'Custom', color: cs.primary),
              _MiniBadge(text: item.durationLabel, color: cs.tertiary),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAction(item),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(item.actionLabel),
                ),
              ),
              if (item.isEditable) ...[
                const SizedBox(width: 10),
                IconButton.outlined(
                  onPressed: () => item.sourceEvent == null ? null : _deleteEvent(item.sourceEvent!),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: cs.error,
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }

  void _openAction(_CalendarItem item) {
    if (item.route != null) {
      Get.toNamed(item.route!);
      return;
    }
    if (item.sourceEvent?.isExam == true) {
      Get.toNamed(Routes.examSetup);
      return;
    }
    Get.toNamed(Routes.courses);
  }

  void _deleteEvent(TimetableEventModel event) {
    final controller = Get.find<TimetableController>();
    controller.deleteEvent(event);
  }

  static String _dateTime(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  static String _time(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}

class _EmptyCalendar extends StatelessWidget {
  const _EmptyCalendar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_busy_outlined, size: 54, color: cs.primary),
          const SizedBox(height: 12),
          const Text('No event here yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Classes, exams, assignment deadlines, and live class reminders will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68), fontWeight: FontWeight.w600),
          ),
        ]),
      ),
    );
  }
}

class _CalendarItem {
  const _CalendarItem({
    required this.id,
    required this.filterIndex,
    required this.title,
    required this.courseCode,
    required this.category,
    required this.start,
    required this.end,
    required this.location,
    required this.actionLabel,
    required this.icon,
    required this.isReadOnly,
    this.route,
    this.sourceEvent,
  });

  factory _CalendarItem.fromTimetable(TimetableEventModel event, {required int filterIndex}) {
    return _CalendarItem(
      id: event.id,
      filterIndex: filterIndex,
      title: event.title,
      courseCode: event.courseCode,
      category: event.isExam ? 'Exam' : 'Class',
      start: event.start,
      end: event.end,
      location: event.location,
      actionLabel: event.isExam ? 'Open exam setup' : 'Open course',
      icon: event.isExam ? Icons.verified_user_outlined : Icons.class_outlined,
      isReadOnly: event.isReadOnly,
      route: event.isExam ? Routes.examSetup : Routes.courses,
      sourceEvent: event,
    );
  }

  final String id;
  final int filterIndex;
  final String title;
  final String courseCode;
  final String category;
  final DateTime start;
  final DateTime end;
  final String location;
  final String actionLabel;
  final IconData icon;
  final bool isReadOnly;
  final String? route;
  final TimetableEventModel? sourceEvent;

  bool get isEditable => sourceEvent != null && !isReadOnly;

  String get durationLabel {
    final minutes = end.difference(start).inMinutes;
    if (minutes <= 0) return 'Deadline';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '$hours hr' : '$hours hr $rem min';
  }

  String get statusText {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(start.year, start.month, start.day);
    if (end.isBefore(now)) return 'Past';
    if (startDay == today) return 'Today';
    if (startDay == today.add(const Duration(days: 1))) return 'Tomorrow';
    return 'Upcoming';
  }

  Color get statusColor {
    final status = statusText;
    if (status == 'Today') return Colors.red.shade700;
    if (status == 'Tomorrow') return Colors.orange.shade700;
    if (status == 'Past') return Colors.grey.shade600;
    return Colors.green.shade700;
  }
}

Widget _glassCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
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
