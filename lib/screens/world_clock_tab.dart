import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
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

  /// Every IANA time zone in the bundled database (~400), sorted by city name.
  static List<WorldCity>? _allZonesCache;

  static List<WorldCity> get _allZones {
    return _allZonesCache ??= () {
      const skipPrefixes = ['Etc/', 'SystemV/'];
      final ids = tz.timeZoneDatabase.locations.keys.where((id) {
        if (id == 'UTC') return true;
        if (!id.contains('/')) return false;
        return !skipPrefixes.any(id.startsWith);
      }).toList();
      final zones = [
        for (var i = 0; i < ids.length; i++)
          WorldCity.fromTzId(ids[i], seed: i),
      ]..sort((a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()));
      return zones;
    }();
  }

  tz.Location _loc(WorldCity city) {
    try {
      return tz.getLocation(city.tzId);
    } catch (_) {
      return tz.UTC;
    }
  }

  DateTime _cityTime(WorldCity city) {
    final instant = widget.now.toUtc().add(
          Duration(minutes: (_scrubHoursOffset * 60).round()),
        );
    return tz.TZDateTime.from(instant, _loc(city));
  }

  String _formatOffset(Duration d) {
    final totalMin = d.inMinutes;
    final sign = totalMin < 0 ? '-' : '+';
    final abs = totalMin.abs();
    final h = abs ~/ 60;
    final m = abs % 60;
    return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
  }

  String _relativeOffsetLabel(WorldCity city) {
    final cityOffset = tz.TZDateTime.now(_loc(city)).timeZoneOffset;
    final diffMin =
        cityOffset.inMinutes - widget.now.timeZoneOffset.inMinutes;
    if (diffMin == 0) return 'Same time as local';
    final sign = diffMin > 0 ? '+' : '-';
    final abs = diffMin.abs();
    final hrs = abs ~/ 60;
    final mins = abs % 60;
    if (mins == 0) return '$sign${hrs}h from local';
    return '$sign${hrs}h ${mins}m from local';
  }

  void _openAddCitySheet(BuildContext context) {
    final existingIds = widget.cities.map((c) => c.id).toSet();
    final all = _allZones.where((c) => !existingIds.contains(c.id)).toList();
    String query = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.palette.cardLavenderSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final q = query.trim().toLowerCase();
            final filtered = q.isEmpty
                ? all
                : all
                    .where((c) =>
                        c.city.toLowerCase().contains(q) ||
                        c.region.toLowerCase().contains(q) ||
                        c.id.toLowerCase().contains(q))
                    .toList();
            return Padding(
              padding: EdgeInsets.only(
                left: 22,
                right: 22,
                top: 22,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.8,
                child: Column(
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
                    const SizedBox(height: 10),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setSheetState(() => query = v),
                      style: TextStyle(color: widget.palette.inkPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search ${all.length} time zones',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: widget.palette.cardLavenderPill,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No matching time zones',
                                style: TextStyle(
                                    color: widget.palette.inkSecondary),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (_, idx) {
                                final city = filtered[idx];
                                final offset =
                                    tz.TZDateTime.now(_loc(city)).timeZoneOffset;
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
                                    '${city.region} (${_formatOffset(offset)})',
                                    style: TextStyle(
                                        color: widget.palette.inkSecondary),
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
              ),
            );
          },
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
                              '${city.region} • ${_relativeOffsetLabel(city)}',
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
