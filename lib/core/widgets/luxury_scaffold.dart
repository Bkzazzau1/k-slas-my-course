import 'package:flutter/material.dart';

class LuxuryScaffold extends StatelessWidget {
  const LuxuryScaffold({
    super.key,
    required this.child,
    this.safeArea = true,
    this.padding,
    this.maxContentWidth = 1240,
  });

  final Widget child;
  final bool safeArea;
  final EdgeInsets? padding;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final body = Padding(padding: padding ?? EdgeInsets.zero, child: child);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _LearningBackgroundPainter(
                surface: Theme.of(context).scaffoldBackgroundColor,
                primary: cs.primary,
                secondary: cs.secondary,
                lineColor: cs.onSurface,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = safeArea ? SafeArea(child: body) : body;
                if (constraints.maxWidth <= maxContentWidth) return content;

                return Center(
                  child: SizedBox(
                    width: maxContentWidth,
                    height: constraints.maxHeight,
                    child: content,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningBackgroundPainter extends CustomPainter {
  const _LearningBackgroundPainter({
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.lineColor,
    required this.isDark,
  });

  final Color surface;
  final Color primary;
  final Color secondary;
  final Color lineColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = surface);

    final washRect = Rect.fromLTWH(0, 0, size.width, size.height * 0.58);
    final washPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: isDark ? 0.16 : 0.08),
          secondary.withValues(alpha: isDark ? 0.10 : 0.045),
          surface.withValues(alpha: 0),
        ],
        stops: const [0, 0.46, 1],
      ).createShader(washRect);
    canvas.drawRect(washRect, washPaint);

    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: isDark ? 0.045 : 0.035)
      ..strokeWidth = 1;
    const gap = 36.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final bandPaint = Paint()
      ..color = primary.withValues(alpha: isDark ? 0.08 : 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final band = Path()
      ..moveTo(-40, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.12,
        size.width + 40,
        size.height * 0.18,
      );
    canvas.drawPath(band, bandPaint);
  }

  @override
  bool shouldRepaint(covariant _LearningBackgroundPainter oldDelegate) {
    return surface != oldDelegate.surface ||
        primary != oldDelegate.primary ||
        secondary != oldDelegate.secondary ||
        lineColor != oldDelegate.lineColor ||
        isDark != oldDelegate.isDark;
  }
}
