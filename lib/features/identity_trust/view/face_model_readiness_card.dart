import 'package:flutter/material.dart';

import '../services/face_model_readiness_service.dart';

class FaceModelReadinessCard extends StatelessWidget {
  const FaceModelReadinessCard({
    super.key,
    required this.loading,
    required this.result,
  });

  final bool loading;
  final FaceModelReadinessResult? result;

  @override
  Widget build(BuildContext context) {
    final ready = result?.ready ?? false;
    final color = loading
        ? Theme.of(context).colorScheme.primary
        : ready
            ? Colors.green
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(_icon(ready), color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                loading
                    ? 'Checking local face model readiness...'
                    : result?.message ?? 'Face model readiness unknown.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(bool ready) {
    if (loading) return Icons.sync_rounded;
    if (ready) return Icons.verified_rounded;
    return Icons.warning_rounded;
  }
}
