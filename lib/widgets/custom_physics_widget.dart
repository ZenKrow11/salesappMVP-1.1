// lib/widgets/custom_physics_widget.dart

import 'package:flutter/widgets.dart';

class SnappyPageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;

  const SnappyPageScrollPhysics({
    super.parent,
    this.dragThreshold = 10.0,
  });

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(
      parent: buildParent(ancestor),
      dragThreshold: dragThreshold,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (position is! PageMetrics || !position.hasContentDimensions) {
      return super.createBallisticSimulation(position, velocity);
    }

    final PageMetrics metrics = position;

    // --- EVEN MORE AGGRESSIVE SETTINGS FOR A FASTER SWIPE ---
    // These values create a very fast, snappy animation with almost no "settling" time.
    final SpringDescription spring = SpringDescription.withDampingRatio(
      mass: 1.0,      // Drastically reduced mass for quick reaction
      stiffness: 800.0,  // Significantly increased stiffness for a powerful snap
      ratio: 1.0,      // Keeps it critically damped to prevent any bounce
    );

    final double dragDistance = metrics.pixels - metrics.page!.round() * metrics.viewportDimension;
    final double flingVelocityThreshold = tolerance.velocity;
    final bool hasFlingVelocity = velocity.abs() > flingVelocityThreshold;
    final bool hasDraggedPastThreshold = dragDistance.abs() > dragThreshold;

    double targetPage;

    if (hasFlingVelocity || hasDraggedPastThreshold) {
      final double direction = velocity.sign != 0 ? velocity.sign : dragDistance.sign;
      targetPage = (metrics.page! + 0.5 * direction).round().toDouble();
    } else {
      targetPage = metrics.page!.round().toDouble();
    }

    final double maxPage = (metrics.maxScrollExtent / metrics.viewportDimension);
    targetPage = targetPage.clamp(0.0, maxPage);
    final double targetPixels = targetPage * metrics.viewportDimension;

    return ScrollSpringSimulation(
      spring,
      metrics.pixels,
      targetPixels,
      velocity,
    );
  }

  @override
  double get minFlingDistance => dragThreshold / 2;
}