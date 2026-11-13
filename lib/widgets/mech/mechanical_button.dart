import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/mech_audio.dart';
import '../../theme/brass.dart';

/// A physical brass button: depresses on touch, clicks, vibrates, springs back.
/// Sound and haptics fire on touch-down so they land with the visual press.
class MechanicalButton extends StatefulWidget {
  const MechanicalButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.semanticLabel,
    this.size = 56,
    this.width,
    this.glow = false,
    this.silent = false,
  });

  /// Usually an Icon or engraved Text. Drawn in amber.
  final Widget child;
  final VoidCallback? onPressed;
  final String semanticLabel;

  /// Diameter (or height when [width] is given for a pill).
  final double size;
  final double? width;

  /// Warm lit state (e.g. the active navigation button).
  final bool glow;
  final bool silent;

  @override
  State<MechanicalButton> createState() => _MechanicalButtonState();
}

class _MechanicalButtonState extends State<MechanicalButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 70),
    reverseDuration: const Duration(milliseconds: 170),
  );
  bool _enabled() => widget.onPressed != null;

  void _down() {
    if (!_enabled()) return;
    _c.forward();
    if (!widget.silent) MechAudio.play(Sfx.buttonClick);
    MechAudio.haptic(Haptic.light);
  }

  void _up() => _c.reverse();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.size;
    final h = widget.size;
    return Semantics(
      button: true,
      enabled: _enabled(),
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _down(),
        onTapCancel: _up,
        onTapUp: (_) => _up(),
        onTap: widget.onPressed,
        child: SizedBox(
          // Keep a 48dp touch target even for small decorative buttons.
          width: math.max(w, 48.0),
          height: math.max(h, 48.0),
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final p = Curves.easeOut.transform(_c.value);
                return Transform.translate(
                  offset: Offset(0, p * h * 0.06),
                  child: Transform.scale(
                    scale: 1 - 0.035 * p,
                    child: CustomPaint(
                      size: Size(w, h),
                      painter: _ButtonPainter(
                        pressed: p,
                        glow: widget.glow,
                        enabled: _enabled(),
                      ),
                      child: SizedBox(width: w, height: h, child: child),
                    ),
                  ),
                );
              },
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: widget.glow ? Brass.amber : Brass.engraved,
                    size: h * 0.46,
                  ),
                  child: DefaultTextStyle.merge(
                    style: Brass.engrave(h * 0.34),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonPainter extends CustomPainter {
  _ButtonPainter({required this.pressed, required this.glow, required this.enabled});
  final double pressed;
  final bool glow, enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final isPill = size.width > size.height * 1.05;
    Path shape(Rect r, double rad) => isPill
        ? (Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(rad))))
        : (Path()..addOval(r));

    // Drop shadow shrinks as the button goes down.
    canvas.drawPath(
      shape(rect, size.height / 2).shift(Offset(0, size.height * (0.10 - 0.06 * pressed))),
      Paint()
        ..color = Colors.black.withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.07),
    );
    // Outer collar.
    canvas.drawPath(
      shape(rect, size.height / 2),
      Paint()..shader = Brass.ringSweep().createShader(rect),
    );
    // Inner dome.
    final inner = rect.deflate(size.height * 0.10);
    final dome = shape(inner, inner.height / 2);
    canvas.drawPath(
      dome,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(-0.35 + pressed * 0.2, -0.5 + pressed * 0.3),
          radius: 1.1,
          colors: glow
              ? const [Color(0xFFFFE2A8), Brass.brass, Brass.brassMid]
              : const [Brass.brassHi, Brass.brass, Brass.brassLo],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(inner),
    );
    canvas.drawPath(
      dome,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withOpacity(0.45),
    );
    if (glow) {
      canvas.drawPath(
        dome,
        Paint()
          ..color = Brass.amber.withOpacity(0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.12),
      );
    }
    if (!enabled) {
      canvas.drawPath(dome, Paint()..color = Colors.black.withOpacity(0.45));
    }
  }

  @override
  bool shouldRepaint(covariant _ButtonPainter o) =>
      o.pressed != pressed || o.glow != glow || o.enabled != enabled;
}
