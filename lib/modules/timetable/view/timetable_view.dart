import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/timetable_models.dart';
import '../controller/timetable_controller.dart';
import '../timetable_form_view.dart';

class TimetableView extends GetView<TimetableController> {
  const TimetableView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Timetable"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Obx(
            () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  _TabChip(
                    label: "Classes",
                    selected: controller.tabIndex.value == 0,
                    onTap: () => controller.tabIndex.value = 0,
                  ),
                  const SizedBox(width: 8),
                  _TabChip(
                    label: "Exams",
                    selected: controller.tabIndex.value == 1,
                    onTap: () => controller.tabIndex.value = 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(() {
          final isExams = controller.tabIndex.value == 1;
          final list = isExams ? controller.examEvents : controller.classEvents;

          if (list.isEmpty) {
            return Center(
              child: Text(
                isExams ? "No exam timetable yet." : "No class timetable yet.",
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _EventCard(event: list[i]),
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isExams = controller.tabIndex.value == 1;
          Get.to(
            () => TimetableFormView(
              type: isExams ? TimetableType.exams : TimetableType.classes,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.14)
              : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});
  final TimetableEventModel event;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.65);

    return _glassCard(
      context,
      child: InkWell(
        onTap: () {
          if (!event.isReadOnly) {
            Get.to(() => TimetableFormView(type: event.type, editing: event));
          } else {
            Get.snackbar(
              "Read-only",
              "This timetable was curated by your school.",
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                ),
                child: Icon(
                  event.isExam ? Icons.event_note_outlined : Icons.class_outlined,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${event.courseCode} - ${event.title}",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${_fmt(event.start)} - ${_fmt(event.end)}",
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Location: ${event.location}",
                      style: TextStyle(color: muted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Badge(
                          text: event.isExam ? "Exam" : "Class",
                          color: cs.secondary,
                        ),
                        const SizedBox(width: 6),
                        _Badge(
                          text: event.isReadOnly ? "Read-only" : "Custom",
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!event.isReadOnly)
                Icon(Icons.delete_outline, color: cs.error),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return "${d.day}/${d.month} $h:$m";
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

Widget _glassCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
