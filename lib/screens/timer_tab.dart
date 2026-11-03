import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clock_models.dart';
import '../theme/chronolith_theme.dart';
import '../widgets/organic_shapes.dart';

/// Tab 4: Expressive Material 3 Timer with Scalloped Progress Dial,
/// +1:00 boost pill, and two-tone organic preset cards.
class TimerTab extends StatefulWidget {
  final ChronolithPalette palette;

  const TimerTab({super.key, required this.palette});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  Duration _totalDuration = const Duration(minutes: 15);
  Duration _remaining = const Duration(minutes: 15);
  Timer? _timer;
  bool _isRunning = false;

  static const List<TimerPreset> _presets = [
    TimerPreset(
      id: 'tea',
      label: 'Herbal Steep',
      duration: Duration(minutes: 5),
      icon: Icons.coffee_rounded,
      tone: AlarmCardTone.lavender,
    ),
    TimerPreset(
      id: 'nap',
      label: 'Power Nap',
      duration: Duration(minutes: 15),
      icon: Icons.bedtime_rounded,
      tone: AlarmCardTone.rose,
    ),
    TimerPreset(
      id: 'pomodoro',
      label: 'Deep Focus Sprint',
      duration: Duration(minutes: 25),
      icon: Icons.bolt_rounded,
      tone: AlarmCardTone.lavender,
    ),
    TimerPreset(
      id: 'workout',
      label: 'Gym Circuit',
      duration: Duration(minutes: 45),
      icon: Icons.fitness_center_rounded,
      tone: AlarmCardTone.rose,
    ),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleStartPause() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    if (_remaining.inSeconds <= 0) {
      _remaining = _totalDuration;
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remaining = Duration.zero;
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chronolith Timer completed!'),
            backgroundColor: widget.palette.heroBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remaining = _totalDuration;
    });
  }

  void _addOneMinute() {
    setState(() {
      _remaining += const Duration(minutes: 1);
      if (_remaining > _totalDuration) {
        _totalDuration = _remaining;
      }
    });
  }

  void _selectPreset(TimerPreset preset) {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _totalDuration = preset.duration;
      _remaining = preset.duration;
    });
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inSeconds == 0
        ? 0.0
        : _remaining.inSeconds / _totalDuration.inSeconds;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      children: [
        // Scalloped Timer Hero Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: widget.palette.heroBackground,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.palette.heroBackground.withOpacity(0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 215,
                height: 215,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: ScallopedDialPainter(
                          progress: progress,
                          trackColor:
                              widget.palette.heroWavePrimary.withOpacity(0.5),
                          activeColor: widget.palette.accentPill,
                          lobeFillColor:
                              widget.palette.heroWavePrimary.withOpacity(0.35),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatDuration(_remaining),
                          style: GoogleFonts.fredoka(
                            fontSize: 46,
                            fontWeight: FontWeight.w700,
                            color: widget.palette.heroTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isRunning ? 'RUNNING' : 'READY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.0,
                            color: widget.palette.heroTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reset Pill
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.palette.heroWavePrimary,
                      foregroundColor: widget.palette.heroTextPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _resetTimer,
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text('Reset'),
                  ),
                  const SizedBox(width: 12),

                  // Primary Start / Pause Expressive Pill
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.palette.accentPill,
                      foregroundColor: widget.palette.accentPillForeground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _toggleStartPause,
                    icon: Icon(
                      _isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      _isRunning ? 'Pause' : 'Start',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // +1:00 Boost Pill
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.palette.heroWavePrimary,
                      foregroundColor: widget.palette.heroTextPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _addOneMinute,
                    child: const Text(
                      '+1:00',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Expressive presets',
          style: GoogleFonts.fredoka(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: widget.palette.inkPrimary,
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(_presets.length, (index) {
          final preset = _presets[index];
          final isRose = preset.tone == AlarmCardTone.rose;
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
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _selectPreset(preset),
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(28),
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
                          width: 118,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${preset.duration.inMinutes}',
                                style: GoogleFonts.fredoka(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w700,
                                  color: widget.palette.inkPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'MIN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: widget.palette.inkPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(preset.icon, color: widget.palette.inkPrimary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            preset.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: widget.palette.inkPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: widget.palette.heroBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Load',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: widget.palette.heroTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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
