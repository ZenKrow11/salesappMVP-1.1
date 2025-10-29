import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class FastLoadingScreen extends ConsumerWidget {
  const FastLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    // This screen is intentionally simple and fast.
    return Scaffold(
      backgroundColor: theme.pageBackground,
      body: Center(
        child: CircularProgressIndicator(
          color: theme.secondary,
        ),
      ),
    );
  }
}