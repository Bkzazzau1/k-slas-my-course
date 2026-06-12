import 'package:flutter/material.dart';

class LuxSearchField extends StatelessWidget {
  const LuxSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.icon = Icons.search_rounded,
    this.controller,
    this.onClear,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasText = controller?.text.isNotEmpty == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onSurface.withValues(alpha: 0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
              ),
            ),
          ),
          if (hasText && onClear != null)
            IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.55)),
              tooltip: "Clear search",
            ),
        ],
      ),
    );
  }
}
