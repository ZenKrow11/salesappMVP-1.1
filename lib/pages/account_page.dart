import 'package:flutter/material.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Account info will be shown here.'),
      ),
    );
  }
}
