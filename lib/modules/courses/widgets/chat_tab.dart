import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../data/models/course_model.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key, required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Column(
      children: [
        // Premium policy banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.secondary.withValues(alpha: 0.16)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.verified_outlined, color: cs.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI answers must be based ONLY on your lecturer materials. Each answer shows citations. If not found: "Not in your materials".',
                  style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, height: 1.25),
                ),
              ),
            ],
          ),
        ),

        // Chat preview
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              _bubble(context, 'You', 'Explain AVL tree rotations.'),
              _bubble(
                context,
                'AI',
                'AVL rotations keep height balanced. See Lecture 5, p.12.',
                isAi: true,
                citation: "Lecture 5, p.12",
              ),
            ],
          ),
        ),

        // Sticky bottom actions
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(Routes.chat, arguments: {'course': course}),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Open Course AI"),
                ),
              ),
              const SizedBox(height: 10),

              // input preview bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Ask about ${course.code}...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: muted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      tooltip: "Send",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Open source'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Report answer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(
    BuildContext context,
    String sender,
    String message, {
    bool isAi = false,
    String? citation,
  }) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    final bg = isAi ? cs.onSurface.withValues(alpha: 0.03) : cs.primary.withValues(alpha: 0.12);
    final border = isAi ? cs.onSurface.withValues(alpha: 0.06) : cs.primary.withValues(alpha: 0.16);

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sender, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
            const SizedBox(height: 6),
            Text(message, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600, height: 1.25)),
            if (isAi && citation != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      citation,
                      style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
