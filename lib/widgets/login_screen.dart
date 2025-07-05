import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _keepLoggedIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signInWithEmail() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      // No need to show error here, error will be handled in build via AsyncValue
    }
  }

  Future<void> _signUpWithEmail() async {
    try {
      await ref.read(authControllerProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {}
  }

  Future<void> _signInWithGoogle() async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Show error SnackBar if there is an error
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) {
          _showErrorSnackBar(e.toString());
        },
      );
    });

    final isLoading = authState.isLoading;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Sign Up'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TabBarView(
            children: [
              _buildForm(isLogin: true, isLoading: isLoading),
              _buildForm(isLogin: false, isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool isLogin, required bool isLoading}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Checkbox(
                value: _keepLoggedIn,
                onChanged: (val) {
                  setState(() => _keepLoggedIn = val ?? true);
                },
              ),
              const Text("Keep me logged in"),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const CircularProgressIndicator()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : (isLogin ? _signInWithEmail : _signUpWithEmail),
                  child: Text(isLogin ? 'Login' : 'Sign Up'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _signInWithGoogle,
                  child: const Text('Sign in with Google'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
