import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Pre-decoded raster art for the mechanical instruments (bezels, gears,
/// buttons, flip-card faces, lever plates). Loaded once at startup so painters
/// can draw synchronously. Every consumer falls back to vector drawing when an
/// image is missing, so a failed load never breaks a screen.
class MechAssets {
  MechAssets._();

  static final Map<String, ui.Image> _images = {};

  static const List<String> _files = [
    'bezel_main.png',
    'card_top.png',
    'card_bottom.png',
    'lever_plate_snooze.png',
    'lever_plate_stop.png',
    'lever_snooze.png',
    'lever_stop.png',
    'nav_button.png',
    'nav_button_lit.png',
    'gears/jewel.png',
    'gears/gear_18.png',
    'gears/gear_20.png',
    'gears/gear_22.png',
    'gears/gear_24.png',
    'gears/gear_26.png',
    'gears/gear_28.png',
    'gears/gear_30.png',
    'gears/gear_34.png',
    'gears/gear_36.png',
  ];

  static Future<void> load() async {
    await Future.wait(_files.map(_loadOne));
  }

  static Future<void> _loadOne(String name) async {
    try {
      final data = await rootBundle.load('assets/mech/$name');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _images[name] = frame.image;
    } catch (_) {
      // Missing or undecodable: callers use their vector fallback.
    }
  }

  static ui.Image? image(String name) => _images[name];
  static ui.Image? gear(int teeth) => _images['gears/gear_$teeth.png'];
}
