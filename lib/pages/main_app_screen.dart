// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // NEW: Import Riverpod
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
// NEW: Import the new theme provider
import 'package:sales_app_mvp/widgets/app_theme.dart';

// CHANGED: The screen is now a ConsumerWidget to access the theme provider
class MainAppScreen extends ConsumerStatefulWidget {
  static const routeName = '/main-app';
  const MainAppScreen({super.key});

  @override
  ConsumerState<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends ConsumerState<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ShoppingListPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // NEW: Get the theme from the provider
    final theme = ref.watch(themeProvider);
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: statusBarHeight,
            // CHANGED: Use the theme color
            color: theme.primary,
          ),
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        // CHANGED: Use theme colors
        backgroundColor: theme.primary,
        currentIndex: _currentIndex,
        selectedItemColor: theme.secondary, // Changed from AppColors.active
        unselectedItemColor: theme.inactive,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money, size: 36),
            label: 'All Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list, size: 36),
            label: 'Lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 36),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}