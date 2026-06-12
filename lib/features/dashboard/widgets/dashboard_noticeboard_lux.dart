import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class DashboardNoticeboardLux extends StatelessWidget {
  const DashboardNoticeboardLux({super.key, required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NoticeItem(course: "CSC 305", title: "Assignment on Graphs due Friday.", by: "Class Rep", isNew: true),
      _NoticeItem(course: "MTH 202", title: "Exam covers Chapters 1-5 only.", by: "Dr. Bala", isNew: false),
      _NoticeItem(course: "GST 201", title: "Past questions uploaded.", by: "Portal", isNew: true),
    ];

    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...items.map((it) => _NoticeRow(cs: cs, it: it)),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: _LinkButton(
            cs: cs,
            label: "View all",
            icon: Icons.open_in_new,
            onTap: () => Get.toNamed(Routes.noticeboard),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Tip: check noticeboard daily for exam updates.",
          style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}

class _NoticeItem {
  const _NoticeItem({
    required this.course,
    required this.title,
    required this.by,
    required this.isNew,
  });

  final String course;
  final String title;
  final String by;
  final bool isNew;
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.cs, required this.it});
  final ColorScheme cs;
  final _NoticeItem it;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left: "new" dot
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: it.isNew ? cs.secondary : cs.onSurface.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CourseChip(cs: cs, course: it.course),
                    const SizedBox(width: 8),
                    if (it.isNew) _NewChip(cs: cs),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  it.title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        it.by,
                        style: TextStyle(color: muted, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded, color: cs.primary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseChip extends StatelessWidget {
  const _CourseChip({required this.cs, required this.course});
  final ColorScheme cs;
  final String course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
      ),
      child: Text(
        course,
        style: TextStyle(
          color: cs.primary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _NewChip extends StatelessWidget {
  const _NewChip({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.secondary.withValues(alpha: 0.18)),
      ),
      child: Text(
        "NEW",
        style: TextStyle(
          color: cs.secondary,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.cs,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final ColorScheme cs;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: cs.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
