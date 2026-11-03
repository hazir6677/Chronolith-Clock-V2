import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 Expressive palette & theme tokens for Chronolith.
/// Combines the signature Dreamy Lavender & Deep Plum palette from the mockup
/// with Android 12+ Material You (`dynamic_color`) harmonization.
class ChronolithPalette {
  final Color scaffoldBackground;
  final Color backgroundBlob;
  final Color heroBackground;
  final Color heroWavePrimary;
  final Color heroWaveSecondary;
  final Color heroTextPrimary;
  final Color heroTextSecondary;
  final Color weatherPillBackground;
  final Color accentPill;
  final Color accentPillForeground;
  final Color cardLavenderSurface;
  final Color cardLavenderPill;
  final Color cardLavenderWave;
  final Color cardRoseSurface;
  final Color cardRosePill;
  final Color cardRoseWave;
  final Color switchActiveTrack;
  final Color switchInactiveTrack;
  final Color navBarBackground;
  final Color navSelectedIndicator;
  final Color inkPrimary;
  final Color inkSecondary;
  final bool isDark;

  const ChronolithPalette({
    required this.scaffoldBackground,
    required this.backgroundBlob,
    required this.heroBackground,
    required this.heroWavePrimary,
    required this.heroWaveSecondary,
    required this.heroTextPrimary,
    required this.heroTextSecondary,
    required this.weatherPillBackground,
    required this.accentPill,
    required this.accentPillForeground,
    required this.cardLavenderSurface,
    required this.cardLavenderPill,
    required this.cardLavenderWave,
    required this.cardRoseSurface,
    required this.cardRosePill,
    required this.cardRoseWave,
    required this.switchActiveTrack,
    required this.switchInactiveTrack,
    required this.navBarBackground,
    required this.navSelectedIndicator,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.isDark,
  });

  /// Exact palette matched to the Chronolith Dreamy Alarm Dashboard mockup.
  static const ChronolithPalette dreamyLavender = ChronolithPalette(
    scaffoldBackground: Color(0xFFD2BEFC),
    backgroundBlob: Color(0xFFC1A6FA),
    heroBackground: Color(0xFF35184C),
    heroWavePrimary: Color(0xFF60378B),
    heroWaveSecondary: Color(0xFFA78BFA),
    heroTextPrimary: Color(0xFFF6EEFF),
    heroTextSecondary: Color(0xFFDCC8FA),
    weatherPillBackground: Color(0xCC7C68A6),
    accentPill: Color(0xFFD49CFA),
    accentPillForeground: Color(0xFF230E36),
    cardLavenderSurface: Color(0xFFE5DAFC),
    cardLavenderPill: Color(0xFFF3EDFF),
    cardLavenderWave: Color(0xFFC4A7FA),
    cardRoseSurface: Color(0xFFF5DCEF),
    cardRosePill: Color(0xFFFCEBF6),
    cardRoseWave: Color(0xFFF0C3DF),
    switchActiveTrack: Color(0xFF472768),
    switchInactiveTrack: Color(0xFFA98FA8),
    navBarBackground: Color(0xFFEAE0FD),
    navSelectedIndicator: Color(0xFFD5B4FA),
    inkPrimary: Color(0xFF230E36),
    inkSecondary: Color(0xFF563C74),
    isDark: false,
  );

  /// Deep Plum Nocturne mode for evening / OLED comfort.
  static const ChronolithPalette deepNocturne = ChronolithPalette(
    scaffoldBackground: Color(0xFF1A0B28),
    backgroundBlob: Color(0xFF26123B),
    heroBackground: Color(0xFF311647),
    heroWavePrimary: Color(0xFF532C7A),
    heroWaveSecondary: Color(0xFF7B4EB0),
    heroTextPrimary: Color(0xFFF7F0FF),
    heroTextSecondary: Color(0xFFD4B9FA),
    weatherPillBackground: Color(0xCC5E4385),
    accentPill: Color(0xFFC78BF8),
    accentPillForeground: Color(0xFF1F0A33),
    cardLavenderSurface: Color(0xFF2A153F),
    cardLavenderPill: Color(0xFF361D50),
    cardLavenderWave: Color(0xFF48266B),
    cardRoseSurface: Color(0xFF35183A),
    cardRosePill: Color(0xFF47214C),
    cardRoseWave: Color(0xFF5E2B63),
    switchActiveTrack: Color(0xFFD49CFA),
    switchInactiveTrack: Color(0xFF5E4870),
    navBarBackground: Color(0xFF28133D),
    navSelectedIndicator: Color(0xFF522B78),
    inkPrimary: Color(0xFFF5ECFF),
    inkSecondary: Color(0xFFC9B0E6),
    isDark: true,
  );

