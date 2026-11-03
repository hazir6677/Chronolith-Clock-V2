import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clock_models.dart';
import '../theme/chronolith_theme.dart';
import '../widgets/hero_clock_card.dart';
import '../widgets/organic_shapes.dart';

class AlarmTab extends StatelessWidget {
  final DateTime now;
  final ChronolithPalette palette;
  final bool use24HourFormat;
  final List<AlarmItem> alarms;
  final bool showBedtimeReminder;
  final ValueChanged<String> onToggleAlarm;
  final ValueChanged<AlarmItem> onAddOrUpdateAlarm;
  final ValueChanged<String> onDeleteAlarm;
  final VoidCallback onDismissBedtimeReminder;
  final VoidCallback onRestoreBedtimeReminder;

  const AlarmTab({
    super.key,
    required this.now,
    required this.palette,
    required this.use24HourFormat,
    required this.alarms,
    required this.showBedtimeReminder,
    required this.onToggleAlarm,
    required this.onAddOrUpdateAlarm,
    required this.onDeleteAlarm,
    required this.onDismissBedtimeReminder,
    required this.onRestoreBedtimeReminder,
  });

  IconData _iconForType(AlarmIconType type) {
    switch (type) {
      case AlarmIconType.sun:
        return Icons.wb_sunny_rounded;
      case AlarmIconType.gym:
        return Icons.fitness_center_rounded;
      case AlarmIconType.moon:
        return Icons.nightlight_round;
      case AlarmIconType.coffee:
        return Icons.coffee_rounded;
      case AlarmIconType.book:
        return Icons.menu_book_rounded;
      case AlarmIconType.flight:
        return Icons.flight_takeoff_rounded;
    }
  }

