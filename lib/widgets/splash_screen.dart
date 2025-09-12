// lib/widgets/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  static const routeName = '/'; // Keep this if you use it in main.dart
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    // This is now just a simple display widget.
    // AuthGate handles all the logic and navigation.
    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_checkout,
              size: 80,
              color: theme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 18,
                color: theme.inactive,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: LinearProgressIndicator(
                backgroundColor: theme.primary,
                valueColor: AlwaysStoppedAnimation<Color>(theme.secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}