  /// Derives an expressive palette from an Android 12+ Material You dynamic ColorScheme.
  factory ChronolithPalette.fromDynamicScheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    if (isDark) {
      return ChronolithPalette(
        scaffoldBackground: scheme.surface,
        backgroundBlob: scheme.surfaceContainerHighest.withOpacity(0.55),
        heroBackground: scheme.primaryContainer,
        heroWavePrimary: scheme.primary.withOpacity(0.35),
        heroWaveSecondary: scheme.tertiary.withOpacity(0.45),
        heroTextPrimary: scheme.onPrimaryContainer,
        heroTextSecondary: scheme.onPrimaryContainer.withOpacity(0.8),
        weatherPillBackground: scheme.surfaceContainerHigh.withOpacity(0.8),
        accentPill: scheme.primary,
        accentPillForeground: scheme.onPrimary,
        cardLavenderSurface: scheme.surfaceContainerHigh,
        cardLavenderPill: scheme.surfaceContainerHighest,
        cardLavenderWave: scheme.primaryContainer.withOpacity(0.65),
        cardRoseSurface: scheme.tertiaryContainer.withOpacity(0.65),
        cardRosePill: scheme.tertiaryContainer,
        cardRoseWave: scheme.tertiary.withOpacity(0.35),
        switchActiveTrack: scheme.primary,
        switchInactiveTrack: scheme.outline,
        navBarBackground: scheme.surfaceContainerHigh,
        navSelectedIndicator: scheme.primaryContainer,
        inkPrimary: scheme.onSurface,
        inkSecondary: scheme.onSurfaceVariant,
        isDark: true,
      );
    }
    return ChronolithPalette(
      scaffoldBackground: Color.lerp(scheme.primaryContainer, scheme.surface, 0.35)!,
      backgroundBlob: scheme.primaryContainer,
      heroBackground: scheme.onPrimaryContainer,
      heroWavePrimary: scheme.primary.withOpacity(0.55),
      heroWaveSecondary: scheme.tertiary.withOpacity(0.65),
      heroTextPrimary: scheme.surface,
      heroTextSecondary: scheme.primaryContainer,
      weatherPillBackground: scheme.secondary.withOpacity(0.75),
      accentPill: scheme.tertiaryContainer,
      accentPillForeground: scheme.onTertiaryContainer,
      cardLavenderSurface: scheme.surfaceContainerLow,
      cardLavenderPill: scheme.surface,
      cardLavenderWave: scheme.primaryContainer,
      cardRoseSurface: Color.lerp(scheme.tertiaryContainer, scheme.surface, 0.45)!,
      cardRosePill: Color.lerp(scheme.tertiaryContainer, Colors.white, 0.65)!,
      cardRoseWave: scheme.tertiaryContainer,
      switchActiveTrack: scheme.onPrimaryContainer,
      switchInactiveTrack: scheme.outlineVariant,
      navBarBackground: scheme.surfaceContainerLow,
      navSelectedIndicator: scheme.primaryContainer,
      inkPrimary: scheme.onSurface,
      inkSecondary: scheme.onSurfaceVariant,
      isDark: false,
    );
  }
}

class ChronolithTheme {
  static ThemeData buildTheme(ChronolithPalette palette, {ColorScheme? dynamicScheme}) {
    final baseScheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B3FA0),
          brightness: palette.isDark ? Brightness.dark : Brightness.light,
        );

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      scaffoldBackgroundColor: palette.scaffoldBackground,
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.fredoka(
          fontSize: 68,
          fontWeight: FontWeight.w700,
          color: palette.heroTextPrimary,
          height: 0.98,
        ),
        displayMedium: GoogleFonts.fredoka(
          fontSize: 42,
          fontWeight: FontWeight.w700,
          color: palette.inkPrimary,
          letterSpacing: -0.8,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: palette.inkPrimary,
          letterSpacing: -0.4,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.inkPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          color: palette.inkSecondary,
        ),
      ),
    );
  }
}