  void _openAlarmEditor(BuildContext context, {AlarmItem? existing}) {
    TimeOfDay selectedTime =
        existing?.time ?? const TimeOfDay(hour: 6, minute: 30);
    final labelController =
        TextEditingController(text: existing?.label ?? 'Morning Focus');
    final List<String> allDays = const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];
    final Set<String> selectedDays = Set<String>.from(
      existing?.days ?? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    );
    AlarmCardTone selectedTone = existing?.tone ?? AlarmCardTone.lavender;
    AlarmIconType selectedIcon = existing?.iconType ?? AlarmIconType.sun;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.cardLavenderSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: palette.inkSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existing == null ? 'New Alarm' : 'Edit Alarm',
                        style: GoogleFonts.fredoka(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: palette.inkPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setSheetState(() => selectedTime = picked);
                          }
                        },
                        icon: Icon(Icons.access_time_filled_rounded,
                            color: palette.inkPrimary),
                        label: Text(
                          selectedTime.format(ctx),
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: palette.inkPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: labelController,
                    style: TextStyle(
                      color: palette.inkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Alarm label',
                      filled: true,
                      fillColor: palette.cardLavenderPill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Repeat days',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: palette.inkPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allDays.map((day) {
                      final active = selectedDays.contains(day);
                      return FilterChip(
                        selected: active,
                        label: Text(day),
                        selectedColor: palette.accentPill,
                        backgroundColor: palette.cardLavenderPill,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: active
                              ? palette.accentPillForeground
                              : palette.inkSecondary,
                        ),
                        onSelected: (val) {
                          setSheetState(() {
                            if (val) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Icon',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: palette.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: AlarmIconType.values.map((iconType) {
                                final isSelected = selectedIcon == iconType;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () => setSheetState(
                                      () => selectedIcon = iconType),
                                  child: Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? palette.heroBackground
                                          : palette.cardLavenderPill,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _iconForType(iconType),
                                      size: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : palette.inkPrimary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Card tone',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: palette.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Lavender'),
                                selected:
                                    selectedTone == AlarmCardTone.lavender,
                                onSelected: (_) => setSheetState(() =>
                                    selectedTone = AlarmCardTone.lavender),
                              ),
                              const SizedBox(width: 6),
                              ChoiceChip(
                                label: const Text('Rose'),
                                selected: selectedTone == AlarmCardTone.rose,
                                onSelected: (_) => setSheetState(
                                    () => selectedTone = AlarmCardTone.rose),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.heroBackground,
                        foregroundColor: palette.heroTextPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        final orderedDays = allDays
                            .where((d) => selectedDays.contains(d))
                            .toList();
                        final item = AlarmItem(
                          id: existing?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          time: selectedTime,
                          label: labelController.text.trim().isEmpty
                              ? 'Alarm'
                              : labelController.text.trim(),
                          days: orderedDays,
                          isEnabled: existing?.isEnabled ?? true,
                          tone: selectedTone,
                          iconType: selectedIcon,
                        );
                        onAddOrUpdateAlarm(item);
                        Navigator.of(ctx).pop();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        existing == null ? 'Create Alarm' : 'Save Changes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      children: [
        HeroClockCard(
          now: now,
          palette: palette,
          use24HourFormat: use24HourFormat,
        ),
        const SizedBox(height: 20),

        // Section Header: "Your alarms" + "+ Add alarm" pill button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your alarms',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: palette.inkPrimary,
              ),
            ),
            Material(
              color: palette.accentPill,
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => _openAlarmEditor(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: palette.accentPillForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add alarm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: palette.accentPillForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Alarm Cards List
        ...List.generate(alarms.length, (index) {
          final alarm = alarms[index];
          final isRose = alarm.tone == AlarmCardTone.rose;
          final baseColor =
              isRose ? palette.cardRoseSurface : palette.cardLavenderSurface;
          final pillColor =
              isRose ? palette.cardRosePill : palette.cardLavenderPill;
          final waveColor =
              isRose ? palette.cardRoseWave : palette.cardLavenderWave;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 92,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: palette.heroBackground.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: CustomPaint(
                painter: CardOrganicBlobPainter(
                  pillColor: pillColor,
                  waveColor: waveColor,
                  variant: index,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 6),
                  child: Row(
                    children: [
                      // Left Time Column (e.g., "7:00 AM")
                      SizedBox(
                        width: 125,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                use24HourFormat
                                    ? '${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}'
                                    : alarm.formattedHourMinute,
                                style: GoogleFonts.fredoka(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: palette.inkPrimary,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              if (!use24HourFormat) ...[
                                const SizedBox(width: 4),
                                Text(
                                  alarm.periodLabel,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: palette.inkPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Middle Icon + Label + Days
                      Icon(
                        _iconForType(alarm.iconType),
                        size: 26,
                        color: palette.inkPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _openAlarmEditor(context, existing: alarm),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alarm.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: palette.inkPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                alarm.daysSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: palette.inkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Right Expressive Switch + 3-dot Menu
                      ChronolithSwitch(
                        value: alarm.isEnabled,
                        onChanged: (_) => onToggleAlarm(alarm.id),
                        palette: palette,
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: palette.inkPrimary,
                          size: 22,
                        ),
                        onSelected: (action) {
                          if (action == 'edit') {
                            _openAlarmEditor(context, existing: alarm);
                          } else if (action == 'delete') {
                            onDeleteAlarm(alarm.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit alarm'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete alarm'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 4),

        // Bedtime reminder banner matching the bottom card in the mockup
        if (showBedtimeReminder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: palette.heroBackground,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: palette.heroBackground.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: palette.heroWavePrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(26),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Icon(
                    Icons.bed_rounded,
                    color: palette.heroTextSecondary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bedtime reminder',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: palette.heroTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "It's 30 minutes before your sleep time.",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: palette.heroTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  color: palette.accentPill,
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onDismissBedtimeReminder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      child: Text(
                        'Dismiss',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: palette.accentPillForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRestoreBedtimeReminder,
              icon: Icon(Icons.bedtime_outlined,
                  size: 18, color: palette.inkSecondary),
              label: Text(
                'Show bedtime reminder',
                style: TextStyle(color: palette.inkSecondary),
              ),
            ),
          ),
      ],
    );
  }
}
