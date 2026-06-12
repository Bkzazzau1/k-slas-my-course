import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';

class PastQuestionsTab extends StatelessWidget {
  const PastQuestionsTab({super.key, required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        _Header(cs: cs, title: "Past questions", subtitle: "Train like the exam. Smart sets are generated from your materials."),
        const SizedBox(height: 12),

        _ActionTile(
          icon: Icons.account_tree_outlined,
          title: "Practice by topic",
          subtitle: "Focus on Trees, Sorting, Graphs",
          onTap: () => Get.toNamed(Routes.cbtSetup, arguments: {"courseCode": course.code}),
        ),
        _ActionTile(
          icon: Icons.shuffle_rounded,
          title: "Mixed set",
          subtitle: "Random 20 questions (exam-style)",
          onTap: () => Get.toNamed(Routes.cbtSetup, arguments: {"courseCode": course.code}),
        ),

        const SizedBox(height: 16),
        Text("Mode", style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
        const SizedBox(height: 10),
        const _ModeRow(),

        const SizedBox(height: 16),
        Text("Last attempts", style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.history_rounded, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CBT practice - Trees", style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text("Score: 68% - Timed (12 mins)", style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cs, required this.title, required this.subtitle});
  final ColorScheme cs;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.onSurface)),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: cs.primary),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
        subtitle: Text(subtitle, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
        trailing: Icon(Icons.play_circle_outline, color: cs.primary),
      ),
    );
  }
}

class _ModeRow extends StatefulWidget {
  const _ModeRow();

  @override
  State<_ModeRow> createState() => _ModeRowState();
}

class _ModeRowState extends State<_ModeRow> {
  String mode = 'Timed';

  @override
  Widget build(BuildContext context) {
    final modes = ['Timed', 'Untimed', 'CBT style'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modes
          .map(
            (m) => ChoiceChip(
              label: Text(m),
              selected: mode == m,
              onSelected: (_) => setState(() => mode = m),
            ),
          )
          .toList(),
    );
  }
}
