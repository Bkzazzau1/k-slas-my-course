import 'package:flutter/material.dart';

import '../../../core/whiteboard/whiteboard_models.dart';
import '../controller/live_class_workspace_controller.dart';

class LiveClassBoardCanvas extends StatelessWidget {
  const LiveClassBoardCanvas({
    super.key,
    required this.controller,
    required this.isInteractive,
  });

  final LiveClassBoardController controller;
  final bool isInteractive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: controller.currentTool == LiveClassBoardTool.pointer
              ? (event) =>
                    controller.updateLaserPointer(event.localPosition, size)
              : null,
          onExit: controller.currentTool == LiveClassBoardTool.pointer
              ? (_) => controller.updateLaserPointer(null, size)
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: !isInteractive
                ? null
                : (details) {
                    controller.beginStroke(details.localPosition, size);
                  },
            onPanUpdate: !isInteractive
                ? null
                : (details) {
                    if (controller.currentTool == LiveClassBoardTool.pointer) {
                      controller.translateCanvas(details.delta);
                      return;
                    }
                    controller.appendPoint(details.localPosition, size);
                  },
            onPanEnd: !isInteractive
                ? null
                : (_) {
                    controller.endStroke();
                  },
            onPanCancel: !isInteractive ? null : controller.endStroke,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _LiveClassBoardPainter(controller: controller),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LiveClassBoardPainter extends CustomPainter {
  const _LiveClassBoardPainter({required this.controller});

  final LiveClassBoardController controller;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(controller.canvasOffset.dx, controller.canvasOffset.dy);
    canvas.scale(controller.canvasZoom);

    for (final stroke in controller.currentPageStrokes) {
      _drawStroke(canvas, size, stroke);
    }
    for (final stroke in controller.remotePreviewStrokes) {
      _drawStroke(canvas, size, stroke);
    }

    final activeStroke = controller.activeStroke;
    if (activeStroke != null) {
      _drawStroke(canvas, size, activeStroke);
    }
    canvas.restore();

    final laserPointer = controller.laserPointer;
    if (laserPointer != null) {
      final glowPaint = Paint()
        ..color = const Color(0xFFFF7043).withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      final corePaint = Paint()..color = const Color(0xFFFF7043);
      canvas.drawCircle(laserPointer, 18, glowPaint);
      canvas.drawCircle(laserPointer, 5.5, corePaint);
    }
  }

  void _drawStroke(Canvas canvas, Size size, WhiteboardStroke stroke) {
    final points = stroke.points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Color(stroke.colorValue)
      ..strokeWidth = stroke.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    if (stroke.toolType == LiveClassBoardTool.highlighter.name) {
      paint.strokeWidth = stroke.strokeWidth;
      paint.blendMode = BlendMode.srcOver;
    }

    if (points.length == 1) {
      canvas.drawCircle(points.first, stroke.strokeWidth / 2, paint);
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 2) {
      path.lineTo(points.last.dx, points.last.dy);
      canvas.drawPath(path, paint);
      return;
    }

    for (var index = 1; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];
      final midPoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midPoint.dx, midPoint.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiveClassBoardPainter oldDelegate) {
    return true;
  }
}
