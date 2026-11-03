import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/clock_models.dart';
import '../theme/chronolith_theme.dart';
import '../widgets/organic_shapes.dart';

/// Tab 3: World Clock with Interactive Global Time Scrubber, Day/Night indicators,
/// organic pastel city cards, and a searchable global city directory.
class WorldClockTab extends StatefulWidget {
  final DateTime now;
  final ChronolithPalette palette;
  final bool use24HourFormat;
  final List<WorldCity> cities;
  final ValueChanged<WorldCity> onAddCity;
  final ValueChanged<String> onRemoveCity;

  const WorldClockTab({
    super.key,
    required this.now,
    required this.palette,
    required this.use24HourFormat,
    required this.cities,
    required this.onAddCity,
    required this.onRemoveCity,
  });

  @override
  State<WorldClockTab> createState() => _WorldClockTabState();
}

class _WorldClockTabState extends State<WorldClockTab> {
  double _scrubHoursOffset = 0.0;

  static const List<WorldCity> _directory = [
    WorldCity(
      id: 'tokyo',
      city: 'Tokyo',
      country: 'Japan',
      utcOffsetHours: 9.0,
      tone: AlarmCardTone.lavender,
    ),
    WorldCity(
      id: 'london',
      city: 'London',
      country: 'United Kingdom',
      utcOffsetHours: 0.0,
      tone: AlarmCardTone.rose,
    ),
    WorldCity(
      id: 'new_york',
      city: 'New York',
      country: 'United States',
      utcOffsetHours: -4.0,
      tone: AlarmCardTone.lavender,
    ),
    WorldCity(
      id: 'sydney',
      city: 'Sydney',
      country: 'Australia',
      utcOffsetHours: 10.0,
      tone: AlarmCardTone.rose,
    ),
    WorldCity(
      id: 'paris',
      city: 'Paris',
      country: 'France',
      utcOffsetHours: 1.0,
      tone: AlarmCardTone.lavender,
    ),
    WorldCity(
      id: 'dubai',
      city: 'Dubai',
      country: 'United Arab Emirates',
      utcOffsetHours: 4.0,
      tone: AlarmCardTone.rose,
    ),
    WorldCity(
      id: 'singapore',
      city: 'Singapore',
      country: 'Singapore',
      utcOffsetHours: 8.0,
      tone: AlarmCardTone.lavender,
    ),
    WorldCity(
      id: 'san_francisco',
      city: 'San Francisco',
      country: 'United States',
      utcOffsetHours: -7.0,
      tone: AlarmCardTone.rose,
    ),
    WorldCity(
      id: 'seoul',
      city: 'Seoul',
      country: 'South Korea',
      utcOffsetHours: 9.0,
      tone: AlarmCardTone.lavender,
    ),
    WorldCity(
      id: 'zurich',
      city: 'Zurich',
      country: 'Switzerland',
      utcOffsetHours: 1.0,
      tone: AlarmCardTone.rose,
    ),
  ];

  DateTime _cityTime(WorldCity city) {
    final utcNow = widget.now.toUtc().add(
          Duration(minutes: (_scrubHoursOffset * 60).round()),
        );
    return utcNow.add(
      Duration(minutes: (city.utcOffsetHours * 60).round()),
    );
  }

  String _relativeOffsetLabel(WorldCity city) {
    final localOffsetHours = widget.now.timeZoneOffset.inMinutes / 60.0;
    final diff = city.utcOffsetHours - localOffsetHours;
    if (diff == 0) return 'Same time as local';
    final sign = diff > 0 ? '+' : '-';
    final absDiff = diff.abs();
    final hrs = absDiff.floor();
    final mins = ((absDiff - hrs) * 60).round();
    if (mins == 0) return '$sign${hrs}h from local';
    return '$sign${hrs}h ${mins}m from local';
  }

