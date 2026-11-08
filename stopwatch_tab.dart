import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clock_models.dart';
import '../theme/chronolith_theme.dart';
import '../widgets/organic_shapes.dart';

/// Tab 5: High-Precision Millisecond Stopwatch with Lap Split Comparison,
/// Best/Slowest Lap Highlights, and Organic Two-Tone Cards.
class StopwatchTab extends StatefulWidget {
  final ChronolithPalette palette;

  const StopwatchTab({super.key, required this.palette});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}

class _StopwatchTabState extends State<StopwatchTab> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  final List<LapRecord> _laps = [];
  Duration _lastLapTotal = Duration.zero;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleStartPause() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
      setState(() {});
    } else {
      _stopwatch.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (mounted) setState(() {});
      });
      setState(() {});
    }
  }

  void _recordLapOrReset() {
    if (_stopwatch.isRunning) {
      final total = _stopwatch.elapsed;
      final split = total - _lastLapTotal;
      _lastLapTotal = total;
      setState(() {
        _laps.insert(
          0,
          LapRecord(
            lapNumber: _laps.length + 1,
            splitDuration: split,
            totalDuration: total,
          ),
        );
      });
    } else {
      _stopwatch.reset();
      _lastLapTotal = Duration.zero;
      setState(() {
        _laps.clear();
      });
    }
  }

  String _formatMain(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String _formatCentiseconds(Duration d) {
    final cs = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '.$cs';
  }

  String _formatFull(Duration d) =>
      '${_formatMain(d)}${_formatCentiseconds(d)}';

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;

    // Identify best & slowest laps when 2+ laps exist
    int? fastestLapNum;
    int? slowestLapNum;
    if (_laps.length >= 2) {
      var sorted = List<LapRecord>.from(_laps)
        ..sort((a, b) => a.splitDuration.compareTo(b.splitDuration));
      fastestLapNum = sorted.first.lapNumber;
      slowestLapNum = sorted.last.lapNumber;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      children: [
        // Hero Stopwatch Display Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            color: widget.palette.heroBackground,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.palette.heroBackground.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: HeroCardWavesPainter(palette: widget.palette),
            child: Column(
              children: [
                Text(
                  'PRECISION STOPWATCH',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                    color: widget.palette.heroTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatMain(elapsed),
                      style: GoogleFonts.fredoka(
                        fontSize: 70,
                        fontWeight: FontWeight.w700,
                        color: widget.palette.heroTextPrimary,
                        height: 0.95,
                      ),
                    ),
                    Text(
                      _formatCentiseconds(elapsed),
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: widget.palette.accentPill,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_stopwatch.isRunning || elapsed.inMilliseconds > 0) ...[
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.palette.heroWavePrimary,
                        foregroundColor: widget.palette.heroTextPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 13,
                        ),
                      ),
                      onPressed: (elapsed.inMilliseconds == 0 &&
                              !_stopwatch.isRunning)
                          ? null
                          : _recordLapOrReset,
                      icon: Icon(
                        _stopwatch.isRunning
                            ? Icons.flag_rounded
                            : Icons.refresh_rounded,
                      ),
                      label: Text(
                        _stopwatch.isRunning ? 'Lap' : 'Reset',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.palette.accentPill,
                        foregroundColor: widget.palette.accentPillForeground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: _toggleStartPause,
                      icon: Icon(
                        _stopwatch.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        _stopwatch.isRunning ? 'Pause' : 'Start',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recorded laps',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: widget.palette.inkPrimary,
              ),
            ),
            Text(
              '${_laps.length} total',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: widget.palette.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_laps.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.palette.cardLavenderSurface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 28,
                  color: widget.palette.inkSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Start the stopwatch and tap Lap to compare split times with automatic fastest/slowest highlights.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: widget.palette.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(_laps.length, (index) {
            final lap = _laps[index];
            final isFastest = lap.lapNumber == fastestLapNum;
            final isSlowest = lap.lapNumber == slowestLapNum;
            final isRose = isSlowest || (index % 2 == 1 && !isFastest);
            final baseColor = isRose
                ? widget.palette.cardRoseSurface
                : widget.palette.cardLavenderSurface;
            final pillColor = isRose
                ? widget.palette.cardRosePill
                : widget.palette.cardLavenderPill;
            final waveColor = isRose
                ? widget.palette.cardRoseWave
                : widget.palette.cardLavenderWave;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: CustomPaint(
                  painter: CardOrganicBlobPainter(
                    pillColor: pillColor,
                    waveColor: waveColor,
                    variant: index,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            'Lap ${lap.lapNumber}',
                            style: GoogleFonts.fredoka(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: widget.palette.inkPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Split +${_formatFull(lap.splitDuration)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: widget.palette.inkPrimary,
                                ),
                              ),
                              Text(
                                'Total ${_formatFull(lap.totalDuration)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: widget.palette.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isFastest || isSlowest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.palette.heroBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              isFastest ? 'FASTEST' : 'SLOWEST',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: widget.palette.heroTextPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
