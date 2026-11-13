import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material palette and type for the mechanical design language:
/// brushed brass, bronze, copper, gunmetal, smoked glass, warm amber light.
class Brass {
  Brass._();

  static const Color bgTop = Color(0xFF241A14);
  static const Color bgBottom = Color(0xFF0C0806);
  static const Color brassHi = Color(0xFFF3D391);
  static const Color brass = Color(0xFFC9964F);
  static const Color brassMid = Color(0xFF9A6B32);
  static const Color brassLo = Color(0xFF5E3D1A);
  static const Color copper = Color(0xFFB8693C);
  static const Color gunmetal = Color(0xFF2B2623);
  static const Color charcoal = Color(0xFF16120F);
  static const Color smoke = Color(0xFF0B0807);
  static const Color amber = Color(0xFFFFB347);
  static const Color amberDeep = Color(0xFFFF8A1F);
  static const Color cream = Color(0xFFF3E7CC);
  static const Color ruby = Color(0xFFB0204A);
  static const Color engraved = Color(0xFF3A2813);

  static const List<Color> _ring = [
    brassHi, brass, brassLo, brassMid, brassHi, brass, brassLo, brassMid, brassHi,
  ];

  /// Conical, brushed-metal look for rims and bezels.
  static SweepGradient ringSweep({double rotation = -math.pi / 4}) =>
      SweepGradient(colors: _ring, transform: GradientRotation(rotation));

  static LinearGradient brassLinear({
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
  }) =>
      LinearGradient(
        begin: begin,
        end: end,
        colors: const [brassHi, brass, brassMid, brassLo],
        stops: const [0.0, 0.35, 0.72, 1.0],
      );

  static const List<FontFeature> _lining = [
    FontFeature.liningFigures(),
    FontFeature.tabularFigures(),
  ];

  /// Large serif numerals for flip digits.
  static TextStyle numerals(double size, {Color color = cream}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
        fontFeatures: _lining,
      );

  /// Restrained supporting text.
  static TextStyle label(double size,
          {Color color = cream, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1.1,
        fontFeatures: _lining,
      );

  /// Text stamped into brass plates.
  static TextStyle engrave(double size) => GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: engraved,
        height: 1.0,
        letterSpacing: size * 0.06,
        shadows: const [Shadow(color: Color(0x66FFE2A8), offset: Offset(0, 0.8))],
      );
}

/// Deep brown/charcoal backdrop with warm directional light.
class BrassBackdrop extends StatelessWidget {
  const BrassBackdrop({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _BackdropPainter(), child: child),
      );
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Brass.bgTop, Brass.bgBottom],
        ).createShader(rect),
    );
    // Soft shafts of warm light falling from the upper right.
    final shaft = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.55 + i * 0.16);
      final w = size.width * (0.10 + 0.03 * (i % 2));
      final path = Path()
        ..moveTo(x, -20)
        ..lineTo(x + w, -20)
        ..lineTo(x + w - size.width * 0.55, size.height * 0.75)
        ..lineTo(x - size.width * 0.55, size.height * 0.75)
        ..close();
      shaft.shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          const Color(0xFFFFB066).withOpacity(0.07 - i * 0.012),
          const Color(0x00FFB066),
        ],
      ).createShader(rect);
      canvas.drawPath(path, shaft);
    }
    // Vignette.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
          stops: const [0.55, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
