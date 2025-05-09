import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _keepLoggedIn = true;

  Future<void> signInWithEmail() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> signUpWithEmail() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Welcome to SalesApp'),
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
              _buildForm(isLogin: true),
              _buildForm(isLogin: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool isLogin}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
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
                  setState(() {
                    _keepLoggedIn = val ?? true;
                  });
                },
              ),
              const Text("Keep me logged in"),
            ],
          ),
          const SizedBox(height: 16),
          _loading
              ? const CircularProgressIndicator()
              : Column(
            children: [
              ElevatedButton(
                onPressed: isLogin ? signInWithEmail : signUpWithEmail,
                child: Text(isLogin ? 'Login' : 'Sign Up'),
              ),
              ElevatedButton(
                onPressed: signInWithGoogle,
                child: const Text('Sign in with Google'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
