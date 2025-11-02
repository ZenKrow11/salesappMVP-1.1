// lib/services/notification_manager.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/components/top_notification.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class NotificationManager {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    // If a notification is already visible, remove it instantly before showing the new one.
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    final theme = ProviderScope.containerOf(context, listen: false).read(themeProvider);

    _overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWrapper(
        message: message,
        theme: theme,
        onDispose: _removeOverlay,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void _removeOverlay() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}


// A private helper widget to manage the animation and timer.
class _NotificationWrapper extends StatefulWidget {
  final String message;
  final AppThemeData theme;
  final VoidCallback onDispose;

  const _NotificationWrapper({
    required this.message,
    required this.theme,
    required this.onDispose,
  });

  @override
  _NotificationWrapperState createState() => _NotificationWrapperState();
}

class _NotificationWrapperState extends State<_NotificationWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, -1.5), // Start above the screen
      end: const Offset(0, 0),       // End at the top
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Animate in, wait, then animate out.
    _controller.forward().then((_) {
      // Wait for 3 seconds before starting the dismiss animation.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _controller.reverse().then((_) => widget.onDispose());
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using MediaQuery to position it correctly at the top, respecting notches.
    final topPadding = MediaQuery.of(context).viewPadding.top + 16.0;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _animation,
        child: TopNotification(
          message: widget.message,
          theme: widget.theme,
        ),
      ),
    );
  }
}