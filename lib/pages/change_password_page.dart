import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/generated/app_localizations.dart';
import 'package:sales_app_mvp/providers/auth_controller.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  // --- REFACTOR: Add controller for current password ---
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      // --- REFACTOR: Call the updated changePassword method with both passwords ---
      await ref.read(authControllerProvider.notifier).changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Check for errors *after* the operation, as the listener might not have fired yet.
      final error = ref.read(authControllerProvider).error;
      if (error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.passwordChangedSuccessfully),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final l10n = AppLocalizations.of(context)!;

    // --- REFACTOR: This listener will now work correctly for errors ---
    ref.listen(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (e, _) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()),
              backgroundColor: theme.accent,
            ));
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        title:
        Text(l10n.changePassword, style: TextStyle(color: theme.inactive)),
        backgroundColor: theme.primary,
        iconTheme: IconThemeData(color: theme.inactive),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- REFACTOR: Add Current Password field ---
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    labelStyle: TextStyle(color: theme.inactive)),
                style: TextStyle(color: theme.inactive),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    labelStyle: TextStyle(color: theme.inactive)),
                style: TextStyle(color: theme.inactive),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterNewPassword;
                  }
                  if (value.length < 6) return l10n.passwordTooShort(6);
                  return null;
                },
              ),
              const SizedBox(height: 32),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.updatePassword),
              ),
            ],
          ),
        ),
      ),
    );
  }
}