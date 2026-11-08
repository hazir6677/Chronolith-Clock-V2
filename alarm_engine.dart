import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/clock_models.dart';

class RingingStatus {
  final bool isRinging;
  final String id;
  final String label;
  const RingingStatus(this.isRinging, this.id, this.label);
}

class RingtoneChoice {
  final String uri;
  final String title;
  const RingtoneChoice(this.uri, this.title);
}

/// Bridge to the native Android alarm engine (AlarmManager + foreground service).
/// Every call is safe to make on platforms without the native side.
class AlarmEngine {
  static const MethodChannel _ch = MethodChannel('dev.chronolith.app/alarm');
  static const String bedtimeId = '__bedtime__';

  static Future<T?> _call<T>(String method, [dynamic args]) async {
    try {
      return await _ch.invokeMethod<T>(method, args);
    } catch (_) {
      return null;
    }
  }

  /// Sends the full alarm list (plus the bedtime reminder) to the native scheduler.
  static Future<void> sync(
    List<AlarmItem> alarms,
    BedtimeReminder bedtime,
  ) async {
    final list = <Map<String, dynamic>>[
      for (final a in alarms)
        {
          'id': a.id,
          'hour': a.time.hour,
          'minute': a.time.minute,
          'days': a.isoDays,
          'enabled': a.isEnabled,
          'label': a.label,
          'kind': 'alarm',
          'ringtoneUri': a.ringtoneUri ?? '',
        },
      {
        'id': bedtimeId,
        'hour': bedtime.time.hour,
        'minute': bedtime.time.minute,
        'days': <int>[1, 2, 3, 4, 5, 6, 7],
        'enabled': bedtime.enabled,
        'label': 'Bedtime reminder',
        'kind': 'reminder',
        'ringtoneUri': '',
      },
    ];
    await _call<bool>('syncAlarms', jsonEncode(list));
  }

  static Future<RingtoneChoice?> pickRingtone(String? currentUri) async {
    final r = await _call<Map<dynamic, dynamic>>(
      'pickRingtone',
      {'currentUri': currentUri ?? ''},
    );
    if (r == null) return null;
    return RingtoneChoice(
      (r['uri'] as String?) ?? '',
      (r['title'] as String?) ?? 'Custom sound',
    );
  }

  static Future<void> scheduleTimer(DateTime endsAt) =>
      _call<bool>('scheduleTimer', {
        'triggerAtMillis': endsAt.millisecondsSinceEpoch,
      });

  static Future<void> cancelTimer() => _call<bool>('cancelTimer');

  static Future<RingingStatus?> ringingStatus() async {
    final r = await _call<Map<dynamic, dynamic>>('getRingingStatus');
    if (r == null) return null;
    return RingingStatus(
      r['isRinging'] == true,
      (r['id'] as String?) ?? '',
      (r['label'] as String?) ?? '',
    );
  }

  static Future<void> stopRinging() => _call<bool>('stopRinging');
  static Future<void> snoozeRinging() => _call<bool>('snoozeRinging');

  static Future<List<String>> consumeFiredOneShots() async {
    final r = await _call<List<dynamic>>('consumeFiredOneShots');
    return r == null ? <String>[] : r.map((e) => e.toString()).toList();
  }

  /// Returns null when the native side is unavailable.
  static Future<Map<String, bool>?> permissionStatus() async {
    final r = await _call<Map<dynamic, dynamic>>('getPermissionStatus');
    if (r == null) return null;
    return {
      'notifications': r['notifications'] == true,
      'exactAlarms': r['exactAlarms'] == true,
    };
  }

  static Future<void> openExactAlarmSettings() =>
      _call<bool>('openExactAlarmSettings');
}

/// Local persistence so alarms, bedtime reminder and cities survive restarts.
class Persistence {
  static const _alarmsKey = 'alarms_v1';
  static const _bedtimeKey = 'bedtime_v1';
  static const _citiesKey = 'world_cities_v1';

  static Future<List<AlarmItem>?> loadAlarms() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_alarmsKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => AlarmItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAlarms(List<AlarmItem> alarms) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _alarmsKey, jsonEncode(alarms.map((a) => a.toJson()).toList()));
    } catch (_) {}
  }

  static Future<BedtimeReminder> loadBedtime() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_bedtimeKey);
      if (raw == null) return const BedtimeReminder();
      return BedtimeReminder.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return const BedtimeReminder();
    }
  }

  static Future<void> saveBedtime(BedtimeReminder b) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_bedtimeKey, jsonEncode(b.toJson()));
    } catch (_) {}
  }

  static Future<List<String>?> loadCityIds() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getStringList(_citiesKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCityIds(List<String> ids) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setStringList(_citiesKey, ids);
    } catch (_) {}
  }
}
