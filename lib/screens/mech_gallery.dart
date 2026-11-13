import 'dart:async';

import 'package:flutter/material.dart';

import '../services/mech_audio.dart';
import '../services/settings.dart';
import '../theme/brass.dart';
import '../widgets/mech/mech.dart';

/// Phase 1 test bench for the mechanical components. Open it with a long
/// press on the "Chronolith" title. Removed once the real screens land.
class MechGalleryPage extends StatefulWidget {
  const MechGalleryPage({super.key});

  @override
  State<MechGalleryPage> createState() => _MechGalleryPageState();
}

class _MechGalleryPageState extends State<MechGalleryPage> {
  late Timer _tick;
  DateTime _now = DateTime.now();
  double _slider = 0.5;
  int _crown = 25; // minutes
  String _lever = 'none';
  int _dial = 1;
  final _settings = ChronolithSettings.instance;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _settings.addListener(_rebuild);
    MechAudio.setAmbience(true);
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
      MechAudio.setAmbience(true);
    }
  }

  @override
  void dispose() {
    _tick.cancel();
    _settings.removeListener(_rebuild);
    MechAudio.setAmbience(false);
    super.dispose();
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final h12 = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    return Scaffold(
      backgroundColor: Brass.bgBottom,
      body: BrassBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            children: [
              Text('Mechanical bench', style: Brass.label(28, weight: FontWeight.w700)),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1,
                child: MechanicalHousing(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const GearAssembly(),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FlipDigit(value: '$h12', height: 96),
                            const FlipColon(height: 96),
                            FlipDigit(value: _two(_now.minute), height: 96),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              MechanicalSlider(
                value: _slider,
                onChanged: (v) => setState(() => _slider = v),
                semanticValue: '${(_slider * 24).round()} hours',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MechanicalButton(
                    semanticLabel: 'Test button',
                    size: 64,
                    onPressed: () {},
                    child: const Icon(Icons.play_arrow_rounded),
                  ),
                  MechanicalButton(
                    semanticLabel: 'Lit button',
                    size: 64,
                    glow: true,
                    onPressed: () {},
                    child: const Icon(Icons.alarm),
                  ),
                  RotaryCrown(
                    onStep: (steps, speed) => setState(
                        () => _crown = (_crown + steps * (speed > 600 ? 5 : 1)).clamp(0, 999).toInt()),
                  ),
                ],
              ),
              Center(child: Text('Crown: $_crown min', style: Brass.label(20))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ToggleLever(
                    key: ValueKey('snooze$_lever'),
                    engagedAtTop: true,
                    semanticLabel: 'Snooze lever',
                    icon: const Icon(Icons.snooze),
                    width: 110,
                    height: 190,
                    onEngaged: () => setState(() => _lever = 'snooze'),
                  ),
                  ToggleLever(
                    key: ValueKey('stop$_lever'),
                    engagedAtTop: false,
                    semanticLabel: 'Stop lever',
                    icon: const Icon(Icons.stop_rounded),
                    width: 110,
                    height: 190,
                    onEngaged: () => setState(() => _lever = 'stop'),
                  ),
                ],
              ),
              Center(child: Text('Lever engaged: $_lever', style: Brass.label(20))),
              TextButton(
                onPressed: () => setState(() => _lever = 'reset${DateTime.now().millisecond}'),
                child: Text('Reset levers', style: Brass.label(18, color: Brass.amber)),
              ),
              const SizedBox(height: 12),
              Center(
                child: MechanicalDial(
                  index: _dial,
                  count: 6,
                  semanticLabel: 'Snooze minutes dial',
                  onChanged: (i) {
                    setState(() => _dial = i);
                    _settings.setSnoozeMinutes(const [5, 10, 15, 20, 30, 45][i]);
                  },
                ),
              ),
              Center(
                  child: Text('Snooze: ${_settings.snoozeMinutes} min',
                      style: Brass.label(20))),
              const SizedBox(height: 16),
              _switch('Interface sounds', _settings.interfaceSounds, _settings.setInterfaceSounds),
              _switch('Alarm sounds', _settings.alarmSounds, _settings.setAlarmSounds),
              _switch('Haptic feedback', _settings.haptics, _settings.setHaptics),
              _switch('Gear ambience', _settings.gearAmbience, _settings.setGearAmbience),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch(String label, bool v, ValueChanged<bool> on) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: Brass.label(20)),
        activeColor: Brass.amber,
        value: v,
        onChanged: on,
      );
}
