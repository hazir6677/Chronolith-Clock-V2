import 'dart:async';
import 'package:flutter/cupertino.dart'
    show
        CupertinoTimerPicker,
        CupertinoTimerPickerMode,
        CupertinoTheme,
        CupertinoThemeData,
        CupertinoTextThemeData;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clock_models.dart';
import '../services/alarm_engine.dart';
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
  Duration _totalDuration = Duration.zero;
  Duration _remaining = Duration.zero;
  DateTime? _endsAt;
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

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    AlarmEngine.cancelTimer();
  }

  void _toggleStartPause() {
    if (_isRunning) {
      final left = _endsAt?.difference(DateTime.now()) ?? _remaining;
      _stopTicking();
      setState(() {
        _remaining = left.isNegative ? Duration.zero : left;
        _isRunning = false;
      });
      return;
    }

    if (_remaining.inMilliseconds <= 0) {
      _openTimePicker();
      return;
    }

    _endsAt = DateTime.now().add(_remaining);
    AlarmEngine.scheduleTimer(_endsAt!);
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _endsAt == null) return;
      final left = _endsAt!.difference(DateTime.now());
      if (left <= Duration.zero) {
        // The native alarm engine rings the timer; here we just reset the UI.
        _timer?.cancel();
        _timer = null;
        _endsAt = null;
        setState(() {
          _remaining = _totalDuration;
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chronolith Timer completed!'),
            backgroundColor: widget.palette.heroBackground,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (_secondsCeil(left) != _secondsCeil(_remaining)) {
        setState(() => _remaining = left);
      }
    });
  }

  /// Reset clears the timer back to 00:00.
  void _resetTimer() {
    _stopTicking();
    setState(() {
      _isRunning = false;
      _totalDuration = Duration.zero;
      _remaining = Duration.zero;
    });
  }

  void _addOneMinute() {
    setState(() {
      _remaining += const Duration(minutes: 1);
      if (_remaining > _totalDuration) {
        _totalDuration = _remaining;
      }
    });
    if (_isRunning && _endsAt != null) {
      _endsAt = _endsAt!.add(const Duration(minutes: 1));
      AlarmEngine.scheduleTimer(_endsAt!);
    }
  }

  void _selectPreset(TimerPreset preset) {
    _stopTicking();
    setState(() {
      _isRunning = false;
      _totalDuration = preset.duration;
      _remaining = preset.duration;
    });
  }

  Future<void> _openTimePicker() async {
    if (_isRunning) return;
    final p = widget.palette;
    Duration picked = _remaining > Duration.zero
        ? _remaining
        : const Duration(minutes: 5);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.cardLavenderSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set timer',
                  style: GoogleFonts.fredoka(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: p.inkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 190,
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(
                          color: p.inkPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: picked,
                      onTimerDurationChanged: (d) => picked = d,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.heroBackground,
                      foregroundColor: p.heroTextPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Set',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirmed == true && picked > Duration.zero && mounted) {
      setState(() {
        _totalDuration = picked;
        _remaining = picked;
      });
    }
  }

  int _secondsCeil(Duration d) => (d.inMilliseconds + 999) ~/ 1000;

  String _formatDuration(Duration d) {
    final total = _secondsCeil(d);
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final sec = total % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inMilliseconds == 0
        ? 0.0
        : (_remaining.inMilliseconds / _totalDuration.inMilliseconds)
            .clamp(0.0, 1.0);

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
              GestureDetector(
                onTap: _openTimePicker,
                child: SizedBox(
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
                          _isRunning
                              ? 'RUNNING'
                              : (_remaining == Duration.zero
                                  ? 'TAP TO SET TIME'
                                  : 'READY'),
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
