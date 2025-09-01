import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sales_app_mvp/components/top_notification.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

void showTopNotification(BuildContext context, {required String message, required AppThemeData theme}) {
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      // --- FIX: Wrap the animator to control position and interaction ---
      // Align positions the child at the top of the screen.
      // IgnorePointer allows taps to pass through to the UI below.
      return Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: _TopNotificationAnimator(
            child: TopNotification(
              message: message,
              theme: theme,
            ),
            onDispose: () {
              overlayEntry?.remove();
            },
          ),
        ),
      );
    },
  );

  Overlay.of(context).insert(overlayEntry);
}

class _TopNotificationAnimator extends StatefulWidget {
  final Widget child;
  final VoidCallback onDispose;

  const _TopNotificationAnimator({required this.child, required this.onDispose});

  @override
  _TopNotificationAnimatorState createState() => _TopNotificationAnimatorState();
}

class _TopNotificationAnimatorState extends State<_TopNotificationAnimator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5), // Start above the screen
      end: const Offset(0.0, 0.0),    // End at the top
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Animate in
    _controller.forward();

    // Wait for a few seconds, then animate out and remove
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDispose();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}