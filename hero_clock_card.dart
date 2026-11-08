import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/chronolith_theme.dart';
import 'organic_shapes.dart';

/// Top Hero Time & Weather Card directly modeled on the Chronolith mockup.
/// Displays greeting, oversized fluid time + AM/PM, date, organic scalloped
/// mountain sunset cutout, and floating 26° weather pill badge.
class HeroClockCard extends StatelessWidget {
  final DateTime now;
  final ChronolithPalette palette;
  final bool use24HourFormat;
  final int temperatureCelsius;

  const HeroClockCard({
    super.key,
    required this.now,
    required this.palette,
    this.use24HourFormat = false,
    this.temperatureCelsius = 26,
  });

  String _greetingForHour(int hour) {
    if (hour < 12) return 'GOOD MORNING';
    if (hour < 17) return 'GOOD AFTERNOON';
    if (hour < 21) return 'GOOD EVENING';
    return 'GOOD NIGHT';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = use24HourFormat
        ? DateFormat('HH:mm').format(now)
        : DateFormat('h:mm').format(now);
    final periodStr = DateFormat('a').format(now);
    final dateStr = DateFormat('EEE, d MMM').format(now);

    return Container(
      height: 222,
      decoration: BoxDecoration(
        color: palette.heroBackground,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: palette.heroBackground.withOpacity(0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Organic wavy background layers inside the hero card
          Positioned.fill(
            child: CustomPaint(
              painter: HeroCardWavesPainter(palette: palette),
            ),
          ),

          // Left column: Greeting, oversized expressive time, and date
          Positioned(
            left: 22,
            top: 24,
            bottom: 22,
            right: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _greetingForHour(now.hour),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.8,
                    color: palette.heroTextSecondary,
                  ),
                ),
                 FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        timeStr,
                        style: GoogleFonts.fredoka(
                          fontSize: 78,
                          fontWeight: FontWeight.w700,
                          color: palette.heroTextPrimary,
                          height: 0.95,
                          letterSpacing: -1.5,
                        ),
                      ),
                      if (!use24HourFormat) ...[
                        const SizedBox(width: 6),
                        Text(
                          periodStr,
                          style: GoogleFonts.fredoka(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: palette.heroTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: palette.heroTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right side: Scalloped organic cutout with alpine sunset image
          Positioned(
            right: 10,
            top: 12,
            bottom: 12,
            width: 175,
            child: ClipPath(
              clipper: ScallopedCloudClipper(),
              child: CustomPaint(
                painter: MountainSunsetPainter(),
                child: Image.asset(
                  'assets/images/mountain_sunset.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.expand(),
                ),
              ),
            ),
          ),

          // Bottom-right floating weather pill badge ("26°")
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: palette.weatherPillBackground,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 26,
                    height: 22,
                    child: Stack(
                      children: [
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: Icon(
                            Icons.wb_sunny_rounded,
                            size: 16,
                            color: Color(0xFFFFD54F),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.cloud_rounded,
                            size: 19,
                            color: Colors.white.withOpacity(0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$temperatureCelsius°',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
