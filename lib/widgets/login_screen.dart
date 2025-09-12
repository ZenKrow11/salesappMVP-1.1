// lib/widgets/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:sales_app_mvp/providers/auth_controller.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

// --- The main widget is now just a wrapper for the DefaultTabController ---
class LoginScreen extends ConsumerWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We create the DefaultTabController here...
    return const DefaultTabController(
      length: 2,
      // ...and its child is the new _LoginView widget, which will handle all the UI.
      child: _LoginView(),
    );
  }
}

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView();

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView> {
  // --- CHANGE 1: Create a separate GlobalKey for each form ---
  // A single key cannot be used on two widgets (Login Form and Sign Up Form)
  // that exist in the widget tree at the same time.
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  // These controllers can still be shared since the UI is visually separated by tabs.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _keepLoggedIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final isLogin = DefaultTabController.of(context).index == 0;

    // --- CHANGE 2: Select the correct form key based on the active tab ---
    final currentFormKey = isLogin ? _loginFormKey : _signUpFormKey;

    // Validate using the key for the currently visible form.
    if (!currentFormKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (isLogin) {
      await authNotifier.signInWithEmail(email, password);
    } else {
      await authNotifier.signUpWithEmail(email, password);
    }
  }

  // --- All helper methods below are unchanged and work correctly ---

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final theme = ref.read(themeProvider);
    final dialogEmailController =
    TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          return AlertDialog(
            backgroundColor: theme.background,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text('Reset Password',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: theme.secondary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: TextStyle(color: theme.inactive)),
                const SizedBox(height: 16),
                TextField(
                  controller: dialogEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: TextStyle(color: theme.inactive),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: theme.inactive),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  child:
                  Text('Cancel', style: TextStyle(color: theme.inactive)),
                  onPressed: () => Navigator.of(dialogContext).pop()),
              authState.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: theme.secondary),
                child: const Text('Send Email'),
                onPressed: () async {
                  final email = dialogEmailController.text.trim();
                  if (email.isEmpty) {
                    _showErrorSnackBar("Please enter an email address.");
                    return;
                  }
                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .sendPasswordResetEmail(email);
                  if (dialogContext.mounted)
                    Navigator.of(dialogContext).pop();
                  if (success && mounted) {
                    _showSuccessSnackBar(
                        "Password reset email sent to $email");
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final materialTheme = Theme.of(context);
    final appTheme = ref.watch(themeProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) => _showErrorSnackBar(e.toString()),
      );
    });

    return Scaffold(
      backgroundColor: appTheme.background,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Welcome to SalesSeekr',
          style: materialTheme.textTheme.headlineMedium?.copyWith(
            color: appTheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          indicatorColor: appTheme.secondary,
          indicatorWeight: 3.0,
          labelColor: appTheme.secondary,
          unselectedLabelColor: appTheme.inactive,
          labelStyle:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 16),
          tabs: const [
            Tab(text: 'Login'),
            Tab(text: 'Sign Up'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            // --- CHANGE 3: Pass the correct, unique key to each form ---
            _buildForm(
                key: _loginFormKey, isLogin: true, isLoading: isLoading),
            _buildForm(
                key: _signUpFormKey, isLogin: false, isLoading: isLoading),
          ],
        ),
      ),
    );
  }

  // --- CHANGE 4: Modify the _buildForm signature to accept the key ---
  Widget _buildForm(
      {required Key key, required bool isLogin, required bool isLoading}) {
    return Center(
      // --- CHANGE 5: Use the passed-in key for the Form widget ---
      child: Form(
        key: key,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              if (isLogin) ...[
                const SizedBox(height: 8),
                _buildLoginOptions(),
              ],
              SizedBox(height: isLogin ? 24 : 40),
              if (isLoading)
                Center(
                    child: CircularProgressIndicator(
                        color: ref.watch(themeProvider).secondary))
              else
                _buildAuthActions(isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    final appTheme = ref.watch(themeProvider);
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: appTheme.inactive),
      decoration: InputDecoration(
        labelText: 'Email Address',
        labelStyle: TextStyle(color: appTheme.inactive),
        prefixIcon: Icon(Icons.email_outlined, color: appTheme.inactive),
        filled: true,
        fillColor: appTheme.primary.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.inactive.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.secondary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your email address.';
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address.';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    final appTheme = ref.watch(themeProvider);
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      style: TextStyle(color: appTheme.inactive),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: appTheme.inactive),
        prefixIcon: Icon(Icons.lock_outline, color: appTheme.inactive),
        filled: true,
        fillColor: appTheme.primary.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.inactive.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.secondary, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password.';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters long.';
        }
        return null;
      },
    );
  }

  Widget _buildLoginOptions() {
    final appTheme = ref.watch(themeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _keepLoggedIn,
              onChanged: (val) => setState(() => _keepLoggedIn = val ?? true),
              activeColor: appTheme.secondary,
              checkColor: appTheme.background,
              side: BorderSide(
                  color: appTheme.inactive.withOpacity(0.5), width: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            GestureDetector(
              onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
              child:
              Text("Remember me", style: TextStyle(color: appTheme.inactive)),
            ),
          ],
        ),
        TextButton(
          onPressed: _showForgotPasswordDialog,
          child: Text(
            'Forgot Password?',
            style: TextStyle(
                color: appTheme.secondary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthActions({required bool isLoading}) {
    final appTheme = ref.watch(themeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.secondary,
            foregroundColor: appTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: isLoading ? null : _submitForm,
          child: Text(DefaultTabController.of(context).index == 0
              ? 'Login'
              : 'Create Account'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: Divider(color: appTheme.inactive.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR", style: TextStyle(color: appTheme.inactive)),
            ),
            Expanded(
                child: Divider(color: appTheme.inactive.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: SvgPicture.asset('assets/icons/google.svg', height: 22),
          label: const Text('Continue with Google'),
          onPressed: isLoading
              ? null
              : () =>
              ref.read(authControllerProvider.notifier).signInWithGoogle(),
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.pageBackground,
            foregroundColor: appTheme.inactive,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: appTheme.inactive.withOpacity(0.3)),
            ),
            elevation: 0,
            textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}