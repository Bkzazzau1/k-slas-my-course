import 'package:flutter/material.dart';

class PremiumSkeleton extends StatefulWidget {
  const PremiumSkeleton({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.radius = 14,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<PremiumSkeleton> createState() => _PremiumSkeletonState();
}

class _PremiumSkeletonState extends State<PremiumSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.onSurface.withValues(alpha: 0.06);
    final hi = cs.onSurface.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + (2 * t), 0),
              end: Alignment(1 + (2 * t), 0),
              colors: [base, hi, base],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

class PremiumSkeletonBlock extends StatelessWidget {
  const PremiumSkeletonBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        PremiumSkeleton(height: 14, width: 180),
        SizedBox(height: 10),
        PremiumSkeleton(height: 52),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: PremiumSkeleton(height: 12)),
            SizedBox(width: 10),
            Expanded(child: PremiumSkeleton(height: 12)),
          ],
        ),
      ],
    );
  }
}
