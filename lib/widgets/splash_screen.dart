import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/storage_providers.dart';
import 'package:sales_app_mvp/models/products_provider.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart'; // UPDATED

@immutable
class StartupState {
  const StartupState({required this.progress, required this.message});
  final double progress;
  final String message;
}

class StartupNotifier extends StateNotifier<StartupState> {
  StartupNotifier(this._ref)
      : super(const StartupState(progress: 0.0, message: 'Initializing...')) {
    _initialize();
  }
  final Ref _ref;
  Future<void> _animateProgress(double target, String message) async {
    final double currentProgress = state.progress;
    final int steps = ((target - currentProgress).abs() * 100).round();
    if (steps == 0) return;

    for (int i = 1; i <= steps; i++) {
      final newProgress = min(currentProgress + (i * 0.01), target);
      state = StartupState(progress: newProgress, message: message);
      await Future.delayed(const Duration(milliseconds: 15));
    }
    state = StartupState(progress: target, message: message);
  }

  Future<void> _initialize() async {
    await _animateProgress(0.20, 'Preparing local storage...');
    await _ref.read(hiveInitializationProvider.future);
    await _animateProgress(0.50, 'Loading latest deals...');
    await _ref.read(initialProductsProvider.future);
    await _animateProgress(0.90, 'Getting things ready...');
    await _ref.read(homePageProductsProvider.future);
    await _animateProgress(1.0, 'All set!');
    await Future.delayed(const Duration(milliseconds: 250));
  }
}

final startupProvider =
StateNotifierProvider<StartupNotifier, StartupState>((ref) {
  return StartupNotifier(ref);
});

class SplashScreen extends ConsumerWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);
    final theme = ref.watch(themeProvider); // Get theme

    ref.listen(startupProvider, (previous, next) {
      if (next.progress == 1.0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pushReplacementNamed(MainAppScreen.routeName);
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: theme.pageBackground, // UPDATED (pageBackground is good for full screens)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_checkout, size: 80, color: theme.secondary), // UPDATED
            const SizedBox(height: 24),
            Text(startupState.message, style: TextStyle(fontSize: 18, color: theme.inactive, fontWeight: FontWeight.w600)), // UPDATED
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: LinearProgressIndicator(
                value: startupState.progress,
                minHeight: 8.0,
                backgroundColor: theme.primary, // UPDATED
                valueColor: AlwaysStoppedAnimation<Color>(theme.secondary), // UPDATED
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}