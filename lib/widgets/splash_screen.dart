// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart'; // For AuthGate
import '../providers/storage_providers.dart'; // For hiveInitializationProvider
import '../providers/product_provider.dart'; // For paginatedProductsProvider

/// This new provider acts as a "gatekeeper" for the splash screen.
/// It waits for all necessary startup tasks to complete.
final splashReadyProvider = FutureProvider<void>((ref) async {
  // Define all the futures that must complete before the app is ready.
  final allInitializations = [
    // 1. Wait for Hive to be fully initialized.
    ref.watch(hiveInitializationProvider.future),

    // 2. Wait for the first page of products to be fetched from Firestore.
    ref.watch(paginatedProductsProvider.future),

    // 3. Wait for a minimum display time of 2 seconds (for better UX).
    Future.delayed(const Duration(seconds: 2)),
  ];

  // Wait for all of them to finish in parallel.
  await Future.wait(allInitializations);
});

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We 'listen' to the provider. The listener callback is only called when
    // the provider's state changes (e.g., from loading to data/error).
    // This is perfect for one-time actions like navigation.
    ref.listen<AsyncValue<void>>(
      splashReadyProvider,
          (previous, next) {
        // When the state is no longer loading, navigate.
        if (!next.isLoading) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthGate()),
          );
        }
      },
    );

    // This is the UI that is displayed while the splashReadyProvider is running.
    // It's simple, declarative, and doesn't contain any complex logic.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Getting things ready..."),
          ],
        ),
      ),
    );
  }
}