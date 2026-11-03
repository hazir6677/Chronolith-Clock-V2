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

  const AlarmItem({
    required this.id,
    required this.time,
    required this.label,
    required this.days,
    required this.isEnabled,
    this.tone = AlarmCardTone.lavender,
    this.iconType = AlarmIconType.sun,
  });

  AlarmItem copyWith({
    String? id,
    TimeOfDay? time,
    String? label,
    List<String>? days,
    bool? isEnabled,
    AlarmCardTone? tone,
    AlarmIconType? iconType,
  }) {
    return AlarmItem(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
      tone: tone ?? this.tone,
      iconType: iconType ?? this.iconType,
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
  final String id;
  final String city;
  final String country;
  final double utcOffsetHours;
  final AlarmCardTone tone;

  const WorldCity({
    required this.id,
    required this.city,
    required this.country,
    required this.utcOffsetHours,
    this.tone = AlarmCardTone.lavender,
  });
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
