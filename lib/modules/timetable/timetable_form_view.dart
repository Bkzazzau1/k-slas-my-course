import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/timetable_models.dart';
import 'controller/timetable_controller.dart';

class TimetableFormView extends StatefulWidget {
  const TimetableFormView({super.key, required this.type, this.editing});

  final String type; // TimetableType.classes or TimetableType.exams
  final TimetableEventModel? editing; // only custom events editable

  @override
  State<TimetableFormView> createState() => _TimetableFormViewState();
}

class _TimetableFormViewState extends State<TimetableFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController courseCtrl;
  late final TextEditingController titleCtrl;
  late final TextEditingController locationCtrl;

  DateTime? start;
  DateTime? end;
  int? dayOfWeek; // for class events

  bool get isEdit => widget.editing != null;
  bool get isExams => widget.type == TimetableType.exams;

  @override
  void initState() {
    super.initState();

    final e = widget.editing;
    courseCtrl = TextEditingController(text: e?.courseCode ?? "");
    titleCtrl = TextEditingController(text: e?.title ?? "");
    locationCtrl = TextEditingController(text: e?.location ?? "");

    start = e?.start ?? DateTime.now().add(const Duration(hours: 1));
    end = e?.end ?? DateTime.now().add(const Duration(hours: 2));
    dayOfWeek = e?.dayOfWeek ?? DateTime.now().weekday;
  }

  @override
  void dispose() {
    courseCtrl.dispose();
    titleCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ctrl = Get.find<TimetableController>();

    // Lock editing for curated
    if (isEdit && (widget.editing?.isReadOnly ?? true)) {
      return Scaffold(
        appBar: AppBar(title: const Text("Timetable")),
        body: LuxuryScaffold(
          safeArea: true,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "This event is curated by your school and cannot be edited.",
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit event" : "Add event"),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final e = widget.editing!;
                await ctrl.deleteEvent(e);
                Get.back();
              },
            ),
        ],
      ),
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
          _glassCard(
            context,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExams ? "Exam event" : "Class event",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Students can add personal timetable entries. Curated school timetable is read-only.",
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  controller: courseCtrl,
                  label: "Course code (e.g. CSC 305)",
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? "Enter course code"
                      : null,
                ),
                const SizedBox(height: 10),
                _field(
                  controller: titleCtrl,
                  label: "Title (e.g. Lecture / Revision / Exam)",
                  validator: (v) =>
                      (v == null || v.trim().length < 3) ? "Enter title" : null,
                ),
                const SizedBox(height: 10),
                _field(
                  controller: locationCtrl,
                  label: "Location (e.g. LT2)",
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? "Enter location" : null,
                ),
                const SizedBox(height: 14),

                if (!isExams) ...[_dayPicker(cs), const SizedBox(height: 14)],

                _dateTimePicker(
                  cs: cs,
                  label: "Start time",
                  value: start!,
                  onPick: (dt) => setState(() => start = dt),
                ),
                const SizedBox(height: 10),
                _dateTimePicker(
                  cs: cs,
                  label: "End time",
                  value: end!,
                  onPick: (dt) => setState(() => end = dt),
                ),

                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      if (start == null || end == null) return;

                      if (end!.isBefore(start!)) {
                        Get.snackbar(
                          "Invalid time",
                          "End time must be after start time",
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      // Save (MVP: add; edit can be treated as delete+add for custom)
                      if (isEdit) {
                        await ctrl.deleteEvent(widget.editing!);
                      }

                      await ctrl.addCustomEvent(
                        type: widget.type,
                        courseCode: courseCtrl.text.trim(),
                        title: titleCtrl.text.trim(),
                        start: start!,
                        end: end!,
                        location: locationCtrl.text.trim(),
                        dayOfWeek: isExams ? null : dayOfWeek,
                      );

                      if (!mounted) return;
                      Get.back();
                    },
                    child: Text(isEdit ? "Save changes" : "Add event"),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _dayPicker(ColorScheme cs) {
    final days = const [
      (1, "Mon"),
      (2, "Tue"),
      (3, "Wed"),
      (4, "Thu"),
      (5, "Fri"),
      (6, "Sat"),
      (7, "Sun"),
    ];

    return _glassCard(
      context,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              "Day",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: days
                    .map(
                      (d) => ChoiceChip(
                        label: Text(d.$2),
                        selected: dayOfWeek == d.$1,
                        onSelected: (_) => setState(() => dayOfWeek = d.$1),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimePicker({
    required ColorScheme cs,
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onPick,
  }) {
    return _glassCard(
      context,
      child: InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (d == null) return;
          if (!mounted) return;

          final t = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
          );
          if (t == null) return;

          if (!mounted) return;
          onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                ),
                child: Icon(Icons.edit_calendar_outlined, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(value),
                      style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return "${d.day}/${d.month}/${d.year}  $hh:$mm";
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
