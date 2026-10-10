import 'package:flutter/services.dart';

/// Short vibrations. Uses the platform haptic engine, so no extra
/// package or Android permission is needed.
class Haptics {
  Haptics({this.enabled = true});

  bool enabled;

  Future<void> tap() => _run(HapticFeedback.selectionClick);

  Future<void> light() => _run(HapticFeedback.lightImpact);

  Future<void> medium() => _run(HapticFeedback.mediumImpact);

  Future<void> heavy() => _run(HapticFeedback.heavyImpact);

  /// A longer, unpleasant buzz for horror events.
  Future<void> horror() async {
    await heavy();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await _run(HapticFeedback.vibrate);
  }

  Future<void> _run(Future<void> Function() feedback) async {
    if (!enabled) return;
    try {
      await feedback();
    } catch (_) {
      // Vibration is optional; ignore devices that do not support it.
    }
  }
}
