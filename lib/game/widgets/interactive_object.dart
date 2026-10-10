import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/game_timings.dart';
import '../../core/utils/audio_manager.dart';
import '../../core/utils/haptics.dart';
import '../models/game_object.dart';

/// Anything in the room the player can touch.
///
/// Handles the shared feel of a touch — a small press, a faint glint,
/// an optional sound and a tick of haptics — and forwards the tap.
/// What the tap *means* is decided elsewhere (GameController).
class InteractiveObject extends StatefulWidget {
  const InteractiveObject({
    super.key,
    required this.id,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.visible = true,
    this.sound = Sfx.click,
    this.semanticLabel,
  });

  final ObjectId id;
  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final bool visible;
  final Sfx? sound;
  final String? semanticLabel;

  @override
  State<InteractiveObject> createState() => _InteractiveObjectState();
}

class _InteractiveObjectState extends State<InteractiveObject>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: GameTimings.tap,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || !widget.visible) return;
    _press.forward(from: 0);
    final sound = widget.sound;
    if (sound != null) {
      unawaited(context.read<AudioManager>().play(sound, volume: .5));
    }
    unawaited(context.read<Haptics>().tap());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: GameTimings.fade,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.semanticLabel ?? widget.id.name,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: AnimatedBuilder(
              animation: _press,
              builder: (context, child) {
                final t = math.sin(_press.value * math.pi);
                return Transform.scale(
                  scale: 1 - .035 * t,
                  child: Stack(
                    clipBehavior: Clip.none,
                    fit: StackFit.expand,
                    children: [
                      child!,
                      IgnorePointer(
                        child: Opacity(
                          opacity: t,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [Color(0x1FCFC6B8), Color(0x00CFC6B8)],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Repaints a [CustomPainter] in a slow loop, for living details
/// (a flickering bulb, a rippling mirror). Idle when [animate] is false.
class LoopingPaint extends StatefulWidget {
  const LoopingPaint({
    super.key,
    required this.painter,
    this.animate = true,
    this.period = const Duration(seconds: 4),
  });

  final CustomPainter Function(double phase) painter;
  final bool animate;
  final Duration period;

  @override
  State<LoopingPaint> createState() => _LoopingPaintState();
}

class _LoopingPaintState extends State<LoopingPaint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LoopingPaint old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period) _loop.duration = widget.period;
    _sync();
  }

  void _sync() {
    if (widget.animate && !_loop.isAnimating) {
      _loop.repeat();
    } else if (!widget.animate && _loop.isAnimating) {
      _loop.stop();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _loop,
      builder: (context, _) =>
          CustomPaint(painter: widget.painter(_loop.value)),
    );
  }
}
