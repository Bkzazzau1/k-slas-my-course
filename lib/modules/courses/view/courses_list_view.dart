import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../controller/courses_controller.dart';
import '../widgets/course_tile.dart';

class CoursesListView extends GetView<CoursesController> {
  const CoursesListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Obx(
          () => CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                sliver: SliverToBoxAdapter(
                  child: _CoursesHeader(
                    cs: cs,
                    providerLabel: controller.providerLabel,
                  ),
                ),
              ),
              if (controller.errorMessage.value != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  sliver: SliverToBoxAdapter(
                    child: _InfoBanner(
                      message: controller.errorMessage.value!,
                      onRetry: controller.loadCourses,
                    ),
                  ),
                ),
              if (controller.isLoading.value)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (controller.courses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(onReload: controller.loadCourses),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
                  sliver: SliverList.separated(
                    itemCount: controller.courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final course = controller.courses[i];
                      return CourseTile(
                        course: course,
                        onTap: () => Get.toNamed(
                          Routes.courseDetail,
                          arguments: {'course': course},
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoursesHeader extends StatelessWidget {
  const _CoursesHeader({required this.cs, required this.providerLabel});
  final ColorScheme cs;
  final String providerLabel;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your Courses",
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Study notes, live classes, past questions, AI chat and revision plan - per course.",
                style: TextStyle(
                  color: muted,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          ),
          child: Text(
            providerLabel,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFF59E0B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReload});

  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: cs.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 12),
            Text(
              'No courses available right now.',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The app will keep your demo path safe until backend data is ready.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onReload(),
              child: const Text('Reload'),
            ),
          ],
        ),
      ),
    );
  }
}
