import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_courses/data/models/theory_rewrite_models.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/course_model.dart';
import '../../../data/models/theory_models.dart';

class RevisionTab extends StatelessWidget {
  const RevisionTab({super.key, required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    final items = [
      (
        'Flashcards',
        'Auto-generated from lecturer notes',
        Icons.style_outlined,
      ),
      ('Quick summary', 'Key points for exam', Icons.auto_awesome_outlined),
      (
        'Common mistakes',
        'Pitfalls from past attempts',
        Icons.warning_amber_outlined,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      children: [
        Text(
          "Revision tools",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "All revision content must cite lecturer materials only.",
          style: TextStyle(color: muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        ...items.map(
          (i) => _Tile(icon: i.$3, title: i.$1, subtitle: i.$2, onTap: () {}),
        ),

        const SizedBox(height: 6),
        _Tile(
          icon: Icons.edit_note_outlined,
          title: "Theory practice",
          subtitle: "Write and get marking + keywords from lecturer notes",
          onTap: () {
            Get.toNamed(
              Routes.theoryPractice,
              arguments: TheoryQuestionModel(
                id: "t1",
                courseCode: course.code,
                topic: "Trees",
                question:
                    "Explain Binary Search Tree and state its properties.",
                marks: 10,
                sourceRef: "Lecture 3, Page 7",
                expectedKeywords: [
                  "Binary Search Tree",
                  "left subtree",
                  "right subtree",
                  "less than root",
                  "greater than root",
                ],
              ),
            );
          },
        ),

        _Tile(
          icon: Icons.assessment_outlined,
          title: AppStrings.assessment,
          subtitle:
              "Launch graded/ungraded assessment (CBT, fill, essay, or mixed)",
          onTap: () => Get.toNamed(
            Routes.cbtSetup,
            arguments: {"courseCode": course.code},
          ),
        ),

        _Tile(
          icon: Icons.school_outlined,
          title: AppStrings.examination,
          subtitle:
              "Launch graded/ungraded examination with mixed question types",
          onTap: () => Get.toNamed(Routes.examSetup),
        ),

        _Tile(
          icon: Icons.refresh_outlined,
          title: "Theory rewrite",
          subtitle: "Rewrite answers using lecturer keywords (improves scores)",
          onTap: () => Get.toNamed(
            Routes.theoryRewrite,
            arguments: TheoryRewritePrompt(
              courseCode: course.code,
              topic: "Keywords rewrite",
              question:
                  "Rewrite the answer using all required keywords and keep it concise.",
              sourceRef: "Lecturer notes",
              requiredKeywords: const ["definition", "properties", "example"],
              originalAnswer: null,
              originalScore: null,
              originalTotal: 10,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
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
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: muted, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
