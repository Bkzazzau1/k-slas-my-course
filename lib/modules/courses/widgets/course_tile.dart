import 'package:flutter/material.dart';
import '../../../data/models/course_model.dart';

class CourseTile extends StatelessWidget {
  const CourseTile({super.key, required this.course, required this.onTap});

  final CourseModel course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 12),
              color: Colors.black.withValues(alpha: 0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            _CourseBadge(code: course.code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        text: course.notes ? "Notes" : "No notes",
                        tone: course.notes ? _Tone.neutral : _Tone.warn,
                      ),
                      _Pill(
                        text: course.pastQuestions ? "Past Qs" : "No past Qs",
                        tone: course.pastQuestions ? _Tone.neutral : _Tone.warn,
                      ),
                      _Pill(
                        text: "${course.progress}%",
                        tone: _Tone.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (course.progress / 100).clamp(0.0, 1.0),
                      minHeight: 10,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Progress - Tap to open",
                    style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}

class _CourseBadge extends StatelessWidget {
  const _CourseBadge({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        code.replaceAll(' ', '\n'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

enum _Tone { primary, neutral, warn }

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone});
  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      _Tone.primary => (cs.primary.withValues(alpha: 0.12), cs.primary),
      _Tone.neutral => (cs.onSurface.withValues(alpha: 0.06), cs.onSurface),
      _Tone.warn => (const Color(0xFFF59E0B).withValues(alpha: 0.14), const Color(0xFFF59E0B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.16)),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}
