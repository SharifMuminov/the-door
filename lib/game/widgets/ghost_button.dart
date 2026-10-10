import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_timings.dart';

/// Text-only button. No ripple, no box: the text darkens to red while held.
class GhostButton extends StatefulWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.style = AppText.label,
    this.color,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final TextStyle style;
  final Color? color;
  final bool enabled;

  @override
  State<GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<GhostButton> {
  bool _down = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.color ?? widget.style.color ?? AppColors.bone;
    final color = !_active
        ? AppColors.smoke
        : (_down ? AppColors.bloodLight : base);

    return Semantics(
      button: true,
      enabled: _active,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _active ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: _active ? widget.onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: AnimatedDefaultTextStyle(
            duration: GameTimings.tap,
            style: widget.style.copyWith(color: color),
            child: Text(widget.label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
