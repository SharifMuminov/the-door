import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/constants/app_colors.dart';

/// Short whispered lines at the bottom of the room ("It's locked.").
/// Letters appear one by one, then the line fades away by itself.
/// Never blocks taps.
class DialogueOverlay extends StatefulWidget {
  const DialogueOverlay({
    super.key,
    required this.message,
    required this.messageId,
  });

  final String? message;

  /// Changes every time a new line should be shown (even the same text).
  final int messageId;

  @override
  State<DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends State<DialogueOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
    reverseDuration: const Duration(milliseconds: 700),
  );
  late final AnimationController _type = AnimationController(vsync: this);
  Timer? _hide;
  String _text = '';

  @override
  void didUpdateWidget(DialogueOverlay old) {
    super.didUpdateWidget(old);
    final message = widget.message;
    if (widget.messageId != old.messageId && message != null) _show(message);
  }

  void _show(String text) {
    _hide?.cancel();
    setState(() => _text = text);
    _type
      ..duration = Duration(milliseconds: 24 * text.length)
      ..forward(from: 0);
    _fade.forward(from: _fade.value);
    _hide = Timer(Duration(milliseconds: 2400 + 55 * text.length), () {
      if (mounted) _fade.reverse();
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _fade.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(0, .9),
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.4,
                colors: [
                  AppColors.black.withValues(alpha: .8),
                  AppColors.black.withValues(alpha: 0),
                ],
              ),
            ),
            child: AnimatedBuilder(
              animation: _type,
              builder: (context, _) {
                final shown = (_text.length * _type.value).round();
                // The hidden rest keeps its space so the line never jumps.
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: _text.substring(0, shown)),
                      TextSpan(
                        text: _text.substring(shown),
                        style: const TextStyle(color: Colors.transparent),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppText.whisper,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
