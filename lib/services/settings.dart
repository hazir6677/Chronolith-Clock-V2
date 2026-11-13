import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-facing feedback and behaviour settings. Interface sounds, alarm sounds
/// and haptics are independent switches.
///
/// Keys are stored through shared_preferences, so the native alarm service can
/// read the same values (they live under the "flutter." prefix on Android).
class ChronolithSettings extends ChangeNotifier {
  ChronolithSettings._();
  static final ChronolithSettings instance = ChronolithSettings._();

  bool _interfaceSounds = true;
  bool _alarmSounds = true;
  bool _haptics = true;
  bool _gearAmbience = false;
  int _snoozeMinutes = 10;

  bool get interfaceSounds => _interfaceSounds;
  bool get alarmSounds => _alarmSounds;
  bool get haptics => _haptics;
  bool get gearAmbience => _gearAmbience;
  int get snoozeMinutes => _snoozeMinutes;

  static const _kInterface = 'set_interface_sounds';
  static const _kAlarm = 'set_alarm_sounds';
  static const _kHaptics = 'set_haptics';
  static const _kAmbience = 'set_gear_ambience';
  static const _kSnooze = 'set_snooze_minutes';

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _interfaceSounds = p.getBool(_kInterface) ?? true;
      _alarmSounds = p.getBool(_kAlarm) ?? true;
      _haptics = p.getBool(_kHaptics) ?? true;
      _gearAmbience = p.getBool(_kAmbience) ?? false;
      _snoozeMinutes = (p.getInt(_kSnooze) ?? 10).clamp(1, 60);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveBool(String k, bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(k, v);
    } catch (_) {}
  }

  void setInterfaceSounds(bool v) {
    _interfaceSounds = v;
    notifyListeners();
    _saveBool(_kInterface, v);
  }

  void setAlarmSounds(bool v) {
    _alarmSounds = v;
    notifyListeners();
    _saveBool(_kAlarm, v);
  }

  void setHaptics(bool v) {
    _haptics = v;
    notifyListeners();
    _saveBool(_kHaptics, v);
  }

  void setGearAmbience(bool v) {
    _gearAmbience = v;
    notifyListeners();
    _saveBool(_kAmbience, v);
  }

  Future<void> setSnoozeMinutes(int minutes) async {
    _snoozeMinutes = minutes.clamp(1, 60);
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt(_kSnooze, _snoozeMinutes);
    } catch (_) {}
  }
}
