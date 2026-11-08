import 'package:flutter/material.dart';

enum AlarmCardTone { lavender, rose }

enum AlarmIconType { sun, gym, moon, coffee, book, flight }

class AlarmItem {
  final String id;
  final TimeOfDay time;
  final String label;
  final List<String> days;
  final bool isEnabled;
  final AlarmCardTone tone;
  final AlarmIconType iconType;

  /// Android ringtone URI chosen in the picker. Null = system default alarm sound.
  final String? ringtoneUri;
  final String? ringtoneTitle;

  const AlarmItem({
    required this.id,
    required this.time,
    required this.label,
    required this.days,
    required this.isEnabled,
    this.tone = AlarmCardTone.lavender,
    this.iconType = AlarmIconType.sun,
    this.ringtoneUri,
    this.ringtoneTitle,
  });

  static const List<String> weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  /// Mon=1 .. Sun=7 (matches DateTime.weekday).
  List<int> get isoDays =>
      days.map((d) => weekdayNames.indexOf(d) + 1).where((i) => i > 0).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': time.hour,
        'minute': time.minute,
        'label': label,
        'days': days,
        'isEnabled': isEnabled,
        'tone': tone.name,
        'iconType': iconType.name,
        'ringtoneUri': ringtoneUri,
        'ringtoneTitle': ringtoneTitle,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> j) {
    return AlarmItem(
      id: j['id'] as String,
      time: TimeOfDay(hour: j['hour'] as int, minute: j['minute'] as int),
      label: (j['label'] as String?) ?? 'Alarm',
      days: List<String>.from((j['days'] as List?) ?? const []),
      isEnabled: (j['isEnabled'] as bool?) ?? true,
      tone: AlarmCardTone.values.firstWhere(
        (t) => t.name == j['tone'],
        orElse: () => AlarmCardTone.lavender,
      ),
      iconType: AlarmIconType.values.firstWhere(
        (t) => t.name == j['iconType'],
        orElse: () => AlarmIconType.sun,
      ),
      ringtoneUri: j['ringtoneUri'] as String?,
      ringtoneTitle: j['ringtoneTitle'] as String?,
    );
  }

  AlarmItem copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    List<String>? days,
    bool? isEnabled,
    AlarmCardTone? tone,
    AlarmIconType? iconType,
    String? ringtoneUri,
    String? ringtoneTitle,
    bool clearRingtone = false,
  }) {
    return AlarmItem(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
      tone: tone ?? this.tone,
      iconType: iconType ?? this.iconType,
      ringtoneUri: clearRingtone ? null : (ringtoneUri ?? this.ringtoneUri),
      ringtoneTitle: clearRingtone ? null : (ringtoneTitle ?? this.ringtoneTitle),
    );
  }

  String get formattedHourMinute {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hour12:$minuteStr';
  }

  String get periodLabel => time.period == DayPeriod.am ? 'AM' : 'PM';

  String get daysSummary {
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'One-time alarm';
    return days.join(', ');
  }
}

class WorldCity {
  /// IANA time zone id, e.g. "Asia/Kolkata". Also used as the unique id.
  final String id;
  final String city;
  final String region;
  final AlarmCardTone tone;

  const WorldCity({
    required this.id,
    required this.city,
    required this.region,
    this.tone = AlarmCardTone.lavender,
  });

  String get tzId => id;

  factory WorldCity.fromTzId(String tzId, {AlarmCardTone? tone, int seed = 0}) {
    final parts = tzId.split('/');
    final name = parts.last.replaceAll('_', ' ');
    final region = parts.length > 1
        ? parts.sublist(0, parts.length - 1).join(' / ').replaceAll('_', ' ')
        : 'Universal';
    return WorldCity(
      id: tzId,
      city: name,
      region: region,
      tone: tone ??
          (seed.isEven ? AlarmCardTone.lavender : AlarmCardTone.rose),
    );
  }
}

/// Daily wind-down reminder, delivered as a notification.
class BedtimeReminder {
  final TimeOfDay time;
  final bool enabled;

  const BedtimeReminder({
    this.time = const TimeOfDay(hour: 21, minute: 30),
    this.enabled = false,
  });

  BedtimeReminder copyWith({TimeOfDay? time, bool? enabled}) =>
      BedtimeReminder(time: time ?? this.time, enabled: enabled ?? this.enabled);

  Map<String, dynamic> toJson() =>
      {'hour': time.hour, 'minute': time.minute, 'enabled': enabled};

  factory BedtimeReminder.fromJson(Map<String, dynamic> j) => BedtimeReminder(
        time: TimeOfDay(hour: j['hour'] as int, minute: j['minute'] as int),
        enabled: (j['enabled'] as bool?) ?? false,
      );
}

class TimerPreset {
  final String id;
  final String label;
  final Duration duration;
  final IconData icon;
  final AlarmCardTone tone;

  const TimerPreset({
    required this.id,
    required this.label,
    required this.duration,
    required this.icon,
    this.tone = AlarmCardTone.lavender,
  });
}

class LapRecord {
  final int lapNumber;
  final Duration splitDuration;
  final Duration totalDuration;

  const LapRecord({
    required this.lapNumber,
    required this.splitDuration,
    required this.totalDuration,
  });
}
