// lib/widgets/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
import 'package:sales_app_mvp/generated/app_localizations.dart';

import 'package:sales_app_mvp/providers/auth_controller.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class LoginScreen extends ConsumerWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 2,
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
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

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
    final currentFormKey = isLogin ? _loginFormKey : _signUpFormKey;

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

    // 2. GET LOCALIZATIONS FOR THE DIALOG
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          return AlertDialog(
            backgroundColor: theme.background,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(l10n.resetPassword, // <-- LOCALIZED
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: theme.secondary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.resetPasswordInstructions, // <-- LOCALIZED
                    style: TextStyle(color: theme.inactive)),
                const SizedBox(height: 16),
                TextField(
                  controller: dialogEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: TextStyle(color: theme.inactive),
                  decoration: InputDecoration(
                    labelText: l10n.emailAddress, // <-- LOCALIZED
                    labelStyle: TextStyle(color: theme.inactive),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  child:
                  Text(l10n.cancel, style: TextStyle(color: theme.inactive)), // <-- LOCALIZED
                  onPressed: () => Navigator.of(dialogContext).pop()),
              authState.isLoading
                  ? const CircularProgressIndicator()
                  : FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: theme.secondary),
                child: Text(l10n.sendEmail), // <-- LOCALIZED
                onPressed: () async {
                  final email = dialogEmailController.text.trim();
                  if (email.isEmpty) {
                    _showErrorSnackBar(l10n.pleaseEnterEmail); // <-- LOCALIZED
                    return;
                  }
                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .sendPasswordResetEmail(email);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (success && mounted) {
                    _showSuccessSnackBar(
                        l10n.passwordResetEmailSent(email)); // <-- LOCALIZED
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

    // 3. GET LOCALIZATIONS FOR THE MAIN BUILD METHOD
    final l10n = AppLocalizations.of(context)!;

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
          l10n.welcomeToAppName(l10n.appName), // <-- LOCALIZED (Nested)
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
          tabs: [
            Tab(text: l10n.login), // <-- LOCALIZED
            Tab(text: l10n.signUp), // <-- LOCALIZED
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          physics: const BouncingScrollPhysics(),
          children: [
            _buildForm(
                key: _loginFormKey, isLogin: true, isLoading: isLoading, l10n: l10n),
            _buildForm(
                key: _signUpFormKey, isLogin: false, isLoading: isLoading, l10n: l10n),
          ],
        ),
      ),
    );
  }

  // 4. PASS THE l10n OBJECT TO HELPER METHODS
  Widget _buildForm(
      {required Key key, required bool isLogin, required bool isLoading, required AppLocalizations l10n}) {
    return Center(
      child: Form(
        key: key,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildEmailField(l10n),
              const SizedBox(height: 16),
              _buildPasswordField(l10n),
              if (isLogin) ...[
                const SizedBox(height: 8),
                _buildLoginOptions(l10n),
              ],
              SizedBox(height: isLogin ? 24 : 40),
              if (isLoading)
                Center(
                    child: CircularProgressIndicator(
                        color: ref.watch(themeProvider).secondary))
              else
                _buildAuthActions(isLoading: isLoading, isLogin: isLogin, l10n: l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    final appTheme = ref.watch(themeProvider);
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: appTheme.inactive),
      decoration: InputDecoration(
        labelText: l10n.emailAddress, // <-- LOCALIZED
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
          return l10n.pleaseEnterEmail; // <-- LOCALIZED
        }
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return l10n.pleaseEnterValidEmail; // <-- LOCALIZED
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    final appTheme = ref.watch(themeProvider);
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      style: TextStyle(color: appTheme.inactive),
      decoration: InputDecoration(
        labelText: l10n.password, // <-- LOCALIZED
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
          return l10n.pleaseEnterPassword; // <-- LOCALIZED
        }
        if (value.length < 6) {
          return l10n.passwordTooShort(6); // <-- LOCALIZED
        }
        return null;
      },
    );
  }

  Widget _buildLoginOptions(AppLocalizations l10n) {
    final appTheme = ref.watch(themeProvider);

    // Replace Row with Wrap
    return Wrap(
      alignment: WrapAlignment.spaceBetween, // Pushes items to the ends
      crossAxisAlignment: WrapCrossAlignment.center, // Vertically aligns items
      children: [
        // This child stays the same
        Row(
          mainAxisSize: MainAxisSize.min, // Important: Makes the inner Row only as wide as it needs to be
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
              Text(l10n.rememberMe, style: TextStyle(color: appTheme.inactive)),
            ),
          ],
        ),
        // This child stays the same
        TextButton(
          onPressed: _showForgotPasswordDialog,
          child: Text(
            l10n.forgotPassword,
            style: TextStyle(
                color: appTheme.secondary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthActions({required bool isLoading, required bool isLogin, required AppLocalizations l10n}) {
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
          child: Text(isLogin ? l10n.login : l10n.createAccount), // <-- LOCALIZED
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: Divider(color: appTheme.inactive.withOpacity(0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.or, style: TextStyle(color: appTheme.inactive)), // <-- LOCALIZED
            ),
            Expanded(
                child: Divider(color: appTheme.inactive.withOpacity(0.3))),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: SvgPicture.asset('assets/icons/google.svg', height: 22),
          label: Text(l10n.continueWithGoogle), // <-- LOCALIZED
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