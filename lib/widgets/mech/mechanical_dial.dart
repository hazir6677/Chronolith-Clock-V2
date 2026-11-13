import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/mech_audio.dart';
import '../../theme/brass.dart';

/// Horizontal brass slider with an engraved scale and a knurled knob.
/// Used for the simulated-time slider on the main clock.
class MechanicalSlider extends StatefulWidget {
  const MechanicalSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.divisions = 48,
    this.semanticLabel = 'Time slider',
    this.semanticValue,
    this.height = 64,
  });

  /// 0..1
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Number of ratchet detents (each one ticks).
  final int divisions;
  final String semanticLabel;
  final String? semanticValue;
  final double height;

  @override
  State<MechanicalSlider> createState() => _MechanicalSliderState();
}

class _MechanicalSliderState extends State<MechanicalSlider> {
  int _lastDetent = -1;

  void _set(double dx, double width, {bool end = false}) {
    final inset = widget.height * 0.55;
    final v = ((dx - inset) / math.max(1, width - 2 * inset)).clamp(0.0, 1.0).toDouble();
    final detent = (v * widget.divisions).round();
    if (detent != _lastDetent) {
      _lastDetent = detent;
      MechAudio.play(Sfx.crownTick, volume: 0.55, minGapMs: 30);
      MechAudio.haptic(Haptic.tick);
    }
    widget.onChanged(detent / widget.divisions);
    if (end) widget.onChangeEnd?.call(detent / widget.divisions);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Semantics(
        slider: true,
        label: widget.semanticLabel,
        value: widget.semanticValue,
        onIncrease: () => widget.onChanged(math.min(1.0, widget.value + 1 / widget.divisions)),
        onDecrease: () => widget.onChanged(math.max(0.0, widget.value - 1 / widget.divisions)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _set(d.localPosition.dx, w),
          onTapUp: (d) => _set(d.localPosition.dx, w, end: true),
          onHorizontalDragUpdate: (d) => _set(d.localPosition.dx, w),
          onHorizontalDragEnd: (_) => widget.onChangeEnd?.call(widget.value),
          child: SizedBox(
            height: widget.height,
            width: w,
            child: CustomPaint(painter: _SliderPainter(widget.value, widget.divisions)),
          ),
        ),
      );
    });
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter(this.value, this.divisions);
  final double value;
  final int divisions;

  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.12, size.width, size.height * 0.76),
      Radius.circular(size.height * 0.38),
    );
    canvas.drawRRect(
      body.shift(Offset(0, size.height * 0.05)),
      Paint()
        ..color = Colors.black.withOpacity(0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.07),
    );
    canvas.drawRRect(body, Paint()..shader = Brass.ringSweep().createShader(body.outerRect));
    final track = body.deflate(size.height * 0.11);
    canvas.drawRRect(track, Paint()..color = Brass.smoke);

    final inset = size.height * 0.55;
    final usable = size.width - 2 * inset;
    final cy = size.height / 2;
    // Scale marks; amber where the knob has passed.
    for (var i = 0; i <= divisions; i++) {
      final x = inset + usable * i / divisions;
      final major = i % 4 == 0;
      final lit = i / divisions <= value;
      canvas.drawLine(
        Offset(x, cy - (major ? size.height * 0.17 : size.height * 0.09)),
        Offset(x, cy + (major ? size.height * 0.17 : size.height * 0.09)),
        Paint()
          ..strokeWidth = major ? 1.6 : 1.0
          ..color = lit ? Brass.amber.withOpacity(major ? 0.95 : 0.6) : Brass.brassLo,
      );
    }
    // Knob.
    final kx = inset + usable * value;
    final kw = size.height * 0.34, kh = size.height * 0.80;
    final knob = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(kx, cy), width: kw, height: kh),
      Radius.circular(kw * 0.35),
    );
    canvas.drawRRect(
      knob.shift(const Offset(1.5, 3)),
      Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      knob,
      Paint()
        ..shader = const LinearGradient(
          colors: [Brass.brassLo, Brass.brassHi, Brass.brassMid, Brass.brassLo],
          stops: [0.0, 0.35, 0.7, 1.0],
        ).createShader(knob.outerRect),
    );
    final ridge = Paint()
      ..strokeWidth = 1
      ..color = Colors.black.withOpacity(0.4);
    for (var y = knob.top + 5; y < knob.bottom - 3; y += 3.5) {
      canvas.drawLine(Offset(knob.left + 3, y), Offset(knob.right - 3, y), ridge);
    }
  }

  @override
  bool shouldRepaint(covariant _SliderPainter o) =>
      o.value != value || o.divisions != divisions;
}

