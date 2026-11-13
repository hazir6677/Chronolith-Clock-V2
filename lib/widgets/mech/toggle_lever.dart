import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../services/mech_audio.dart';
import '../../theme/brass.dart';

/// A spring-loaded toggle lever in a vertical slot. Drag, flick or tap.
/// It rests at one end of the slot; moving it to the other end engages it.
/// Releasing short of the detent springs it back.
class ToggleLever extends StatefulWidget {
  const ToggleLever({
    super.key,
    required this.onEngaged,
    required this.semanticLabel,
    this.icon,
    this.engagedAtTop = true,
    this.width = 128,
    this.height = 200,
  });

  final VoidCallback onEngaged;
  final String semanticLabel;

  /// Engraved symbol above the slot.
  final Widget? icon;

  /// true: starts at the bottom, engages at the top. false: the reverse.
  final bool engagedAtTop;
  final double width, height;

  @override
  State<ToggleLever> createState() => _ToggleLeverState();
}

class _ToggleLeverState extends State<ToggleLever> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() => _p = _c.value));
  double _p = 0; // 0 = rest, 1 = engaged
  bool _engaged = false;
  bool _crossed = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 520, damping: 27);

  double get _travel => widget.height * 0.44;
  double get _dir => widget.engagedAtTop ? -1 : 1; // screen-y sign toward engaged

  void _snapTo(double target, double velocity) {
    _c.animateWith(SpringSimulation(_spring, _p, target, velocity)).whenComplete(() {
      if (!mounted) return;
      if (target == 1.0 && !_engaged) _engage();
    });
  }

  void _engage() {
    _engaged = true;
    _p = 1.0;
    MechAudio.play(Sfx.leverClack);
    MechAudio.haptic(Haptic.heavy);
    // Let the lever visibly settle before the action runs.
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) widget.onEngaged();
    });
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_engaged) return;
    _c.stop();
    // Resistance builds toward the detent so it feels sprung.
    final resist = 1.0 - 0.35 * _p;
    final dp = (d.delta.dy * _dir / _travel) * resist;
    setState(() => _p = math.min(1.0, math.max(-0.03, _p + dp)));
    if (!_crossed && _p >= 0.55) {
      _crossed = true;
      MechAudio.haptic(Haptic.tick);
    } else if (_crossed && _p < 0.5) {
      _crossed = false;
    }
  }

  void _dragEnd(DragEndDetails d) {
    if (_engaged) return;
    final vp = d.velocity.pixelsPerSecond.dy * _dir / _travel;
    final goes = _p + vp * 0.10 > 0.55;
    _snapTo(goes ? 1.0 : 0.0, vp);
  }

  void _tap() {
    if (_engaged) return;
    _snapTo(1.0, 2.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: _tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        onVerticalDragUpdate: _dragUpdate,
        onVerticalDragEnd: _dragEnd,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _LeverPainter(math.min(1.04, math.max(-0.04, _p)), widget.engagedAtTop),
              ),
              if (widget.icon != null)
                Positioned(
                  top: widget.height * 0.07,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(color: Brass.amber, size: widget.height * 0.11),
                      child: widget.icon!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeverPainter extends CustomPainter {
  _LeverPainter(this.p, this.engagedAtTop);
  final double p;
  final bool engagedAtTop;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.5),
    );
    canvas.drawRRect(
      plate.shift(Offset(0, size.height * 0.02)),
      Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.05),
    );
    canvas.drawRRect(
      plate,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A322C), Color(0xFF1F1A17)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      plate.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Brass.brassMid.withOpacity(0.55),
    );
    // Corner screws.
    for (final o in [
      Offset(size.width * 0.17, size.height * 0.20),
      Offset(size.width * 0.83, size.height * 0.20),
      Offset(size.width * 0.17, size.height * 0.80),
      Offset(size.width * 0.83, size.height * 0.80),
    ]) {
      canvas.drawCircle(o, size.width * 0.032,
          Paint()..color = Brass.brassMid);
      canvas.drawCircle(o, size.width * 0.012, Paint()..color = Brass.smoke);
    }

    // Slot.
    final slotW = size.width * 0.50;
    final slotH = size.height * 0.62;
    final slot = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.53), width: slotW, height: slotH),
      Radius.circular(slotW / 2),
    );
    canvas.drawRRect(
      slot.inflate(size.width * 0.035),
      Paint()..shader = Brass.ringSweep().createShader(slot.outerRect.inflate(8)),
    );
    canvas.drawRRect(slot, Paint()..color = Brass.smoke);
    canvas.drawRRect(
      slot.deflate(size.width * 0.02),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.03
        ..color = Colors.black.withOpacity(0.7),
    );

    // Lever: pivot at the slot centre, ball slides along the slot.
    final pivot = slot.center;
    final half = slotH / 2 - slotW * 0.42;
    final restY = engagedAtTop ? half : -half; // offset from pivot
    final engY = -restY;
    final ballY = restY + (engY - restY) * p;
    final ball = pivot + Offset(0, ballY);
    final armW = size.width * 0.10;

    // Arm.
    final armRect = Rect.fromPoints(pivot, ball).inflate(armW / 2);
    canvas.drawLine(
      pivot.translate(size.width * 0.02, 2),
      ball.translate(size.width * 0.02, 2),
      Paint()
        ..strokeWidth = armW
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withOpacity(0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawLine(
      pivot,
      ball,
      Paint()
        ..strokeWidth = armW
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Brass.brassLo, Brass.brassHi, Brass.brassMid],
        ).createShader(armRect.inflate(4)),
    );
    // Pivot boss.
    canvas.drawCircle(
      pivot,
      size.width * 0.085,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Brass.brassHi, Brass.brassMid, Brass.brassLo],
        ).createShader(Rect.fromCircle(center: pivot, radius: size.width * 0.085)),
    );
    // Ball: bigger when engaged toward the viewer.
    final br = size.width * (0.185 + 0.012 * math.max(0, p));
    canvas.drawCircle(
      ball.translate(size.width * 0.02, size.width * 0.04),
      br,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, br * 0.3),
    );
    canvas.drawCircle(
      ball,
      br,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.0,
          colors: const [Color(0xFFFFEBC0), Brass.brass, Brass.brassLo],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: ball, radius: br)),
    );
    canvas.drawCircle(
      ball.translate(-br * 0.35, -br * 0.4),
      br * 0.18,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _LeverPainter o) =>
      o.p != p || o.engagedAtTop != engagedAtTop;
}
