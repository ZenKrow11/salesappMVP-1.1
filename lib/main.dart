import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sales_app_mvp/pages/main_app_screen.dart';
import 'firebase_options.dart';
import 'login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/product.dart';
import 'services/hive_storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'models/named_list.dart';
import 'package:sales_app_mvp/widgets/splash_screen.dart';

final hiveStorageService = HiveStorageService.instance; // Optional global instance

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(NamedListAdapter());

  await HiveStorageService.instance.init();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales App',
      theme: ThemeData(useMaterial3: true),
      home: const SplashScreen(), // Set SplashScreen as home
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key}); // Add constructor with key

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return const MainAppScreen(); // Signed in
        } else {
          return const LoginScreen(); // Not signed in
        }
      },
    );
  }
}