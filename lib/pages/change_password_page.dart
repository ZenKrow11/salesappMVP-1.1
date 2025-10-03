// lib/pages/change_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. IMPORT THE GENERATED LOCALIZATIONS FILE
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
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Get localizations here for the success message
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState?.validate() ?? false) {
      final success = await ref.read(authControllerProvider.notifier).changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // 2. USE LOCALIZED SUCCESS MESSAGE
          SnackBar(content: Text(l10n.passwordChangedSuccessfully), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final authState = ref.watch(authControllerProvider);

    // 3. GET LOCALIZATIONS FOR THE BUILD METHOD
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AsyncValue>(authControllerProvider, (_, state) {
      if (state is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error.toString()), backgroundColor: theme.accent),
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
        // 4. REPLACE ALL HARDCODED STRINGS
        title: Text(l10n.changePassword, style: TextStyle(color: theme.inactive)),
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
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(labelText: l10n.currentPassword, labelStyle: TextStyle(color: theme.inactive)),
                style: TextStyle(color: theme.inactive),
                obscureText: true,
                validator: (value) => value!.isEmpty ? l10n.pleaseEnterCurrentPassword : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: l10n.newPassword, labelStyle: TextStyle(color: theme.inactive)),
                style: TextStyle(color: theme.inactive),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.pleaseEnterNewPassword;
                  // Use the parameterized string for length validation
                  if (value.length < 6) return l10n.passwordTooShort(6);
                  return null;
                },
              ),
              const SizedBox(height: 32),
              authState.isLoading
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