import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/chronolith_theme.dart';

/// Paints the dreamy organic lavender background waves shown behind the dashboard.
class DreamyBackgroundPainter extends CustomPainter {
  final ChronolithPalette palette;

  DreamyBackgroundPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.backgroundBlob.withOpacity(0.55)
      ..style = PaintingStyle.fill;

    // Top-left organic wave
    final topBlob = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.36, 0)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.06,
        size.width * 0.25,
        size.height * 0.11,
        0,
        size.height * 0.09,
      )
      ..close();
    canvas.drawPath(topBlob, paint);

    // Right mid organic wave
    final rightBlob = Path()
      ..moveTo(size.width, size.height * 0.18)
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.22,
        size.width * 0.88,
        size.height * 0.38,
        size.width,
        size.height * 0.44,
      )
      ..close();
    canvas.drawPath(rightBlob, paint);

    // Bottom-left organic wave
    final bottomLeftBlob = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.14,
        size.height * 0.68,
        size.width * 0.12,
        size.height * 0.86,
        0,
        size.height * 0.94,
      )
      ..close();
    canvas.drawPath(bottomLeftBlob, paint);
  }

  @override
  bool shouldRepaint(covariant DreamyBackgroundPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Paints the layered purple & lavender waves inside the Deep Plum Hero Card.
class HeroCardWavesPainter extends CustomPainter {
  final ChronolithPalette palette;

  HeroCardWavesPainter({required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final midPurplePaint = Paint()
      ..color = palette.heroWavePrimary
      ..style = PaintingStyle.fill;

    final softLavenderPaint = Paint()
      ..color = palette.heroWaveSecondary
      ..style = PaintingStyle.fill;

    // Right organic wave bed behind the mountain cutout
    final rightWave = Path()
      ..moveTo(size.width * 0.56, 0)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.32,
        size.width * 0.45,
        size.height * 0.68,
        size.width * 0.60,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(rightWave, midPurplePaint);

    // Top-right soft lavender wave crest
    final topRightCrest = Path()
      ..moveTo(size.width * 0.58, 0)
      ..cubicTo(
        size.width * 0.60,
        size.height * 0.20,
        size.width * 0.78,
        size.height * 0.14,
        size.width,
        size.height * 0.24,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topRightCrest, softLavenderPaint);

    // Bottom-center soft lavender hill
    final bottomHill = Path()
      ..moveTo(size.width * 0.24, size.height)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.76,
        size.width * 0.48,
        size.height * 0.74,
        size.width * 0.56,
        size.height,
      )
      ..close();
    canvas.drawPath(bottomHill, softLavenderPaint);
  }

  @override
  bool shouldRepaint(covariant HeroCardWavesPainter oldDelegate) =>
      oldDelegate.palette != palette;
}

/// Scalloped 6-lobe flower/cloud clipper matching the mountain landscape cutout in the mockup.
class ScallopedCloudClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Smooth organic multi-lobed cloud/flower silhouette matching the right hero cutout
    path.moveTo(w * 0.55, h * 0.05);
    // Top-right lobe
    path.cubicTo(w * 0.74, h * 0.01, w * 0.80, h * 0.16, w * 0.88, h * 0.22);
    // Upper-right bulge
    path.cubicTo(w * 1.02, h * 0.28, w * 0.99, h * 0.48, w * 0.91, h * 0.57);
    // Lower-right lobe
    path.cubicTo(w * 1.01, h * 0.70, w * 0.96, h * 0.92, w * 0.78, h * 0.96);
    // Bottom center-left lobe
    path.cubicTo(w * 0.58, h * 0.99, w * 0.32, h * 0.98, w * 0.24, h * 0.86);
    // Mid-left indentation
    path.cubicTo(w * 0.19, h * 0.75, w * 0.30, h * 0.66, w * 0.22, h * 0.58);
    // Leftmost lobe (pointing toward 9:30 AM)
    path.cubicTo(w * 0.01, h * 0.52, w * 0.01, h * 0.32, w * 0.22, h * 0.29);
    // Upper-left transition into top lobe
    path.cubicTo(w * 0.37, h * 0.27, w * 0.38, h * 0.08, w * 0.55, h * 0.05);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Procedural fallback painter for the dreamy pink/purple mountain sunset
/// in case asset loading is unavailable in tests.
class MountainSunsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final skyRect = Offset.zero & size;
    final skyGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFE7A9D7),
        Color(0xFFF3B7C8),
        Color(0xFF9C72B8),
        Color(0xFF3E2963),
      ],
    ).createShader(skyRect);

    canvas.drawRect(skyRect, Paint()..shader = skyGradient);

    // Distant mountain peak
    final peakPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.82)
      ..lineTo(size.width * 0.52, size.height * 0.38)
      ..lineTo(size.width * 0.74, size.height * 0.26)
      ..lineTo(size.width * 0.98, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      peakPath,
      Paint()..color = const Color(0xFF3B245B),
    );

    // Highlighted ridge lines
    final ridgePath = Path()
      ..moveTo(size.width * 0.74, size.height * 0.26)
      ..lineTo(size.width * 0.62, size.height * 0.55)
      ..lineTo(size.width * 0.82, size.height * 0.64)
      ..close();

    canvas.drawPath(
      ridgePath,
      Paint()..color = const Color(0xFF7B549C).withOpacity(0.65),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the organictwo-tone right-side wave inside each Alarm / World Clock / Preset card.
class CardOrganicBlobPainter extends CustomPainter {
  final Color pillColor;
  final Color waveColor;
  final int variant;

  CardOrganicBlobPainter({
    required this.pillColor,
    required this.waveColor,
    this.variant = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Left brighter rounded capsule for the big time numbers
    final leftCapsule = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.30, 0)
      ..cubicTo(
        size.width * 0.39,
        size.height * 0.18,
        size.width * 0.39,
        size.height * 0.82,
        size.width * 0.44,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftCapsule, Paint()..color = pillColor);

    // Right organic blob around the toggle switch
    final blobPaint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final blob = Path();
    if (variant % 3 == 0) {
      blob.moveTo(size.width * 0.72, 0);
      blob.cubicTo(
        size.width * 0.68,
        size.height * 0.45,
        size.width * 0.78,
        size.height * 0.72,
        size.width * 0.70,
        size.height,
      );
      blob.lineTo(size.width * 0.94, size.height);
      blob.cubicTo(
        size.width * 0.98,
        size.height * 0.62,
        size.width * 0.88,
        size.height * 0.28,
        size.width * 0.72,
        0,
      );
    } else if (variant % 3 == 1) {
      blob.moveTo(size.width * 0.76, 0);
      blob.cubicTo(
        size.width * 0.64,
        size.height * 0.32,
        size.width * 0.66,
        size.height * 0.78,
        size.width * 0.82,
        size.height,
      );
      blob.lineTo(size.width * 0.95, size.height);
      blob.cubicTo(
        size.width * 0.91,
        size.height * 0.52,
        size.width * 0.94,
        size.height * 0.18,
        size.width * 0.76,
        0,
      );
    } else {
      blob.moveTo(size.width * 0.62, size.height);
      blob.cubicTo(
        size.width * 0.66,
        size.height * 0.25,
        size.width * 0.76,
        size.height * 0.04,
        size.width * 0.88,
        size.height * 0.32,
      );
      blob.cubicTo(
        size.width * 0.96,
        size.height * 0.56,
        size.width * 0.88,
        size.height * 0.88,
        size.width * 0.76,
        size.height,
      );
    }
    blob.close();
    canvas.drawPath(blob, blobPaint);
  }

  @override
  bool shouldRepaint(covariant CardOrganicBlobPainter oldDelegate) =>
      oldDelegate.pillColor != pillColor ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.variant != variant;
}

/// Custom Material 3 Expressive oversized pill switch matching the mockup.
class ChronolithSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final ChronolithPalette palette;

  const ChronolithSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutBack,
        width: 72,
        height: 40,
        padding: const EdgeInsets.all(4.5),
        decoration: BoxDecoration(
          color: value ? palette.switchActiveTrack : palette.switchInactiveTrack,
          borderRadius: BorderRadius.circular(24),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: value
                  ? const Color(0xFFF6F1FF)
                  : const Color(0xFFEDE2F5),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.14),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints an expressive scalloped Material 3 analog clock dial or timer ring.
class ScallopedDialPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color activeColor;
  final Color lobeFillColor;
  final bool showClockHands;
  final DateTime? dateTime;

  ScallopedDialPainter({
    required this.progress,
    required this.trackColor,
    required this.activeColor,
    required this.lobeFillColor,
    this.showClockHands = false,
    this.dateTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.42;

    // 12-lobed soft scalloped M3 Expressive flower background
    final scallopPath = Path();
    const int steps = 180;
    for (int i = 0; i <= steps; i++) {
      final theta = (i / steps) * 2 * math.pi;
      final wave = math.sin(theta * 12) * (baseRadius * 0.065);
      final r = baseRadius * 1.06 + wave;
      final x = center.dx + r * math.cos(theta);
      final y = center.dy + r * math.sin(theta);
      if (i == 0) {
        scallopPath.moveTo(x, y);
      } else {
        scallopPath.lineTo(x, y);
      }
    }
    scallopPath.close();
    canvas.drawPath(scallopPath, Paint()..color = lobeFillColor);

    // Circular progress ring
    final ringRect = Rect.fromCircle(center: center, radius: baseRadius * 0.88);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(ringRect, 0, 2 * math.pi, false, trackPaint);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      activePaint,
    );

    if (showClockHands && dateTime != null) {
      final dt = dateTime!;
      // Hour ticks
      for (int h = 0; h < 12; h++) {
        final angle = (h / 12) * 2 * math.pi - math.pi / 2;
        final outer = Offset(
          center.dx + (baseRadius * 0.76) * math.cos(angle),
          center.dy + (baseRadius * 0.76) * math.sin(angle),
        );
        final inner = Offset(
          center.dx + (baseRadius * (h % 3 == 0 ? 0.64 : 0.69)) * math.cos(angle),
          center.dy + (baseRadius * (h % 3 == 0 ? 0.64 : 0.69)) * math.sin(angle),
        );
        canvas.drawLine(
          inner,
          outer,
          Paint()
            ..color = activeColor.withOpacity(h % 3 == 0 ? 0.9 : 0.45)
            ..strokeWidth = h % 3 == 0 ? 3.5 : 2
            ..strokeCap = StrokeCap.round,
        );
      }

      // Hour hand
      final hourAngle =
          (((dt.hour % 12) + dt.minute / 60.0) / 12.0) * 2 * math.pi - math.pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + baseRadius * 0.42 * math.cos(hourAngle),
          center.dy + baseRadius * 0.42 * math.sin(hourAngle),
        ),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      // Minute hand
      final minAngle =
          ((dt.minute + dt.second / 60.0) / 60.0) * 2 * math.pi - math.pi / 2;
      canvas.drawLine(
        center,
        Offset(
          center.dx + baseRadius * 0.60 * math.cos(minAngle),
          center.dy + baseRadius * 0.60 * math.sin(minAngle),
        ),
        Paint()
          ..color = activeColor
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round,
      );

      // Center cap
      canvas.drawCircle(center, 6, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant ScallopedDialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.dateTime != dateTime ||
      oldDelegate.activeColor != activeColor;
}
