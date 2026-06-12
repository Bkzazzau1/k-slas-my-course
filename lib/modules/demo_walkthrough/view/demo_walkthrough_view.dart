import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';

class DemoWalkthroughView extends StatelessWidget {
  const DemoWalkthroughView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final steps = [
      _DemoStep(
        number: '01',
        title: 'Student assignments',
        subtitle:
            'Show pending work, group assignment, peer review, and grade feedback.',
        icon: Icons.school_outlined,
        actionLabel: 'Open student flow',
        onTap: () => Get.toNamed(
          Routes.assignments,
          arguments: {'actorRole': 'student'},
        ),
      ),
      _DemoStep(
        number: '02',
        title: 'Student results',
        subtitle: 'Show published scores, grades, and lecturer feedback.',
        icon: Icons.workspace_premium_outlined,
        actionLabel: 'Open results',
        onTap: () => Get.toNamed(Routes.results),
      ),
      _DemoStep(
        number: '03',
        title: 'Live sessions',
        subtitle:
            'Join live rooms, track attendance, and review class materials.',
        icon: Icons.video_camera_front_outlined,
        actionLabel: 'Open live classes',
        onTap: () => Get.toNamed(Routes.liveSessions),
      ),
      _DemoStep(
        number: '04',
        title: 'Proctored exam start',
        subtitle:
            'Show environment confirmation before audio monitoring is armed.',
        icon: Icons.verified_user_outlined,
        actionLabel: 'Open exam setup',
        onTap: () => Get.toNamed(Routes.examSetup),
      ),
    ];

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverToBoxAdapter(child: _Hero(cs: cs)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              sliver: SliverList.separated(
                itemCount: steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) =>
                    _StepCard(cs: cs, step: steps[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.78),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Demo Walkthrough',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'A guided client path through the strongest workflows.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoStep {
  const _DemoStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String number;
  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.cs, required this.step});

  final ColorScheme cs;
  final _DemoStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
            ),
            child: Icon(step.icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.number}  ${step.title}',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: step.onTap,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(step.actionLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
