// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sales_app_mvp/providers/auth_wrapper.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'package:sales_app_mvp/providers/grouped_products_provider.dart';
import 'package:sales_app_mvp/services/ad_manager.dart';
import 'package:sales_app_mvp/services/firestore_service.dart';
import 'package:sales_app_mvp/widgets/login_screen.dart';

import 'firebase_options.dart';

// --- FIX: Renamed constant to lowerCamelCase ---
const bool useEmulator = bool.fromEnvironment('USE_EMULATOR');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (useEmulator) {
    try {
      final host = '192.168.1.116';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
      debugPrint('>>> CONNECTING TO FIREBASE EMULATORS AT $host <<<');
    } catch (e) {
      debugPrint('Error: Failed to connect to Firebase emulators. $e');
    }
  } else {
    debugPrint('>>> CONNECTING TO LIVE FIREBASE PRODUCTION <<<');
  }

  /// firebase emulators:start --only firestore,auth

  await Hive.initFlutter();

  final container = ProviderContainer();
  container.read(adManagerProvider.notifier).initialize();
  if (!useEmulator) {
    container
        .read(adManagerProvider.notifier)
        .preloadBannerAd(AdPlacement.splashScreen, AdSize.banner);
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateObserverProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      // --- FIX: Replaced deprecated ProviderScope(parent:) pattern ---
      builder: (context, child) {
        // Get the root container.
        final parentContainer = ProviderScope.containerOf(context);
        // Create a new container that inherits from the parent and adds our override.
        final container = ProviderContainer(
          parent: parentContainer,
          overrides: [
            localizationProvider.overrideWithValue(AppLocalizations.of(context)!),
          ],
        );
        // Provide the new container to the widget subtree.
        return UncontrolledProviderScope(
          container: container,
          child: child!,
        );
      },
      home: const AuthWrapper(),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        MainAppScreen.routeName: (context) => const MainAppScreen(),
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Core Application Providers defined in main.dart
// -----------------------------------------------------------------------------

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authStateObserverProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<User?>>(authStateChangesProvider,
          (previous, next) async {
        final user = next.value;
        if (user != null) {
          await ref.read(firestoreServiceProvider).createUserProfile(user);
        }
      });
});