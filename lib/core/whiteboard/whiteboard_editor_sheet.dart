import 'package:flutter/material.dart';

import 'whiteboard_models.dart';

class WhiteboardEditorSheet extends StatefulWidget {
  const WhiteboardEditorSheet({
    super.key,
    required this.title,
    required this.prompt,
    required this.initialStrokes,
  });

  final String title;
  final String? prompt;
  final List<WhiteboardStroke> initialStrokes;

  @override
  State<WhiteboardEditorSheet> createState() => _WhiteboardEditorSheetState();
}

class _WhiteboardEditorSheetState extends State<WhiteboardEditorSheet> {
  late final List<WhiteboardStroke> _strokes;
  List<WhiteboardPoint> _activePoints = <WhiteboardPoint>[];
  double _strokeWidth = 3.0;
  int _selectedColorValue = 0xFF0B1020;

  static const List<int> _palette = <int>[
    0xFF000000, // Black
    0xFFD32F2F, // Red
    0xFF1565C0, // Blue
    0xFF2E7D32, // Green
    0xFFF57C00, // Orange
  ];

  @override
  void initState() {
    super.initState();
    _strokes = List<WhiteboardStroke>.from(widget.initialStrokes);
    if (_strokes.isNotEmpty) {
      _selectedColorValue = _strokes.last.colorValue;
    }
  }

  int get _strokeCount {
    return _strokes.where((s) => s.isUsable).length;
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.clear();
      _activePoints = <WhiteboardPoint>[];
    });
  }

  void _saveAndClose() {
    final usable = _strokes.where((s) => s.isUsable).toList();
    Navigator.of(context).pop<List<WhiteboardStroke>>(usable);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
            if (widget.prompt != null && widget.prompt!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.prompt!.trim(),
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Strokes: $_strokeCount',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  child: Slider(
                    value: _strokeWidth,
                    min: 1.5,
                    max: 7,
                    divisions: 11,
                    label: _strokeWidth.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        _strokeWidth = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            Text(
              'Ink colors',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: _palette
                      .map(
                        (colorValue) => GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColorValue = colorValue;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Color(colorValue),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedColorValue == colorValue
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.22),
                                width: _selectedColorValue == colorValue
                                    ? 2.2
                                    : 1.1,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: cs.onSurface.withValues(alpha: 0.16),
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanStart: (details) {
                          final local = details.localPosition;
                          setState(() {
                            _activePoints = <WhiteboardPoint>[
                              WhiteboardPoint(dx: local.dx, dy: local.dy),
                            ];
                          });
                        },
                        onPanUpdate: (details) {
                          final local = details.localPosition;
                          if (local.dx < 0 ||
                              local.dy < 0 ||
                              local.dx > constraints.maxWidth ||
                              local.dy > constraints.maxHeight) {
                            return;
                          }
                          setState(() {
                            _activePoints = <WhiteboardPoint>[
                              ..._activePoints,
                              WhiteboardPoint(dx: local.dx, dy: local.dy),
                            ];
                          });
                        },
                        onPanEnd: (_) {
                          if (_activePoints.length < 2) {
                            setState(() {
                              _activePoints = <WhiteboardPoint>[];
                            });
                            return;
                          }
                          setState(() {
                            _strokes.add(
                              WhiteboardStroke(
                                points: _activePoints,
                                colorValue: _selectedColorValue,
                                strokeWidth: _strokeWidth,
                              ),
                            );
                            _activePoints = <WhiteboardPoint>[];
                          });
                        },
                        child: CustomPaint(
                          painter: _WhiteboardPainter(
                            strokes: _strokes,
                            activePoints: _activePoints,
                            activeColorValue: _selectedColorValue,
                            activeStrokeWidth: _strokeWidth,
                          ),
                          size: Size.infinite,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _undo,
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('Undo'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear_rounded),
                  label: const Text('Clear'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saveAndClose,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Use drawing'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  _WhiteboardPainter({
    required this.strokes,
    required this.activePoints,
    required this.activeColorValue,
    required this.activeStrokeWidth,
  });

  final List<WhiteboardStroke> strokes;
  final List<WhiteboardPoint> activePoints;
  final int activeColorValue;
  final double activeStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(
        canvas: canvas,
        points: stroke.points,
        colorValue: stroke.colorValue,
        strokeWidth: stroke.strokeWidth,
      );
    }

    if (activePoints.length > 1) {
      _drawStroke(
        canvas: canvas,
        points: activePoints,
        colorValue: activeColorValue,
        strokeWidth: activeStrokeWidth,
      );
    }
  }

  void _drawStroke({
    required Canvas canvas,
    required List<WhiteboardPoint> points,
    required int colorValue,
    required double strokeWidth,
  }) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Color(colorValue)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      canvas.drawLine(Offset(a.dx, a.dy), Offset(b.dx, b.dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.activePoints != activePoints ||
        oldDelegate.activeStrokeWidth != activeStrokeWidth ||
        oldDelegate.activeColorValue != activeColorValue;
  }
}
