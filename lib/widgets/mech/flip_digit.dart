import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/mech_audio.dart';
import '../../theme/brass.dart';

/// A split-flap card. Show one or two characters ("7", "10"). When [value]
/// changes the old top half falls forward and the new bottom half drops into
/// place, with a soft flip sound.
class FlipDigit extends StatefulWidget {
  const FlipDigit({
    super.key,
    required this.value,
    required this.height,
    this.charWidthFactor = 0.62,
    this.playSound = true,
    this.duration = const Duration(milliseconds: 380),
  });

  final String value;
  final double height;

  /// Card width per character, as a fraction of the height.
  final double charWidthFactor;
  final bool playSound;
  final Duration duration;

  @override
  State<FlipDigit> createState() => _FlipDigitState();
}

class _FlipDigitState extends State<FlipDigit> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late String _old;

  @override
  void initState() {
    super.initState();
    _old = widget.value;
    _c = AnimationController(vsync: this, duration: widget.duration, value: 1);
  }

  @override
  void didUpdateWidget(covariant FlipDigit old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _old = old.value;
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = 1;
        return;
      }
      _c.forward(from: 0);
      if (widget.playSound) MechAudio.play(Sfx.flip, volume: 0.7, minGapMs: 60);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double get _w =>
      widget.height * widget.charWidthFactor * math.max(1, widget.value.length);

  Widget _half(String text, {required bool top}) {
    final h = widget.height;
    return SizedBox(
      width: _w,
      height: h / 2,
      child: ClipRect(
        child: OverflowBox(
          alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
          minHeight: h,
          maxHeight: h,
          minWidth: _w,
          maxWidth: _w,
          child: _CardFace(text: text, width: _w, height: h),
        ),
      ),
    );
  }

  Matrix4 _tilt(double a) => Matrix4.identity()
    ..setEntry(3, 2, 0.0022)
    ..rotateX(a);

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return Semantics(
      label: widget.value,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: _w,
          height: h,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final flipping = t < 1;
              final newText = widget.value;
              final oldText = _old;
              return Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _half(newText, top: true)),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _half(flipping ? oldText : newText, top: false),
                  ),
                  if (flipping && t < 0.5)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Transform(
                        alignment: Alignment.bottomCenter,
                        transform: _tilt(math.pi / 2 * (t / 0.5)),
                        child: Stack(children: [
                          _half(oldText, top: true),
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black.withOpacity(0.5 * (t / 0.5)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  if (flipping && t >= 0.5)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Transform(
                        alignment: Alignment.topCenter,
                        transform: _tilt(-math.pi / 2 * (1 - (t - 0.5) / 0.5)),
                        child: Stack(children: [
                          _half(newText, top: false),
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black
                                  .withOpacity(0.5 * (1 - (t - 0.5) / 0.5)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  // Centre seam and axle shadow.
                  Positioned(
                    top: h / 2 - 1,
                    left: 0,
                    right: 0,
                    child: Container(height: 2, color: Colors.black.withOpacity(0.85)),
                  ),
                  Positioned(
                    top: h / 2 + 1,
                    left: 0,
                    right: 0,
                    child: Container(height: 0.8, color: Brass.brass.withOpacity(0.18)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.text, required this.width, required this.height});
  final String text;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height * 0.075),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF26211D), Color(0xFF14100E), Color(0xFF1B1613)],
          stops: [0.0, 0.5, 1.0],
        ),
        border: Border.all(color: Brass.brassMid.withOpacity(0.55), width: 1.2),
      ),
      child: Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: Brass.numerals(height * 0.74),
      ),
    );
  }
}

/// Small brass dots between flip groups ("10 : 24").
class FlipColon extends StatelessWidget {
  const FlipColon({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final d = height * 0.075;
    Widget dot() => Container(
          width: d,
          height: d,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.4, -0.4),
              colors: [Brass.brassHi, Brass.brassMid, Brass.brassLo],
            ),
          ),
        );
    return SizedBox(
      width: height * 0.22,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [dot(), SizedBox(height: height * 0.16), dot()],
      ),
    );
  }
}
