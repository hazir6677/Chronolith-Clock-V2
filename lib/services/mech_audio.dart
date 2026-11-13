import 'package:flutter/services.dart';

import 'settings.dart';

/// Interface sounds. Names match the samples in android res/raw.
enum Sfx {
  buttonClick('button_click'),
  crownTick('crown_tick'),
  leverClack('lever_clack'),
  flip('flip'),
  timerComplete('timer_complete');

  const Sfx(this.asset);
  final String asset;
}

enum Haptic { light, medium, heavy, tick }

/// One place for every mechanical sound and haptic pulse, so the three
/// feedback settings are honored everywhere.
class MechAudio {
  MechAudio._();

  static const MethodChannel _ch = MethodChannel('dev.chronolith.app/sound');
  static final Map<Sfx, int> _last = {};
  static bool _ambienceOn = false;

  /// Plays a sample, ignoring repeats closer together than [minGapMs].
  static void play(Sfx sfx,
      {double volume = 1.0, double rate = 1.0, int minGapMs = 25}) {
    if (!ChronolithSettings.instance.interfaceSounds) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - (_last[sfx] ?? 0) < minGapMs) return;
    _last[sfx] = now;
    _invoke('play', {'name': sfx.asset, 'volume': volume, 'rate': rate});
  }

  static void haptic(Haptic h) {
    if (!ChronolithSettings.instance.haptics) return;
    switch (h) {
      case Haptic.light:
        HapticFeedback.lightImpact();
      case Haptic.medium:
        HapticFeedback.mediumImpact();
      case Haptic.heavy:
        HapticFeedback.heavyImpact();
      case Haptic.tick:
        HapticFeedback.selectionClick();
    }
  }

  /// Quiet gear loop. Only runs when the setting is on and a screen asks for it.
  static void setAmbience(bool visible) {
    final want = visible &&
        ChronolithSettings.instance.interfaceSounds &&
        ChronolithSettings.instance.gearAmbience;
    if (want == _ambienceOn) return;
    _ambienceOn = want;
    _invoke(want ? 'startAmbience' : 'stopAmbience', {'volume': 0.22});
  }

  static Future<void> _invoke(String method, [Object? args]) async {
    try {
      await _ch.invokeMethod<void>(method, args);
    } catch (_) {
      // Native side unavailable (tests, desktop): stay silent.
    }
  }
}
