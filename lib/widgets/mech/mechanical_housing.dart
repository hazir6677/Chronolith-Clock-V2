import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/brass.dart';

enum HousingShape { circle, rrect }

/// Heavy brass bezel around a smoked-glass window. Children render inside the
/// glass; reflections and rim lighting are painted over them.
class MechanicalHousing extends StatelessWidget {
  const MechanicalHousing({
    super.key,
    this.child,
    this.shape = HousingShape.circle,
    this.ringFraction = 0.085,
    this.cornerRadius = 28,
    this.screws = 4,
    this.glass = true,
    this.glow = 0.0,
  });

  final Widget? child;
  final HousingShape shape;

  /// Bezel thickness as a fraction of the shortest side.
  final double ringFraction;
  final double cornerRadius;

  /// 0, 2 (top/bottom) or 4 (all four sides).
  final int screws;
  final bool glass;

  /// 0..1 amber light leaking from the glass edge (ringing / running states).
  final double glow;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        final ring = side * ringFraction;
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _RimPainter(shape, ring, cornerRadius, screws, glow),
            ),
            Padding(
              padding: EdgeInsets.all(ring),
              child: ClipPath(
                clipper: _InnerClipper(shape, cornerRadius - ring / 2),
                child: child ?? const SizedBox.expand(),
              ),
            ),
            if (glass)
              IgnorePointer(
                child: CustomPaint(
                  painter: _GlassPainter(shape, ring, cornerRadius),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _InnerClipper extends CustomClipper<Path> {
  _InnerClipper(this.shape, this.radius);
  final HousingShape shape;
  final double radius;

  @override
  Path getClip(Size size) {
    final r = Offset.zero & size;
    return shape == HousingShape.circle
        ? (Path()..addOval(Rect.fromCenter(
            center: r.center,
            width: math.min(size.width, size.height),
            height: math.min(size.width, size.height))))
        : (Path()..addRRect(RRect.fromRectAndRadius(
            r, Radius.circular(math.max(2, radius)))));
  }

  @override
  bool shouldReclip(covariant _InnerClipper old) =>
      old.shape != shape || old.radius != radius;
}

Rect _outerRect(Size size, HousingShape shape) {
  if (shape == HousingShape.circle) {
    final s = math.min(size.width, size.height);
    return Rect.fromCenter(center: size.center(Offset.zero), width: s, height: s);
  }
  return Offset.zero & size;
}

class _RimPainter extends CustomPainter {
  _RimPainter(this.shape, this.ring, this.corner, this.screws, this.glow);
  final HousingShape shape;
  final double ring, corner, glow;
  final int screws;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = _outerRect(size, shape);
    final inner = outer.deflate(ring);
    final isCircle = shape == HousingShape.circle;
    Path pathFor(Rect r, double radius) => isCircle
        ? (Path()..addOval(r))
        : (Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(radius))));

    final outerPath = pathFor(outer, corner);
    final innerPath = pathFor(inner, math.max(2, corner - ring));

    // Cast shadow on the panel behind.
    canvas.drawPath(
      outerPath.shift(Offset(0, ring * 0.35)),
      Paint()
        ..color = Colors.black.withOpacity(0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * 0.45),
    );

    // Bezel body: brushed brass sweep.
    final bezel = Path.combine(PathOperation.difference, outerPath, innerPath);
    canvas.drawPath(
      bezel,
      Paint()..shader = Brass.ringSweep().createShader(outer),
    );
    // Fine concentric brushing lines.
    final brush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = Colors.black.withOpacity(0.10);
    for (var i = 1; i < 6; i++) {
      canvas.drawPath(
        pathFor(outer.deflate(ring * i / 6.5), math.max(2, corner - ring * i / 6.5)),
        brush,
      );
    }
    // Bevel edges: light on the outside, dark where the glass is seated.
    canvas.drawPath(
      outerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brass.brassHi, Brass.brassLo],
        ).createShader(outer),
    );
    canvas.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * 0.14
        ..color = Colors.black.withOpacity(0.75),
    );
    // Seat of the glass: smoked interior.
    canvas.drawPath(
      innerPath,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          radius: 1.0,
          colors: [Color(0xFF1B1511), Brass.smoke],
        ).createShader(inner),
    );
    if (glow > 0) {
      canvas.drawPath(
        innerPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring * 0.5
          ..color = Brass.amber.withOpacity(0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * 0.5),
      );
    }

    // Screws seated in the bezel.
    if (screws > 0) {
      final c = outer.center;
      final mid = ring / 2;
      final spots = <Offset>[
        Offset(c.dx, outer.top + mid),
        Offset(c.dx, outer.bottom - mid),
        if (screws >= 4) Offset(outer.left + mid, c.dy),
        if (screws >= 4) Offset(outer.right - mid, c.dy),
      ];
      for (var i = 0; i < spots.length; i++) {
        _screw(canvas, spots[i], ring * 0.27, i * 0.9 + 0.4);
      }
    }
  }

  void _screw(Canvas canvas, Offset c, double r, double turn) {
    canvas.drawCircle(c.translate(0, r * 0.25), r * 1.1,
        Paint()..color = Colors.black.withOpacity(0.55));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.4, -0.5),
          colors: [Brass.brassHi, Brass.brassMid, Brass.brassLo],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(turn);
    final slot = Paint()
      ..color = const Color(0xFF2A1A0B)
      ..strokeWidth = r * 0.28
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(-r * 0.7, 0), Offset(r * 0.7, 0), slot);
    canvas.drawLine(Offset(0, -r * 0.7), Offset(0, r * 0.7), slot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RimPainter o) =>
      o.shape != shape || o.ring != ring || o.glow != glow || o.corner != corner;
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.shape, this.ring, this.corner);
  final HousingShape shape;
  final double ring, corner;

  @override
  void paint(Canvas canvas, Size size) {
    final inner = _outerRect(size, shape).deflate(ring);
    final isCircle = shape == HousingShape.circle;
    final clip = isCircle
        ? (Path()..addOval(inner))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(inner, Radius.circular(math.max(2, corner - ring)))));
    canvas.save();
    canvas.clipPath(clip);

    // Darkening smoke toward the edge.
    canvas.drawRect(
      inner,
      Paint()
        ..shader = RadialGradient(
          radius: 0.75,
          colors: [Colors.transparent, Colors.black.withOpacity(0.38)],
          stops: const [0.6, 1.0],
        ).createShader(inner),
    );
    // Broad diagonal reflection.
    final streak = Path()
      ..moveTo(inner.left + inner.width * 0.08, inner.top + inner.height * 0.30)
      ..quadraticBezierTo(inner.left + inner.width * 0.30, inner.top + inner.height * 0.02,
          inner.left + inner.width * 0.72, inner.top + inner.height * 0.04)
      ..quadraticBezierTo(inner.left + inner.width * 0.40, inner.top + inner.height * 0.14,
          inner.left + inner.width * 0.08, inner.top + inner.height * 0.30)
      ..close();
    canvas.drawPath(
      streak,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withOpacity(0.20), Colors.white.withOpacity(0.02)],
        ).createShader(inner),
    );
    // Warm rim catch-light on the lower-left.
    canvas.drawPath(
      clip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ring * 0.32
        ..shader = SweepGradient(
          colors: [
            Colors.transparent,
            Brass.amber.withOpacity(0.30),
            Colors.transparent,
          ],
          stops: const [0.30, 0.40, 0.52],
          transform: const GradientRotation(math.pi * 0.15),
        ).createShader(inner)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ring * 0.15),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassPainter o) =>
      o.shape != shape || o.ring != ring || o.corner != corner;
}
