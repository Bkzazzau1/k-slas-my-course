import 'package:flutter/material.dart';

class LuxSelectTile extends StatelessWidget {
  const LuxSelectTile({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.leadingIcon,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final IconData? leadingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.70);

    final accent = selected ? cs.primary : cs.onSurface.withValues(alpha: 0.80);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cs.primary.withValues(alpha: 0.22) : cs.onSurface.withValues(alpha: 0.06),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: Colors.black.withValues(alpha: 0.04),
            ),
          ],
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: accent.withValues(alpha: 0.10),
                  border: Border.all(color: accent.withValues(alpha: 0.16)),
                ),
                child: Icon(leadingIcon, color: accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (selected)
              Icon(Icons.check_circle, color: cs.primary)
            else
              Icon(Icons.circle_outlined, color: cs.onSurface.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }
}
