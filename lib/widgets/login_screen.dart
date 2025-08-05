import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sales_app_mvp/providers/auth_controller.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart'; // UPDATED

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
        content: const Text(
          "message",
          style: TextStyle(color: Colors.white), // Standard white for error message is fine
        ),
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
    final materialTheme = Theme.of(context);
    final appTheme = ref.watch(themeProvider); // Get theme from provider

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (e, _) => _showErrorSnackBar(e.toString()),
      );
    });

    final isLoading = authState.isLoading;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: appTheme.background, // UPDATED
        appBar: AppBar(
          toolbarHeight: 80,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Get Started',
            style: materialTheme.textTheme.headlineMedium?.copyWith(
              color: appTheme.secondary, // UPDATED
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            indicatorColor: appTheme.secondary, // UPDATED
            indicatorWeight: 3.0,
            labelColor: appTheme.secondary, // UPDATED
            unselectedLabelColor: appTheme.inactive, // UPDATED
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
    final appTheme = ref.watch(themeProvider); // Get theme
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
              Center(child: CircularProgressIndicator(color: appTheme.secondary)) // UPDATED
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
    final appTheme = ref.watch(themeProvider); // Get theme
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isPassword ? TextInputType.visiblePassword : TextInputType.emailAddress,
      style: TextStyle(color: appTheme.inactive), // UPDATED (was textPrimary)
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: appTheme.inactive), // UPDATED
        prefixIcon: Icon(icon, color: appTheme.inactive), // UPDATED
        filled: true,
        fillColor: appTheme.primary.withOpacity(0.5), // UPDATED & FIXED
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.inactive.withOpacity(0.2)), // UPDATED & FIXED
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.secondary, width: 2), // UPDATED
        ),
      ),
    );
  }

  Widget _buildLoginOptions() {
    final appTheme = ref.watch(themeProvider); // Get theme
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _keepLoggedIn,
              onChanged: (val) => setState(() => _keepLoggedIn = val ?? true),
              activeColor: appTheme.secondary, // UPDATED
              checkColor: appTheme.background, // UPDATED
              side: BorderSide(color: appTheme.inactive.withOpacity(0.5), width: 2), // UPDATED & FIXED
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            GestureDetector(
              onTap: () => setState(() => _keepLoggedIn = !_keepLoggedIn),
              child: Text("Remember me", style: TextStyle(color: appTheme.inactive)), // UPDATED (was textPrimary)
            ),
          ],
        ),
        TextButton(
          onPressed: () => _showErrorSnackBar("Forgot Password clicked!"),
          child: Text(
            'Forgot Password?',
            style: TextStyle(color: appTheme.secondary, fontWeight: FontWeight.w600), // UPDATED
          ),
        ),
      ],
    );
  }

  Widget _buildAuthActions({required bool isLogin, required bool isLoading}) {
    final appTheme = ref.watch(themeProvider); // Get theme
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.secondary, // UPDATED
            foregroundColor: appTheme.primary, // UPDATED
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
            Expanded(child: Divider(color: appTheme.inactive.withOpacity(0.3))), // UPDATED & FIXED
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("OR", style: TextStyle(color: appTheme.inactive)), // UPDATED
            ),
            Expanded(child: Divider(color: appTheme.inactive.withOpacity(0.3))), // UPDATED & FIXED
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: SvgPicture.asset('assets/icons/google.svg', height: 22),
          label: const Text('Continue with Google'),
          onPressed: isLoading ? null : _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: appTheme.pageBackground, // UPDATED (primary might be too dark)
            foregroundColor: appTheme.inactive, // UPDATED (was textPrimary)
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: appTheme.inactive.withOpacity(0.3)), // UPDATED & FIXED
            ),
            elevation: 0,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}