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

  final List<Widget> _pages = [
    const HomePage(),
    const ShoppingListPage(),
    const AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // We get the top padding (the height of the status bar) from the MediaQuery.
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      // We set the Scaffold's body to a Column to stack our widgets vertically.
      body: Column(
        children: [
          // 1. A Container for the colored safe area at the top.
          // Its height is set to the status bar height, and it has the primary color.
          Container(
            height: statusBarHeight,
            color: AppColors.primary,
          ),
          // 2. An Expanded widget that takes up all the remaining vertical space.
          // This is where your actual page content will be displayed.
          Expanded(
            child: _pages[_currentIndex],
          ),
        ],
      ),
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