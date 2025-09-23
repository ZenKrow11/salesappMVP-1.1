import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Make sure this path points to your actual theme file
import 'package:sales_app_mvp/widgets/app_theme.dart';

/// Defines the screen position for the notification.
enum NotificationPosition {
  top,
  bottom,
}

/// A highly-customizable notification widget for the app.
/// This is the visual component of the notification.
class AppNotification extends StatelessWidget {
  final String message;
  final AppThemeData theme;
  final IconData icon;

  const AppNotification({
    super.key,
    required this.message,
    required this.theme,
    // Provide a default icon, but allow it to be overridden for different message types (e.g., errors).
    this.icon = Icons.check_circle_outline,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // The SafeArea is important, especially for top notifications on notched devices.
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.primary.withOpacity(0.95), // Using your theme colors
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.secondary, size: 24),
              const SizedBox(width: 12),
              Expanded( // Using Expanded instead of Flexible to ensure it fills the space
                child: Text(
                  message,
                  style: TextStyle(
                    color: theme.inactive, // Using white from your theme
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  // Prevents text overflow on smaller screens
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Displays a custom in-app notification from either the top or bottom of the screen.
///
/// This is the main function you will call from your UI.
///
/// - [context]: The BuildContext from which to find the ScaffoldMessenger.
/// - [ref]: The WidgetRef from Riverpod to access providers like the theme.
/// - [message]: The text to display in the notification.
/// - [position]: (Optional) Where to show the notification. Defaults to [NotificationPosition.bottom].
/// - [icon]: (Optional) An icon to display. Defaults to a checkmark. You could pass `Icons.error_outline` for errors.
void showAppNotification(
    BuildContext context,
    WidgetRef ref, {
      required String message,
      NotificationPosition position = NotificationPosition.bottom,
      IconData icon = Icons.check_circle_outline,
    }) {
  // Ensure we have a ScaffoldMessenger to work with.
  if (!ScaffoldMessenger.of(context).mounted) return;

  // Clear any currently displayed notifications to prevent them from stacking.
  ScaffoldMessenger.of(context).clearSnackBars();

  // Read the theme from your Riverpod provider.
  final theme = ref.read(themeProvider);
  final mediaQuery = MediaQuery.of(context);

  // Calculate the margin based on the desired position.
  final EdgeInsets margin;
  if (position == NotificationPosition.top) {
    // This calculation pushes the SnackBar to the top of the screen.
    // We subtract a fixed height (e.g., 150) to leave room for the notification itself.
    margin = EdgeInsets.only(
      bottom: mediaQuery.size.height - mediaQuery.viewPadding.top - 150,
      left: 16,
      right: 16,
    );
  } else {
    // For the bottom, a simple margin is all that's needed.
    margin = const EdgeInsets.all(16.0);
  }

  // Create the SnackBar that will act as a container for our custom widget.
  final snackBar = SnackBar(
    // We let our AppNotification widget handle all visuals.
    backgroundColor: Colors.transparent,
    elevation: 0,

    // This is crucial for allowing custom margins to position the SnackBar.
    behavior: SnackBarBehavior.floating,

    // Apply the calculated margin.
    margin: margin,

    // The content is our custom, beautifully styled widget.
    content: AppNotification(
      message: message,
      theme: theme,
      icon: icon,
    ),

    // Remove any default padding from the SnackBar container.
    padding: EdgeInsets.zero,

    // Set a consistent duration for all notifications.
    duration: const Duration(seconds: 3),
  );

  // Display the notification.
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}