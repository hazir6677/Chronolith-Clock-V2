import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/chronolith_theme.dart';
import '../widgets/hero_clock_card.dart';
import '../widgets/organic_shapes.dart';

/// Tab 2: Live Digital & Expressive Scalloped Analog Clock with Circadian Rhythm
/// progress and a distraction-free Fullscreen Bedside / Nightstand Saver Mode.
class ClockTab extends StatefulWidget {
  final DateTime now;
  final ChronolithPalette palette;
  final bool use24HourFormat;

  const ClockTab({
    super.key,
    required this.now,
    required this.palette,
    required this.use24HourFormat,
  });

  @override
  State<ClockTab> createState() => _ClockTabState();
}

class _ClockTabState extends State<ClockTab> {
  bool _hourlyChime = true;
  bool _gentleSecondsPulse = true;

  void _openBedsideNightstand(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF170924),
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton.filledTonal(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_fullscreen_rounded),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'BEDSIDE AMBIENT MODE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          letterSpacing: 3.2,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC59BFA),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        widget.use24HourFormat
                            ? DateFormat('HH:mm').format(widget.now)
                            : DateFormat('h:mm').format(widget.now),
                        style: GoogleFonts.fredoka(
                          fontSize: 112,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF3E8FF),
                          height: 0.95,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy').format(widget.now),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB388EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondsFraction = widget.now.second / 60.0;
    final dayProgress =
        ((widget.now.hour * 60 + widget.now.minute) / 1440.0).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      children: [
        HeroClockCard(
          now: widget.now,
          palette: widget.palette,
          use24HourFormat: widget.use24HourFormat,
        ),
        const SizedBox(height: 18),

        // Expressive Scalloped Analog + Live Seconds Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.palette.cardLavenderSurface,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 148,
                height: 148,
                child: CustomPaint(
                  painter: ScallopedDialPainter(
                    progress: _gentleSecondsPulse ? secondsFraction : 1.0,
                    trackColor: widget.palette.heroWavePrimary.withOpacity(0.35),
                    activeColor: widget.palette.accentPill,
                    lobeFillColor: widget.palette.heroBackground,
                    showClockHands: true,
                    dateTime: widget.now,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: widget.palette.cardLavenderPill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'LIVE CHRONOGRAPH',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: widget.palette.inkSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      DateFormat('HH:mm:ss').format(widget.now),
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: widget.palette.inkPrimary,
                      ),
                    ),
                    Text(
                      'Local Timezone (${widget.now.timeZoneName})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.palette.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.palette.accentPill,
                        foregroundColor: widget.palette.accentPillForeground,
                      ),
                      onPressed: () => _openBedsideNightstand(context),
                      icon: const Icon(Icons.nightlight_round, size: 18),
                      label: const Text(
                        'Bedside Mode',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Daylight & Circadian Rhythm Progress Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.palette.cardRoseSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_twilight_rounded,
                        color: widget.palette.inkPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Daylight & Sleep Cycle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: widget.palette.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${(dayProgress * 100).round()}% of day',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.palette.inkSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: dayProgress,
                  minHeight: 12,
                  backgroundColor: widget.palette.cardRosePill,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.palette.heroBackground,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sunrise 6:18 AM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.palette.inkSecondary,
                    ),
                  ),
                  Text(
                    'Solar Peak 12:11 PM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.palette.inkSecondary,
                    ),
                  ),
                  Text(
                    'Sunset 6:04 PM',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.palette.inkSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Expressive Clock Toggles
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: widget.palette.cardLavenderSurface,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gentle Hourly Chime',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: widget.palette.inkPrimary,
                        ),
                      ),
                      Text(
                        'Soft harmonic pulse at the top of each hour',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: widget.palette.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  ChronolithSwitch(
                    value: _hourlyChime,
                    onChanged: (v) => setState(() => _hourlyChime = v),
                    palette: widget.palette,
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Animated Seconds Ring',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: widget.palette.inkPrimary,
                        ),
                      ),
                      Text(
                        'Sweep the scalloped M3 progress ring',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: widget.palette.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                  ChronolithSwitch(
                    value: _gentleSecondsPulse,
                    onChanged: (v) => setState(() => _gentleSecondsPulse = v),
                    palette: widget.palette,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
