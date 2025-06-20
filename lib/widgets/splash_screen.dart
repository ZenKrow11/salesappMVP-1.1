import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart'; // Import for AuthGate
import 'package:sales_app_mvp/providers/product_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure `ref` is available before use.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAppAndNavigate();
    });
  }

  Future<void> _initializeAppAndNavigate() async {
    try {
      // Define two separate futures:
      // 1. A future for the minimum display time of the splash screen.
      //    This makes the UI feel smoother.
      final minSplashTime = Future.delayed(const Duration(seconds: 2));

      // 2. A future that completes when the first page of products is loaded.
      //    We get this by reading the `.future` property of our new provider.
      final productsFuture = ref.read(paginatedProductsProvider.future);

      print("Splash Screen: Waiting for data and min display time...");

      // Use Future.wait to wait for BOTH futures to complete.
      // The navigation will only happen after the splash has been shown for at least
      // 2 seconds AND the initial product data has been fetched.
      await Future.wait([minSplashTime, productsFuture]);

      print("Splash Screen: Data loaded and time elapsed. Navigating...");

    } catch (e) {
      // This block will run if `productsFuture` fails (e.g., no internet).
      // We still want to navigate, so we print the error and continue.
      print("Splash Screen: Error pre-loading products: $e. Navigating anyway...");
      // If an error occurs, we might still be waiting for the minimum splash time.
      // A simple delay ensures we don't just flash an error and disappear.
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      // This `finally` block ensures navigation happens regardless of success or failure.
      // The `if (mounted)` check is crucial. It prevents an error if the user
      // has somehow navigated away before the futures complete.
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the visual part of your splash screen.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Feel free to add your app logo here
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading latest offers..."),
          ],
        ),
      ),
    );
  }
}