/// Rotary selector knob with detents (e.g. snooze length). Drag around the
/// knob or use accessibility increase/decrease.
class MechanicalDial extends StatefulWidget {
  const MechanicalDial({
    super.key,
    required this.index,
    required this.count,
    required this.onChanged,
    this.size = 96,
    this.semanticLabel = 'Dial',
  });

  final int index, count;
  final ValueChanged<int> onChanged;
  final double size;
  final String semanticLabel;

  @override
  State<MechanicalDial> createState() => _MechanicalDialState();
}

class _MechanicalDialState extends State<MechanicalDial> {
  static const _sweep = math.pi * 1.5; // 270 degrees of travel

  void _fromPoint(Offset p) {
    final c = Offset(widget.size / 2, widget.size / 2);
    var a = math.atan2(p.dy - c.dy, p.dx - c.dx) + math.pi * 0.75; // 0 at lower-left stop
    a = (a % (2 * math.pi));
    if (a > _sweep) a = a < _sweep + (2 * math.pi - _sweep) / 2 ? _sweep : 0;
    final i = (a / _sweep * (widget.count - 1)).round();
    if (i != widget.index) {
      MechAudio.play(Sfx.crownTick, minGapMs: 20);
      MechAudio.haptic(Haptic.tick);
      widget.onChanged(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      onIncrease: widget.index < widget.count - 1
          ? () => widget.onChanged(widget.index + 1)
          : null,
      onDecrease: widget.index > 0 ? () => widget.onChanged(widget.index - 1) : null,
      child: GestureDetector(
        onPanStart: (d) => _fromPoint(d.localPosition),
        onPanUpdate: (d) => _fromPoint(d.localPosition),
        onTapUp: (d) => _fromPoint(d.localPosition),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(painter: _DialPainter(widget.index, widget.count)),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.index, this.count);
  final int index, count;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    const sweep = math.pi * 1.5;
    const start = math.pi * 0.75;
    // Detent marks.
    for (var i = 0; i < count; i++) {
      final a = start + sweep * i / math.max(1, count - 1);
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.86),
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.98),
        Paint()
          ..strokeWidth = 1.5
          ..color = i <= index ? Brass.amber : Brass.brassLo,
      );
    }
    final knobR = r * 0.74;
    canvas.drawCircle(c.translate(0, r * 0.06), knobR,
        Paint()..color = Colors.black.withOpacity(0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08));
    canvas.drawCircle(
      c,
      knobR,
      Paint()..shader = Brass.ringSweep().createShader(Rect.fromCircle(center: c, radius: knobR)),
    );
    canvas.drawCircle(
      c,
      knobR * 0.78,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Brass.brassHi, Brass.brass, Brass.brassLo],
        ).createShader(Rect.fromCircle(center: c, radius: knobR)),
    );
    final a = start + sweep * index / math.max(1, count - 1);
    canvas.drawLine(
      c + Offset(math.cos(a), math.sin(a)) * (knobR * 0.30),
      c + Offset(math.cos(a), math.sin(a)) * (knobR * 0.72),
      Paint()
        ..strokeWidth = r * 0.07
        ..strokeCap = StrokeCap.round
        ..color = Brass.engraved,
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter o) => o.index != index || o.count != count;
}
