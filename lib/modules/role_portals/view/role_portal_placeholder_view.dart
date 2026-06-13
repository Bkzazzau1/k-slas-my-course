import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';

class RolePortalPlaceholderView extends StatelessWidget {
  const RolePortalPlaceholderView({
    super.key,
    required this.roleName,
    required this.portalTitle,
    required this.description,
    required this.features,
    this.primaryActionLabel,
    this.primaryActionRoute,
  });

  final String roleName;
  final String portalTitle;
  final String description;
  final List<String> features;
  final String? primaryActionLabel;
  final String? primaryActionRoute;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            _RolePortalHero(
              roleName: roleName,
              portalTitle: portalTitle,
              description: description,
              onBack: () => Get.back<void>(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Portal responsibilities',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...features.map((feature) => _FeatureLine(text: feature)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.primary.withValues(alpha: 0.14)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This route is separated from student screens. Backend permissions will decide who can enter this portal.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        height: 1.32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (primaryActionLabel != null && primaryActionRoute != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Get.toNamed(primaryActionRoute!),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(primaryActionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RolePortalHero extends StatelessWidget {
  const _RolePortalHero({
    required this.roleName,
    required this.portalTitle,
    required this.description,
    required this.onBack,
  });

  final String roleName;
  final String portalTitle;
  final String description;
  final VoidCallback onBack;

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
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  portalTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            roleName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              height: 1.30,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline_rounded, color: cs.primary, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                height: 1.30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
