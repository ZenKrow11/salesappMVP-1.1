import 'package:flutter/material.dart';

// We extend PageRouteBuilder to get full control over the transition.
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideUpPageRoute({required this.page})
      : super(
    // Set the duration of the animation.
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),

    // The pageBuilder simply returns the widget that should be displayed.
    pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        ) {
      return page;
    },

    // The transitionsBuilder is where the magic happens.
    // It defines HOW the page appears and disappears.
    transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) {
      // Define the "from" and "to" positions for our slide animation.
      // Offset(0.0, 1.0) is the bottom of the screen.
      // Offset.zero is the center of the screen (final position).
      final tween = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      );

      // Add a curve to make the animation feel more natural.
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic, // A nice smooth curve
      );

      // Use SlideTransition to animate the child's position.
      return SlideTransition(
        position: tween.animate(curvedAnimation),
        // The `child` here is the `ProductSwiperScreen` returned from pageBuilder.
        child: child,
      );
    },
  );
}