  void _openAddCitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.palette.cardLavenderSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        final existingIds = widget.cities.map((c) => c.id).toSet();
        final available =
            _directory.where((c) => !existingIds.contains(c.id)).toList();

        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add World City',
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: widget.palette.inkPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'All featured cities are already on your dashboard!',
                    style: TextStyle(color: widget.palette.inkSecondary),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: available.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) {
                      final city = available[idx];
                      return ListTile(
                        tileColor: widget.palette.cardLavenderPill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        leading: Icon(
                          Icons.public_rounded,
                          color: widget.palette.inkPrimary,
                        ),
                        title: Text(
                          city.city,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: widget.palette.inkPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${city.country} (UTC${city.utcOffsetHours >= 0 ? '+' : ''}${city.utcOffsetHours})',
                          style: TextStyle(color: widget.palette.inkSecondary),
                        ),
                        trailing: Icon(
                          Icons.add_circle_rounded,
                          color: widget.palette.heroBackground,
                        ),
                        onTap: () {
                          widget.onAddCity(city);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scrubbedLocal = widget.now.add(
      Duration(minutes: (_scrubHoursOffset * 60).round()),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      children: [
        // Top Interactive Time-Scrubber Hero Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: widget.palette.heroBackground,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: widget.palette.heroBackground.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GLOBAL TIME COMPASS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                      color: widget.palette.heroTextSecondary,
                    ),
                  ),
                  if (_scrubHoursOffset != 0)
                    InkWell(
                      onTap: () => setState(() => _scrubHoursOffset = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.palette.accentPill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Reset to Live',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: widget.palette.accentPillForeground,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.use24HourFormat
                        ? DateFormat('HH:mm').format(scrubbedLocal)
                        : DateFormat('h:mm').format(scrubbedLocal),
                    style: GoogleFonts.fredoka(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      color: widget.palette.heroTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.use24HourFormat
                        ? 'LOCAL'
                        : DateFormat('a').format(scrubbedLocal),
                    style: GoogleFonts.fredoka(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: widget.palette.heroTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _scrubHoursOffset == 0
                        ? 'Live Now'
                        : '${_scrubHoursOffset > 0 ? '+' : ''}${_scrubHoursOffset.toStringAsFixed(1)}h',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.palette.accentPill,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: widget.palette.accentPill,
                  inactiveTrackColor: widget.palette.heroWavePrimary,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: _scrubHoursOffset,
                  min: -12.0,
                  max: 12.0,
                  divisions: 48,
                  onChanged: (v) => setState(() => _scrubHoursOffset = v),
                ),
              ),
              Text(
                'Drag slider to preview global meeting hours across all cities',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: widget.palette.heroTextSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Header Row: "World clocks" + "+ Add city" pill button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'World clocks',
              style: GoogleFonts.fredoka(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: widget.palette.inkPrimary,
              ),
            ),
            Material(
              color: widget.palette.accentPill,
              borderRadius: BorderRadius.circular(26),
              child: InkWell(
                borderRadius: BorderRadius.circular(26),
                onTap: () => _openAddCitySheet(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: widget.palette.accentPillForeground,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Add city',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: widget.palette.accentPillForeground,
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

        // World City Cards
        ...List.generate(widget.cities.length, (index) {
          final city = widget.cities[index];
          final cityDt = _cityTime(city);
          final isDaytime = cityDt.hour >= 6 && cityDt.hour < 18;
          final isRose = city.tone == AlarmCardTone.rose;
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
            child: Container(
              height: 92,
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
                  padding: const EdgeInsets.only(left: 16, right: 10),
                  child: Row(
                    children: [
                      // Left Time Capsule
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
                                widget.use24HourFormat
                                    ? DateFormat('HH:mm').format(cityDt)
                                    : DateFormat('h:mm').format(cityDt),
                                style: GoogleFonts.fredoka(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: widget.palette.inkPrimary,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              if (!widget.use24HourFormat) ...[
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('a').format(cityDt),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: widget.palette.inkPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Day / Night Sun or Moon Icon
                      Icon(
                        isDaytime
                            ? Icons.wb_sunny_rounded
                            : Icons.nightlight_round,
                        size: 25,
                        color: widget.palette.inkPrimary,
                      ),
                      const SizedBox(width: 10),

                      // City Name & Offset
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.city,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: widget.palette.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${city.country} • ${_relativeOffsetLabel(city)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: widget.palette.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip: 'Remove city',
                        onPressed: () => widget.onRemoveCity(city.id),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: widget.palette.inkSecondary,
                        ),
                      ),
                    ],
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
