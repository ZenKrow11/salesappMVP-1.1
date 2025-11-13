// lib/auth_wrapper.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/main.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/app_data_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/loading_gate.dart'; // Import the smart gate
import 'package:sales_app_mvp/widgets/login_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // These listeners contain the core LOGIC and remain unchanged.
    // They don't build UI, they orchestrate the process.
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) async {
      final user = next.value;
      if (user != null) {
        await ref.read(ensureProfileExistsProvider(user).future);
        ref.read(appDataProvider.notifier).initialize();
      }
    });

    ref.listen<AppDataState>(appDataProvider, (previous, next) {
      if (next.status == InitializationStatus.loaded) {
        ref.read(adManagerProvider.notifier).disposeAd(AdPlacement.splashScreen);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainAppScreen()),
              (route) => false,
        );
      }
    });

    // The build method is now much simpler. It just reflects the current auth state.
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      // This is the brief, initial state before Firebase responds.
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text("Auth Error: $err"))),
      data: (user) {
        if (user == null) {
          // If logged out, show the login screen.
          return const LoginScreen();
        } else {
          // If logged in, ALWAYS show the LoadingGate.
          // The LoadingGate itself will decide how to appear based on the app data state.
          return const LoadingGate();
        }
      },
    );
  }
}

/// This provider remains unchanged.
final ensureProfileExistsProvider =
FutureProvider.autoDispose.family<void, User?>((ref, user) async {
  if (user == null) return;
  await ref.read(firestoreServiceProvider).createUserProfile(user);
});