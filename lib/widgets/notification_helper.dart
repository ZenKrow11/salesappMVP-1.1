import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

/// Defines the screen position for the notification.
enum NotificationPosition {
  top,
  bottom,
}

/// Displays a custom in-app notification from either the top or bottom of the screen.
/// This version is tuned for the specific AppBar and BottomNavBar heights of this app.
void showAppNotification(
    BuildContext context,
    WidgetRef ref, {
      required String message,
      NotificationPosition position = NotificationPosition.bottom,
      IconData icon = Icons.check_circle_outline,
    }) {
  // Ensure we have a valid context to work with.
  if (!ScaffoldMessenger.of(context).mounted) return;

  // Clear previous notifications to avoid stacking.
  ScaffoldMessenger.of(context).clearSnackBars();

  final theme = ref.read(themeProvider);
  final mediaQuery = MediaQuery.of(context);

  // --- LOGIC FOR POSITIONING AND STYLING ---

  final bool isTopNotification = position == NotificationPosition.top;

  // Define colors based on position for better UX.
  final Color backgroundColor = isTopNotification ? theme.secondary : theme.primary;
  final Color textColor = isTopNotification ? theme.primary : theme.inactive;
  final Color iconColor = isTopNotification ? theme.primary : theme.secondary;

  // Define margins based on the app's specific layout.
  final EdgeInsets margin;
  if (isTopNotification) {
    // This margin is calculated to clear the tall HomePage AppBar.
    // HomePage AppBar Height (~100px) + Status Bar Height + Padding (8px)
    // We use a fixed offset that works for the tallest AppBar.
    const double topBarOffset = 108.0;

    margin = EdgeInsets.only(
      top: mediaQuery.viewPadding.top + topBarOffset,
      left: 16,
      right: 16,
    );
  } else {
    // This margin lifts the bottom notification above the BottomNavigationBar.
    // BottomNavBar Height (~80px) + Padding (10px) = 90px
    const double bottomNavBarOffset = 90.0;

    margin = const EdgeInsets.fromLTRB(16, 16, 16, bottomNavBarOffset);
  }

  // --- BUILD AND SHOW THE SNACKBAR ---

  final snackBar = SnackBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    behavior: SnackBarBehavior.floating, // Allows custom margins
    margin: margin, // Use the calculated, context-aware margin

    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.98),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),

    padding: EdgeInsets.zero,
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}