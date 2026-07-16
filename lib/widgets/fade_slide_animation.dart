import 'package:flutter/material.dart';

class FadeSlideAnimation extends StatelessWidget {
  final Widget child;
  final int delay;

  const FadeSlideAnimation({super.key, required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 500 + delay),
      tween: Tween(begin: 30, end: 0),
      curve: Curves.easeOutCubic,
      builder: (context, offset, widget) {
        final progress = 1 - (offset / 30);

        return Transform.translate(
          offset: Offset(0, offset),
          child: Opacity(opacity: progress.clamp(0.0, 1.0), child: widget),
        );
      },
      child: child,
    );
  }
}
