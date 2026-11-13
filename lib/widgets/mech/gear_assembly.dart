import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/brass.dart';
import '../../theme/mech_assets.dart';

/// One gear in a train. Radius is derived from the tooth count, so meshed gears
/// always touch. A gear with [parent] is placed against its parent at [angle]
/// (radians) and turns the opposite way at a speed set by the tooth ratio.
class GearSpec {
  const GearSpec({
    required this.teeth,
    this.parent,
    this.angle = 0,
    this.center = Offset.zero,
    this.jewel = false,
  });
  final int teeth;
  final int? parent;
  final double angle;

  /// Root gears only. Unit coordinates: (0,0) is the middle of the widget and
  /// 1.0 equals the widget's shorter side.
  final Offset center;
  final bool jewel;
}

class _Gear {
  _Gear(this.x, this.y, this.r, this.teeth, this.phase0, this.omega, this.jewel);
  final double x, y, r, phase0, omega;
  final int teeth;
  final bool jewel;
}

List<_Gear> _layout(List<GearSpec> specs, double module, double baseOmega) {
  final out = <_Gear>[];
  for (var i = 0; i < specs.length; i++) {
    final s = specs[i];
    final r = s.teeth * module;
    if (s.parent == null || s.parent! >= out.length) {
      out.add(_Gear(s.center.dx, s.center.dy, r, s.teeth, 0, baseOmega, s.jewel));
    } else {
      final p = out[s.parent!];
      final a = s.angle;
      final d = p.r + r;
      // Interleave teeth with the parent's gaps at the contact point.
      final up = (a - p.phase0) * p.teeth;
      final phase = a + math.pi - (math.pi - up) / s.teeth;
      out.add(_Gear(
        p.x + math.cos(a) * d,
        p.y + math.sin(a) * d,
        r,
        s.teeth,
        phase,
        -p.omega * p.teeth / s.teeth,
        s.jewel,
      ));
    }
  }
  return out;
}

/// Continuously turning, correctly meshed gear train. Runs at ~30 fps, pauses
/// when [running] is false, when the surrounding route is hidden (TickerMode),
/// or when the system asks for reduced motion.
class GearAssembly extends StatefulWidget {
  const GearAssembly({
    super.key,
    this.gears = clockPreset,
    this.module = 0.0085,
    this.baseSpeed = 0.35,
    this.speed = 1.0,
    this.running = true,
    this.dim = 0.30,
  });

  final List<GearSpec> gears;

  /// Pitch radius per tooth, in unit coordinates.
  final double module;

  /// Angular speed of the first gear, rad/s, before [speed].
  final double baseSpeed;

  /// Multiplier, e.g. 3.0 while a timer is running or an alarm is ringing.
  final double speed;
  final bool running;

  /// 0 = full brass, 1 = near black. Keeps gears behind the digits.
  final double dim;

  static const List<GearSpec> clockPreset = [
    GearSpec(teeth: 36, center: Offset(-0.22, -0.28), jewel: true),
    GearSpec(teeth: 22, parent: 0, angle: 0.75),
    GearSpec(teeth: 30, parent: 1, angle: -0.5, jewel: true),
    GearSpec(teeth: 26, parent: 1, angle: 1.7),
    GearSpec(teeth: 18, parent: 3, angle: 3.0, jewel: true),
    GearSpec(teeth: 20, parent: 0, angle: 2.7),
  ];

  static const List<GearSpec> timerPreset = [
    GearSpec(teeth: 34, center: Offset(0.30, -0.30)),
    GearSpec(teeth: 24, parent: 0, angle: 2.4, jewel: true),
    GearSpec(teeth: 30, parent: 1, angle: 3.6),
    GearSpec(teeth: 28, center: Offset(0.0, 0.50), jewel: true),
    GearSpec(teeth: 20, parent: 3, angle: 3.3),
    GearSpec(teeth: 22, parent: 3, angle: -0.3, jewel: true),
  ];

  @override
  State<GearAssembly> createState() => _GearAssemblyState();
}

