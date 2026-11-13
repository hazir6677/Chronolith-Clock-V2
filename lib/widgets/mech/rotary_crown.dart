import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/mech_audio.dart';
import '../../theme/brass.dart';

/// Knurled winding crown. Drag sideways across it: right = clockwise
/// (increase), left = counter-clockwise (decrease). Every [stepPx] of travel
/// is one ratchet tick with sound and haptics.
class RotaryCrown extends StatefulWidget {
  const RotaryCrown({
    super.key,
    required this.onStep,
    this.width = 120,
    this.height = 64,
    this.stepPx = 14,
    this.semanticLabel = 'Winding crown. Swipe right to increase, left to decrease',
  });

  /// [steps] is signed (+ = clockwise). [speed] is travel in px/s, so callers
  /// can accelerate large changes.
  final void Function(int steps, double speed) onStep;
  final double width, height, stepPx;
  final String semanticLabel;

  @override
  State<RotaryCrown> createState() => _RotaryCrownState();
}

class _RotaryCrownState extends State<RotaryCrown> {
  double _offset = 0; // ridge scroll, px
  double _carry = 0;
  double _speed = 0;
  int _lastMs = 0;

  void _update(DragUpdateDetails d) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = math.max(1, now - _lastMs) / 1000.0;
    _lastMs = now;
    _speed = _speed * 0.6 + (d.delta.dx.abs() / dt) * 0.4;
    setState(() => _offset += d.delta.dx);
    _carry += d.delta.dx;
    final steps = (_carry / widget.stepPx).truncate();
    if (steps != 0) {
      _carry -= steps * widget.stepPx;
      MechAudio.play(Sfx.crownTick, volume: 0.8, minGapMs: 18);
      MechAudio.haptic(Haptic.tick);
      widget.onStep(steps, _speed);
    }
  }

  void _adjust(int dir) {
    // Accessibility: discrete increment/decrement.
    MechAudio.play(Sfx.crownTick);
    MechAudio.haptic(Haptic.tick);
    setState(() => _offset += dir * widget.stepPx);
    widget.onStep(dir, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      increasedValue: 'Increase',
      decreasedValue: 'Decrease',
      onIncrease: () => _adjust(1),
      onDecrease: () => _adjust(-1),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _lastMs = DateTime.now().millisecondsSinceEpoch;
          _speed = 0;
        },
        onHorizontalDragUpdate: _update,
        onHorizontalDragEnd: (_) => _carry = 0,
        child: SizedBox(
          width: math.max(widget.width, 48),
          height: math.max(widget.height, 48),
          child: CustomPaint(painter: _CrownPainter(_offset)),
        ),
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  _CrownPainter(this.offset);
  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.12, size.width, size.height * 0.76),
      Radius.circular(size.height * 0.16),
    );
    canvas.drawRRect(
      body.shift(Offset(0, size.height * 0.05)),
      Paint()
        ..color = Colors.black.withOpacity(0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.05),
    );
    // Cylinder shading: light across the middle, dark at the top and bottom edges.
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Brass.brassLo, Brass.brassHi, Brass.brass, Brass.brassLo],
          stops: [0.0, 0.30, 0.62, 1.0],
        ).createShader(body.outerRect),
    );
    // Knurling: vertical ridges that scroll with the drag.
    canvas.save();
    canvas.clipRRect(body);
    const spacing = 7.0;
    final phase = offset % spacing;
    final dark = Paint()
      ..strokeWidth = 2.2
      ..color = Colors.black.withOpacity(0.38);
    final light = Paint()
      ..strokeWidth = 1.0
      ..color = Brass.brassHi.withOpacity(0.35);
    for (double x = -spacing + phase; x < size.width + spacing; x += spacing) {
      // Ridges bend slightly toward the edges to suggest a round body.
      canvas.drawLine(Offset(x, body.top), Offset(x, body.bottom), dark);
      canvas.drawLine(Offset(x + 2.4, body.top), Offset(x + 2.4, body.bottom), light);
    }
    canvas.restore();
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black.withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter o) => o.offset != offset;
}
