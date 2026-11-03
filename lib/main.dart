import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/clock_models.dart';
import 'screens/alarm_tab.dart';
import 'screens/clock_tab.dart';
import 'screens/stopwatch_tab.dart';
import 'screens/timer_tab.dart';
import 'screens/world_clock_tab.dart';
import 'theme/chronolith_theme.dart';
import 'widgets/bottom_nav_pill.dart';
import 'widgets/organic_shapes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ChronolithApp());
}

class ChronolithApp extends StatefulWidget {
  const ChronolithApp({super.key});

  @override
  State<ChronolithApp> createState() => _ChronolithAppState();
}

class _ChronolithAppState extends State<ChronolithApp> {
  bool _useDynamicColors = false;
  bool _useDarkNocturne = false;
  bool _use24HourFormat = false;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final activeDynamic =
            _useDarkNocturne ? darkDynamic : lightDynamic;

        final ChronolithPalette palette;
        if (_useDynamicColors && activeDynamic != null) {
          palette = ChronolithPalette.fromDynamicScheme(activeDynamic);
        } else if (_useDarkNocturne) {
          palette = ChronolithPalette.deepNocturne;
        } else {
          palette = ChronolithPalette.dreamyLavender;
        }

        return MaterialApp(
          title: 'Chronolith',
          debugShowCheckedModeBanner: false,
          theme: ChronolithTheme.buildTheme(
            palette,
            dynamicScheme: _useDynamicColors ? activeDynamic : null,
          ),
          home: ChronolithDashboard(
            palette: palette,
            useDynamicColors: _useDynamicColors,
            hasSystemDynamicSupport: lightDynamic != null,
            useDarkNocturne: _useDarkNocturne,
            use24HourFormat: _use24HourFormat,
            onToggleDynamicColors: (val) =>
                setState(() => _useDynamicColors = val),
            onToggleDarkNocturne: (val) =>
                setState(() => _useDarkNocturne = val),
            onToggle24Hour: (val) =>
                setState(() => _use24HourFormat = val),
          ),
        );
      },
    );
  }
}

class ChronolithDashboard extends StatefulWidget {
  final ChronolithPalette palette;
  final bool useDynamicColors;
  final bool hasSystemDynamicSupport;
  final bool useDarkNocturne;
  final bool use24HourFormat;
  final ValueChanged<bool> onToggleDynamicColors;
  final ValueChanged<bool> onToggleDarkNocturne;
  final ValueChanged<bool> onToggle24Hour;

  const ChronolithDashboard({
    super.key,
    required this.palette,
    required this.useDynamicColors,
    required this.hasSystemDynamicSupport,
    required this.useDarkNocturne,
    required this.use24HourFormat,
    required this.onToggleDynamicColors,
    required this.onToggleDarkNocturne,
    required this.onToggle24Hour,
  });

  @override
  State<ChronolithDashboard> createState() => _ChronolithDashboardState();
}

class _ChronolithDashboardState extends State<ChronolithDashboard> {
  int _selectedTabIndex = 0;
  late DateTime _now;
  Timer? _clockTimer;
  bool _showBedtimeReminder = true;

