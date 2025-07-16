import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// NOTE: Add flutter_svg to your pubspec.yaml for the Google icon
// flutter_svg: ^2.0.10+1 or latest
import 'package:flutter_svg/flutter_svg.dart';

import '../providers/auth_controller.dart';
// Import the app's theme colors, as seen in the FilterBottomSheet
import 'package:sales_app_mvp/widgets/theme_color.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const routeName = '/login';
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

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Please fill in both email and password.");
      return;
    }
    await ref.read(authControllerProvider.notifier).signInWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Please fill in both email and password.");
      return;
    }
    await ref.read(authControllerProvider.notifier).signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
  }

  Future<void> _signInWithGoogle() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) => _showErrorSnackBar(e.toString()),
      );
    });

    final isLoading = authState.isLoading;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Get Started',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.secondary,
            indicatorWeight: 3.0,
            labelColor: AppColors.secondary,
            unselectedLabelColor: AppColors.inactive,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              _buildForm(isLogin: true, isLoading: isLoading),
              _buildForm(isLogin: false, isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool isLogin, required bool isLoading}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
            ),
            if (isLogin) ...[
              const SizedBox(height: 8),
              _buildLoginOptions(),
            ],
            SizedBox(height: isLogin ? 24 : 40),
            if (isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            else
              _buildAuthActions(isLogin: isLogin, isLoading: isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.inactive),
        prefixIcon: Icon(icon, color: AppColors.inactive),
        filled: true,
        fillColor: AppColors.primary.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.inactive.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
    );
  }

  Widget _buildLoginOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _keepLoggedIn,
              onChanged: (val) => setState(() => _keepLoggedIn = val ?? true),
              activeColor: AppColors.secondary,
              checkColor: AppColors.background,
              side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.5), width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            GestureDetector(
              onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
              child: const Text("Remember me", style: TextStyle(color: AppColors.textPrimary)),
            ),
          ],
        ),
        TextButton(
          onPressed: () => _showErrorSnackBar("Forgot Password clicked!"),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthActions({required bool isLogin, required bool isLoading}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: isLoading ? null : (isLogin ? _signInWithEmail : _signUpWithEmail),
          child: Text(isLogin ? 'Login' : 'Create Account'),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.inactive.withValues(alpha: 0.3))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR", style: TextStyle(color: AppColors.inactive)),
            ),
            Expanded(child: Divider(color: AppColors.inactive.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: SvgPicture.asset('assets/icons/google.svg', height: 22), // Add your asset
          label: const Text('Continue with Google'),
          onPressed: isLoading ? null : _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.inactive.withValues(alpha: 0.3)),
            ),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}