import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/alarm_engine.dart';
import '../theme/chronolith_theme.dart';

/// Full-screen "alarm is ringing" page with Snooze and Dismiss.
class RingingScreen extends StatefulWidget {
  final ChronolithPalette palette;
  final String label;
  final bool use24HourFormat;

  const RingingScreen({
    super.key,
    required this.palette,
    required this.label,
    required this.use24HourFormat,
  });

  @override
  State<RingingScreen> createState() => _RingingScreenState();
}

class _RingingScreenState extends State<RingingScreen> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      // Closed from the notification? Then close this screen too.
      final s = await AlarmEngine.ringingStatus();
      if (mounted && s != null && !s.isRinging) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime() {
    final h = widget.use24HourFormat
        ? _now.hour
        : (_now.hour % 12 == 0 ? 12 : _now.hour % 12);
    final m = _now.minute.toString().padLeft(2, '0');
    final suffix = widget.use24HourFormat ? '' : (_now.hour < 12 ? ' AM' : ' PM');
    return '${widget.use24HourFormat ? h.toString().padLeft(2, '0') : h}:$m$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: p.heroBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(Icons.alarm_rounded, size: 64, color: p.accentPill),
                const SizedBox(height: 18),
                Text(
                  _formatTime(),
                  style: GoogleFonts.fredoka(
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                    color: p.heroTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label.isEmpty ? 'Alarm' : widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: p.heroTextSecondary,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.heroWavePrimary,
                      foregroundColor: p.heroTextPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () async {
                      await AlarmEngine.snoozeRinging();
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                    child: const Text('Snooze 10 min',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.accentPill,
                      foregroundColor: p.accentPillForeground,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    onPressed: () async {
                      await AlarmEngine.stopRinging();
                      if (context.mounted) Navigator.of(context).maybePop();
                    },
                    child: const Text('Dismiss',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
