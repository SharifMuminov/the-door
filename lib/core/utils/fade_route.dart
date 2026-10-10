import 'package:flutter/material.dart';

/// A slow cross-fade between screens. No sliding — it should feel like
/// the lights going out and coming back.
class FadeRoute<T> extends PageRouteBuilder<T> {
  FadeRoute({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 700),
  }) : super(
         opaque: true,
         barrierColor: Colors.black,
         transitionDuration: duration,
         reverseTransitionDuration: duration,
         pageBuilder: (context, _, _) => builder(context),
         transitionsBuilder: (context, animation, _, child) => FadeTransition(
           opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
           child: child,
         ),
       );
}
