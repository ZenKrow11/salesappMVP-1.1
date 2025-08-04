// lib/pages/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/widgets/app_theme.dart';
import 'package:sales_app_mvp/pages/debug_page.dart';



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
    final theme = ref.watch(themeProvider);
    // We need the status bar height to manually color that area.
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      // The background for the main content area.
      backgroundColor: theme.pageBackground,
      body: Column(
        children: [
          // This Container draws the color behind the system status bar icons (time, wifi, etc.)
          Container(
            height: statusBarHeight,
            color: theme.primary, // This must match the color of your top bar in HomePage
          ),
          // This Expanded widget is CRUCIAL. It tells the child page how much space it can fill.
          // This is what will fix the sliver stacking bug.
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.primary,
        currentIndex: _currentIndex,
        selectedItemColor: theme.secondary,
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