  // Initial alarms matching the Chronolith Dreamy Alarm Dashboard mockup
  late List<AlarmItem> _alarms;
  late List<WorldCity> _worldCities;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });

    _alarms = [
      const AlarmItem(
        id: 'wake_up',
        time: TimeOfDay(hour: 7, minute: 0),
        label: 'Wake up',
        days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
        isEnabled: true,
        tone: AlarmCardTone.lavender,
        iconType: AlarmIconType.sun,
      ),
      const AlarmItem(
        id: 'gym',
        time: TimeOfDay(hour: 10, minute: 30),
        label: 'Gym',
        days: ['Mon', 'Wed', 'Fri'],
        isEnabled: false,
        tone: AlarmCardTone.rose,
        iconType: AlarmIconType.gym,
      ),
      const AlarmItem(
        id: 'sleep',
        time: TimeOfDay(hour: 22, minute: 0),
        label: 'Sleep',
        days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        isEnabled: true,
        tone: AlarmCardTone.lavender,
        iconType: AlarmIconType.moon,
      ),
    ];

    _worldCities = const [
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
    ];
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _toggleAlarm(String id) {
    setState(() {
      _alarms = _alarms.map((a) {
        if (a.id == id) {
          return a.copyWith(isEnabled: !a.isEnabled);
        }
        return a;
      }).toList();
    });
  }

  void _addOrUpdateAlarm(AlarmItem item) {
    setState(() {
      final idx = _alarms.indexWhere((a) => a.id == item.id);
      if (idx >= 0) {
        _alarms[idx] = item;
      } else {
        _alarms.add(item);
      }
    });
  }

  void _deleteAlarm(String id) {
    setState(() {
      _alarms.removeWhere((a) => a.id == id);
    });
  }

  void _openThemeSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.palette.cardLavenderSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Material 3 Expressive Appearance',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: widget.palette.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Switch between the signature Chronolith Dreamy Lavender mockup palette, Material You wallpaper colors, or Nocturne dark mode.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: widget.palette.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Material You Dynamic System Colors',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: widget.palette.inkPrimary,
                  ),
                ),
                subtitle: Text(
                  widget.hasSystemDynamicSupport
                      ? 'Harmonize with your Android 12+ wallpaper'
                      : 'Uses expressive M3 seed fallback on devices without wallpaper colors',
                  style: TextStyle(color: widget.palette.inkSecondary),
                ),
                value: widget.useDynamicColors,
                onChanged: (v) {
                  widget.onToggleDynamicColors(v);
                  Navigator.of(ctx).pop();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Deep Plum Nocturne Mode',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: widget.palette.inkPrimary,
                  ),
                ),
                subtitle: Text(
                  'Low-glare dark plum surfaces for nighttime comfort',
                  style: TextStyle(color: widget.palette.inkSecondary),
                ),
                value: widget.useDarkNocturne,
                onChanged: (v) {
                  widget.onToggleDarkNocturne(v);
                  Navigator.of(ctx).pop();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '24-Hour Time Format',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: widget.palette.inkPrimary,
                  ),
                ),
                subtitle: Text(
                  'Display 24-hour military clock across all 5 tabs',
                  style: TextStyle(color: widget.palette.inkSecondary),
                ),
                value: widget.use24HourFormat,
                onChanged: (v) {
                  widget.onToggle24Hour(v);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;

    final tabs = [
      AlarmTab(
        now: _now,
        palette: palette,
        use24HourFormat: widget.use24HourFormat,
        alarms: _alarms,
        showBedtimeReminder: _showBedtimeReminder,
        onToggleAlarm: _toggleAlarm,
        onAddOrUpdateAlarm: _addOrUpdateAlarm,
        onDeleteAlarm: _deleteAlarm,
        onDismissBedtimeReminder: () =>
            setState(() => _showBedtimeReminder = false),
        onRestoreBedtimeReminder: () =>
            setState(() => _showBedtimeReminder = true),
      ),
      ClockTab(
        now: _now,
        palette: palette,
        use24HourFormat: widget.use24HourFormat,
      ),
      WorldClockTab(
        now: _now,
        palette: palette,
        use24HourFormat: widget.use24HourFormat,
        cities: _worldCities,
        onAddCity: (city) => setState(() => _worldCities = [..._worldCities, city]),
        onRemoveCity: (id) => setState(
          () => _worldCities = _worldCities.where((c) => c.id != id).toList(),
        ),
      ),
      TimerTab(palette: palette),
      StopwatchTab(palette: palette),
    ];

    return Scaffold(
      backgroundColor: palette.scaffoldBackground,
      body: CustomPaint(
        painter: DreamyBackgroundPainter(palette: palette),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Brand Header matching mockup: "Chronolith" + "TIME FOR A BRIGHTER YOU"
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 18, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chronolith',
                          style: GoogleFonts.fredoka(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: palette.inkPrimary,
                            height: 0.96,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'TIME FOR A BRIGHTER YOU',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 3.1,
                              color: palette.inkSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Circular 3-dot menu button matching mockup
                        Material(
                          color: palette.backgroundBlob.withOpacity(0.85),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _openThemeSettingsModal,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.more_vert_rounded,
                                size: 22,
                                color: palette.inkPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Circular sunset mountain avatar matching mockup
                        GestureDetector(
                          onTap: _openThemeSettingsModal,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.cardLavenderPill,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.heroBackground.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CustomPaint(
                              painter: MountainSunsetPainter(),
                              child: Image.asset(
                                'assets/images/avatar_sunset.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main Tab Content
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: tabs,
                ),
              ),

              // Floating Pill Bottom Navigation Bar (5 Tabs)
              SafeArea(
                top: false,
                child: ChronolithBottomNavPill(
                  currentIndex: _selectedTabIndex,
                  onTap: (idx) => setState(() => _selectedTabIndex = idx),
                  palette: palette,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
