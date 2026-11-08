import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/chronolith_theme.dart';

class NavTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const NavTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

/// Floating rounded-pill bottom navigation bar styled after the Chronolith mockup,
/// supporting all 5 tabs: Alarm, Clock, World, Timer, and Stopwatch.
class ChronolithBottomNavPill extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final ChronolithPalette palette;

  const ChronolithBottomNavPill({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.palette,
  });

  static const List<NavTabItem> tabs = [
    NavTabItem(
      label: 'Alarm',
      icon: Icons.alarm_outlined,
      activeIcon: Icons.alarm_rounded,
    ),
    NavTabItem(
      label: 'Clock',
      icon: Icons.schedule_outlined,
      activeIcon: Icons.watch_later_rounded,
    ),
    NavTabItem(
      label: 'World',
      icon: Icons.language_outlined,
      activeIcon: Icons.language_rounded,
    ),
    NavTabItem(
      label: 'Timer',
      icon: Icons.hourglass_empty_rounded,
      activeIcon: Icons.hourglass_bottom_rounded,
    ),
    NavTabItem(
      label: 'Stopwatch',
      icon: Icons.timer_outlined,
      activeIcon: Icons.timer_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: palette.navBarBackground,
        borderRadius: BorderRadius.circular(42),
        boxShadow: [
          BoxShadow(
            color: palette.heroBackground.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final item = tabs[index];
          final selected = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? palette.navSelectedIndicator
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(34),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? item.activeIcon : item.icon,
                      size: 24,
                      color: selected
                          ? palette.inkPrimary
                          : palette.inkSecondary.withOpacity(0.85),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? palette.inkPrimary
                              : palette.inkSecondary.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
