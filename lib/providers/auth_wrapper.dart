// lib/auth_wrapper.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart'; // We will navigate from here
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/loading_router.dart';
import 'package:sales_app_mvp/widgets/login_screen.dart';
import 'package:sales_app_mvp/widgets/splash_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is the single, master listener for the entire app startup flow.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) async {
      final user = next.value;
      if (user != null) {
        // 1. Ensure profile exists.
        await ref.read(ensureProfileExistsProvider(user).future);
        // 2. Once the profile is guaranteed to exist, start loading app data.
        ref.read(appDataProvider.notifier).initialize();
      }
    });

    // This listener handles the FINAL navigation step.
    ref.listen<AppDataState>(appDataProvider, (previous, next) {
      if (next.status == InitializationStatus.loaded) {
        ref.read(adManagerProvider.notifier).disposeAd(AdPlacement.splashScreen);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainAppScreen()),
              (route) => false,
        );
      }
    });

    // The build method now just reflects the current state.
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (err, stack) => Scaffold(body: Center(child: Text("Auth Error: $err"))),
      data: (user) {
        if (user == null) {
          // If logged out, show the login screen.
          return const LoginScreen();
        } else {
          // If logged in, the listeners above are handling the logic.
          // We just need to show the correct loading UI.
          final appDataState = ref.watch(appDataProvider);
          if (appDataState.status == InitializationStatus.uninitialized) {
            // This is the brief moment between login and data loading starting.
            return const SplashScreen();
          }
          // Otherwise, show the LoadingRouter, which will display the correct progress.
          return const LoadingRouter();
        }
      },
    );
  }
}

/// A provider that ensures the user's profile document exists in Firestore.
final ensureProfileExistsProvider =
FutureProvider.autoDispose.family<void, User?>((ref, user) async {
  if (user == null) return;
  await ref.read(firestoreServiceProvider).createUserProfile(user);
});