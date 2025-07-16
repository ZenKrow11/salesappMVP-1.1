// lib/widgets/custom_physics_widget.dart

import 'package:flutter/widgets.dart';

/// A custom scroll physics that provides a comfortable, fluid page-turning
/// experience with a custom "speed ramp" animation.
///
/// This physics class ensures that a page turn is triggered by either a
/// traditional fling gesture or by dragging the page past a small pixel
/// threshold.
///
/// Instead of the default animation, it uses a custom-configured
/// `ScrollSpringSimulation` to create a fast initial transition that
/// smoothly decelerates as it approaches the target page.
class ComfortablePageScrollPhysics extends PageScrollPhysics {
  /// The minimum number of pixels a user must drag to trigger a page change.
  final double dragThreshold;

  /// Creates a scroll physics with a custom animation and drag threshold.
  const ComfortablePageScrollPhysics({
    super.parent,
    this.dragThreshold = 15.0,
  });

  @override
  ComfortablePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ComfortablePageScrollPhysics(
      parent: buildParent(ancestor),
      dragThreshold: dragThreshold,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Ensure we have a PageMetrics object
    if (position is! PageMetrics || !position.hasContentDimensions) {
      return super.createBallisticSimulation(position, velocity);
    }

    final PageMetrics metrics = position;

    // ================== NEW ANIMATION LOGIC ==================

    // 1. Define the spring for the animation.
    final SpringDescription spring = SpringDescription.withDampingRatio(
      mass: 0.5,
      stiffness: 100.0,
      ratio: 1.1, // A ratio > 1.0 prevents any bounce.
    );

    // 2. Decide if we are moving to the next/previous page or snapping back.

    // <<< FIX: This is the corrected way to calculate the drag distance.
    // We measure the distance from the current pixel position to the center
    // of the page we started on (the "rounded" page).
    final double dragDistance = metrics.pixels - metrics.page!.round() * metrics.viewportDimension;

    final double flingVelocityThreshold = tolerance.velocity;
    final bool hasFlingVelocity = velocity.abs() > flingVelocityThreshold;

    // A more robust threshold would be based on the viewport dimension,
    // but we'll use the fixed one for this example.
    final bool hasDraggedPastThreshold = dragDistance.abs() > dragThreshold;

    double targetPage;

    // This logic now works correctly because `dragDistance` is calculated properly.
    if (hasFlingVelocity || hasDraggedPastThreshold) {
      // We should move to a new page.
      // The direction is determined by the velocity if it exists, otherwise by the drag direction.
      final double direction = velocity.sign != 0 ? velocity.sign : dragDistance.sign;
      targetPage = (metrics.page! + 0.5 * direction).round().toDouble();
    } else {
      // Snap back to the current page.
      targetPage = metrics.page!.round().toDouble();
    }

    // 3. Clamp the target page to stay within the bounds of the PageView.
    final double maxPage = (metrics.maxScrollExtent / metrics.viewportDimension);
    targetPage = targetPage.clamp(0.0, maxPage);

    // 4. Calculate the final pixel destination.
    final double targetPixels = targetPage * metrics.viewportDimension;

    // 5. Create and return the custom spring simulation.
    return ScrollSpringSimulation(
      spring,
      metrics.pixels, // current position
      targetPixels,   // target position
      velocity,       // initial velocity
    );
  }

  // We still provide a minFlingDistance for gesture detection hints.
  @override
  double get minFlingDistance => dragThreshold / 2;
}