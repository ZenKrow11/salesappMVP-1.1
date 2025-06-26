import 'package:flutter/material.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/widgets/theme_color.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  // The AccountPage is now the third tab in the main navigation.
  final List<Widget> _pages = [
    const HomePage(),
    const ShoppingListPage(),
    const AccountPage(),
  ];

  final List<String> _titles = [
    'All Sales',
    'Lists',
    'Account',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The key and endDrawer have been removed.
      appBar: AppBar(
        // The title now correctly reflects the current page.
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppColors.active,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        // The actions list with the drawer button has been removed.
        actions: const [],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.primary,
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.active,
        unselectedItemColor: AppColors.inactive,
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