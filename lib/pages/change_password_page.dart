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
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState?.validate() ?? false) {
      await ref.read(authControllerProvider.notifier)
          .changePassword(_newPasswordController.text);
      if (mounted) {
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

    ref.listen(authControllerProvider, (_, state) {
      state.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: theme.accent,
        )),
      );
    });

    return Scaffold(
      backgroundColor: theme.pageBackground,
      appBar: AppBar(
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
                controller: _newPasswordController,
                decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    labelStyle: TextStyle(color: theme.inactive)),
                style: TextStyle(color: theme.inactive),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return l10n.pleaseEnterNewPassword;
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
