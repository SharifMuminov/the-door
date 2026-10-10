import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'painters/gallery_painters.dart';

/// A bell on the servants' board. Every time [ringSeq] changes while
/// [ringing] is true, it swings and glows once.
class ServantBell extends StatefulWidget {
  const ServantBell({
    super.key,
    required this.label,
    required this.bellSize,
    required this.ringing,
    required this.ringSeq,
  });

  final String label;
  final double bellSize;
  final bool ringing;
  final int ringSeq;

  @override
  State<ServantBell> createState() => _ServantBellState();
}

class _ServantBellState extends State<ServantBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didUpdateWidget(ServantBell old) {
    super.didUpdateWidget(old);
    if (widget.ringing && widget.ringSeq != old.ringSeq) {
      _swing.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _swing,
      builder: (context, _) {
        final t = _swing.value;
        final moving = _swing.isAnimating;
        final decay = math.pow(1 - t, 2).toDouble();
        return CustomPaint(
          painter: ServantBellPainter(
            label: widget.label,
            bellSize: widget.bellSize,
            swing: moving ? math.sin(t * math.pi * 7) * .45 * decay : 0,
            glow: moving ? decay : 0,
          ),
        );
      },
    );
  }
}