class _GearAssemblyState extends State<GearAssembly>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  late List<_Gear> _gears;
  Duration _lastElapsed = Duration.zero;
  double _lastPaint = 0;
  double _t = 0;
  bool _foreground = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_onTick);
    _build();
    _syncTicker();
  }

  void _build() => _gears = _layout(widget.gears, widget.module, widget.baseSpeed);

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    _t += dt * widget.speed;
    if (_t - _lastPaint >= 0.033 * widget.speed) {
      _lastPaint = _t;
      _time.value = _t;
    }
  }

  void _syncTicker() {
    final shouldRun = widget.running && _foreground && !_reduceMotion;
    if (shouldRun && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant GearAssembly old) {
    super.didUpdateWidget(old);
    if (old.gears != widget.gears ||
        old.module != widget.module ||
        old.baseSpeed != widget.baseSpeed) {
      _build();
    }
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GearPainter(_gears, _time, widget.dim),
        size: Size.infinite,
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  _GearPainter(this.gears, this.time, this.dim) : super(repaint: time);
  final List<_Gear> gears;
  final ValueListenable<double> time;
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width, size.height);
    final o = size.center(Offset.zero);
    final t = time.value;
    for (final g in gears) {
      _drawGear(canvas, o + Offset(g.x * s, g.y * s), g.r * s, g, t);
    }
  }

  Color _dim(Color c) => Color.lerp(c, Brass.smoke, dim)!;

  late final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true
    ..colorFilter = ColorFilter.mode(
      Colors.black.withOpacity(dim), BlendMode.srcATop);
  late final Paint _shadowPaint = Paint()
    ..filterQuality = FilterQuality.low
    ..colorFilter = ColorFilter.mode(
      Colors.black.withOpacity(0.55), BlendMode.srcIn);

  /// Photo-shaded gear sprite: tip radius is 0.92 of the sprite's half size.
  void _drawSprite(Canvas canvas, ui.Image img, Offset c, double r, double angle, bool jewel) {
    final half = r / 0.92;
    final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    final dst = Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    // Contact shadow on the glass-backed plate.
    canvas.save();
    canvas.translate(r * 0.035, r * 0.06);
    canvas.drawImageRect(img, src, dst, _shadowPaint);
    canvas.restore();
    canvas.drawImageRect(img, src, dst, _spritePaint);
    canvas.restore();
    if (jewel) {
      final j = MechAssets.image('gears/jewel.png');
      if (j != null) {
        final js = Rect.fromLTWH(0, 0, j.width.toDouble(), j.height.toDouble());
        canvas.drawImageRect(
          j,
          js,
          Rect.fromCenter(center: c, width: r * 0.34, height: r * 0.34),
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
    }
  }

  void _drawGear(Canvas canvas, Offset c, double r, _Gear g, double t) {
    final phi = g.phase0 + g.omega * t;
    final n = g.teeth;
    final pitch = 2 * math.pi / n;
    final sprite = MechAssets.gear(n);
    if (sprite != null) {
      _drawSprite(canvas, sprite, c, r, phi - 0.5 * pitch, g.jewel);
      return;
    }
    final root = r * 0.87;

    final path = Path();
    var first = true;
    void pt(double a, double rad) {
      final p = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      if (first) {
        path.moveTo(p.dx, p.dy);
        first = false;
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    for (var i = 0; i < n; i++) {
      final a = phi + i * pitch - 0.25 * pitch;
      pt(a, root);
      pt(a + 0.12 * pitch, r);
      pt(a + 0.38 * pitch, r);
      pt(a + 0.50 * pitch, root);
    }
    path.close();

    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawPath(
      path.shift(Offset(r * 0.03, r * 0.05)),
      Paint()..color = Colors.black.withOpacity(0.45),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.25,
          colors: [_dim(Brass.brassHi), _dim(Brass.brass), _dim(Brass.brassLo)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, r * 0.012)
        ..color = Colors.black.withOpacity(0.5),
    );

    // Cut-out between rim and hub, then spokes.
    canvas.drawCircle(c, r * 0.70, Paint()..color = Brass.smoke.withOpacity(0.88));
    canvas.drawCircle(
      c,
      r * 0.70,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = _dim(Brass.brassMid),
    );
    final spokes = n >= 28 ? 6 : 5;
    final spokePaint = Paint()
      ..strokeWidth = r * 0.10
      ..strokeCap = StrokeCap.butt
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_dim(Brass.brass), _dim(Brass.brassLo)],
      ).createShader(rect);
    for (var k = 0; k < spokes; k++) {
      final a = phi + k * 2 * math.pi / spokes;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.15),
        c + Offset(math.cos(a), math.sin(a)) * (r * 0.70),
        spokePaint,
      );
    }
    // Hub.
    final hub = Rect.fromCircle(center: c, radius: r * 0.22);
    canvas.drawCircle(
      c,
      r * 0.22,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [_dim(Brass.brassHi), _dim(Brass.brassMid), _dim(Brass.brassLo)],
        ).createShader(hub),
    );
    if (g.jewel) {
      canvas.drawCircle(c, r * 0.11, Paint()..color = Brass.ruby);
      canvas.drawCircle(
        c + Offset(-r * 0.03, -r * 0.035),
        r * 0.035,
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    } else {
      canvas.drawCircle(c, r * 0.07, Paint()..color = Brass.smoke);
    }
  }

  @override
  bool shouldRepaint(covariant _GearPainter old) =>
      old.gears != gears || old.dim != dim;
}
