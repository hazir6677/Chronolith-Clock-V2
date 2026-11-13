import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../services/mech_audio.dart';
import '../../theme/brass.dart';
import '../../theme/mech_assets.dart';

/// A spring-loaded toggle lever in a vertical slot, drawn from photographed
/// plate and lever art. Drag, flick or tap. It rests at one end of the slot;
/// moving it to the other end engages it. Releasing short of the detent
/// springs it back.
class ToggleLever extends StatefulWidget {
  const ToggleLever({
    super.key,
    required this.onEngaged,
    required this.semanticLabel,
    this.icon,
    this.engagedAtTop = true,
    this.width = 128,
    this.height = 200,
  });

  final VoidCallback onEngaged;
  final String semanticLabel;

  /// Shown only by the vector fallback; the photographed plates carry no icon,
  /// so the icon is always drawn above the slot.
  final Widget? icon;

  /// true (Snooze): rests at the bottom, engages upward.
  /// false (Stop): rests at the top, engages downward.
  final bool engagedAtTop;

  /// [width] drives layout. [height] is only used if the art is missing.
  final double width, height;

  @override
  State<ToggleLever> createState() => _ToggleLeverState();
}

// Geometry of the extracted art, in the art's own pixels (2x crop).
class _Art {
  const _Art(this.plate, this.lever, this.pw, this.ph, this.lx, this.ly, this.lw, this.lh);
  final String plate, lever;
  final double pw, ph, lx, ly, lw, lh;

  static const snooze = _Art('lever_plate_snooze.png', 'lever_snooze.png', 454, 846, 136, 436, 190, 356);
  static const stop = _Art('lever_plate_stop.png', 'lever_stop.png', 440, 842, 138, 160, 204, 352);
  static const double travel = 180; // art px between rest and engaged
}

class _ToggleLeverState extends State<ToggleLever> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() => _p = _c.value));
  double _p = 0; // 0 = rest, 1 = engaged
  bool _engaged = false;
  bool _crossed = false;

  static const _spring = SpringDescription(mass: 1, stiffness: 520, damping: 27);

  _Art get _art => widget.engagedAtTop ? _Art.snooze : _Art.stop;
  bool get _hasArt =>
      MechAssets.image(_art.plate) != null && MechAssets.image(_art.lever) != null;
  double get _scale => widget.width / _art.pw;
  double get _h => _hasArt ? _art.ph * _scale : widget.height;
  double get _travel => _hasArt ? _Art.travel * _scale : widget.height * 0.44;
  double get _dir => widget.engagedAtTop ? -1 : 1; // screen-y sign toward engaged

  void _snapTo(double target, double velocity) {
    _c.animateWith(SpringSimulation(_spring, _p, target, velocity)).whenComplete(() {
      if (!mounted) return;
      if (target == 1.0 && !_engaged) _engage();
    });
  }

  void _engage() {
    _engaged = true;
    _p = 1.0;
    MechAudio.play(Sfx.leverClack);
    MechAudio.haptic(Haptic.heavy);
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) widget.onEngaged();
    });
  }

  void _dragUpdate(DragUpdateDetails d) {
    if (_engaged) return;
    _c.stop();
    final resist = 1.0 - 0.35 * _p;
    final dp = (d.delta.dy * _dir / _travel) * resist;
    setState(() => _p = math.min(1.0, math.max(-0.03, _p + dp)));
    if (!_crossed && _p >= 0.55) {
      _crossed = true;
      MechAudio.haptic(Haptic.tick);
    } else if (_crossed && _p < 0.5) {
      _crossed = false;
    }
  }

  void _dragEnd(DragEndDetails d) {
    if (_engaged) return;
    final vp = d.velocity.pixelsPerSecond.dy * _dir / _travel;
    final goes = _p + vp * 0.10 > 0.55;
    _snapTo(goes ? 1.0 : 0.0, vp);
  }

  void _tap() {
    if (_engaged) return;
    _snapTo(1.0, 2.0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = math.min(1.04, math.max(-0.04, _p));
    final h = _h;
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: _tap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        onVerticalDragUpdate: _dragUpdate,
        onVerticalDragEnd: _dragEnd,
        child: SizedBox(
          width: widget.width,
          height: h,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(widget.width, h),
                painter: _hasArt
                    ? _SpriteLeverPainter(_art, p, _dir)
                    : _VectorLeverPainter(p, widget.engagedAtTop),
              ),
              if (widget.icon != null)
                Positioned(
                  top: h * 0.075,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(
                        color: const Color(0xFFFFD38A),
                        size: h * 0.085,
                        shadows: const [Shadow(color: Color(0xAAFF9A2E), blurRadius: 10)],
                      ),
                      child: widget.icon!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpriteLeverPainter extends CustomPainter {
  _SpriteLeverPainter(this.art, this.p, this.dir);
  final _Art art;
  final double p, dir;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = MechAssets.image(art.plate);
    final lever = MechAssets.image(art.lever);
    if (plate == null || lever == null) return;
    final s = size.width / art.pw;
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
    canvas.drawImageRect(
      plate,
      Rect.fromLTWH(0, 0, plate.width.toDouble(), plate.height.toDouble()),
      Rect.fromLTWH(0, 0, art.pw * s, art.ph * s),
      paint,
    );
    // Keep the lever inside the plate outline.
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, art.pw * s, art.ph * s),
      Radius.circular(art.pw * s / 2),
    ));
    final dy = dir * p * _Art.travel * s;
    final bump = 1.0 + 0.035 * math.sin(math.pi * p.clamp(0.0, 1.0));
    final w = art.lw * s * bump, h = art.lh * s * bump;
    final cx = (art.lx + art.lw / 2) * s;
    final cy = (art.ly + art.lh / 2) * s + dy;
    final dst = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    final src = Rect.fromLTWH(0, 0, lever.width.toDouble(), lever.height.toDouble());
    // Soft shadow under the moving lever.
    canvas.save();
    canvas.translate(s * 5, s * 8);
    canvas.drawImageRect(
      lever,
      src,
      dst,
      Paint()
        ..colorFilter = ColorFilter.mode(Colors.black.withOpacity(0.45), BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: s * 6, sigmaY: s * 6),
    );
    canvas.restore();
    canvas.drawImageRect(lever, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpriteLeverPainter o) => o.p != p || o.art != art;
}

/// Fallback when the art failed to load.
class _VectorLeverPainter extends CustomPainter {
  _VectorLeverPainter(this.p, this.engagedAtTop);
  final double p;
  final bool engagedAtTop;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.5));
    canvas.drawRRect(plate, Paint()..color = const Color(0xFF2B2623));
    final slotW = size.width * 0.5, slotH = size.height * 0.62;
    final slot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.53), width: slotW, height: slotH),
      Radius.circular(slotW / 2),
    );
    canvas.drawRRect(slot, Paint()..color = Brass.smoke);
    final half = slotH / 2 - slotW * 0.42;
    final rest = engagedAtTop ? half : -half;
    final y = rest + (-rest - rest) * p;
    canvas.drawCircle(slot.center.translate(0, y), size.width * 0.18, Paint()..color = Brass.brass);
  }

  @override
  bool shouldRepaint(covariant _VectorLeverPainter o) => o.p != p;
}
