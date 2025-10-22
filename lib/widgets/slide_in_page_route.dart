// lib/widgets/slide_in_page_route.dart

import 'package:flutter/material.dart';

// Enum to define the direction of the slide transition.
enum SlideDirection {
  leftToRight,
  rightToLeft,
}

// We extend PageRouteBuilder to get full control over the transition.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.rightToLeft, // Default to a standard "push" animation
  }) : super(
    // A standard duration for page transitions is a bit faster.
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),

    // For full-screen slides, setting opaque to true is more performant
    // as it doesn't need to render the route underneath.
    opaque: true,

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
      // --- CHANGE: Determine the starting offset based on the direction ---
      Offset beginOffset;
      switch (direction) {
        case SlideDirection.leftToRight:
        // New page comes from the left side.
          beginOffset = const Offset(-1.0, 0.0);
          break;
        case SlideDirection.rightToLeft:
        // New page comes from the right side (standard behavior).
          beginOffset = const Offset(1.0, 0.0);
          break;
      }

      // Define the "from" and "to" positions for our slide animation.
      final tween = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero, // to center
      );

      // Add a curve to make the animation feel more natural.
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut, // A standard, smooth curve
      );

      // Use SlideTransition to animate the child's position.
      // The reverse animation (when popping the route) is handled automatically.
      // It will slide from the center (zero) back to the 'begin' offset,
      // fulfilling the requirement that the dismiss direction is the same as the call direction.
      return SlideTransition(
        position: tween.animate(curvedAnimation),
        child: child,
      );
    },
  );
}