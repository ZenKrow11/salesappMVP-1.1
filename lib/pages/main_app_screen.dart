import 'package:flutter/material.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/secondary_app_screen.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    HomePage(),
    ShoppingListPage(),
    AccountPage(),
  ];

  final List<String> _titles = [
    'All Sales',
    'Lists',
    'Account',
  ];

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: AppColors.active,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 40,
            color: AppColors.active,
            onPressed: _openDrawer,
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(
              height: 119,
              width: double.infinity,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                ),
                child: Text(
                  'User Avatar',
                  style: TextStyle(
                    color: AppColors.active,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person,
                  color: AppColors.active, size: 40),
              title: const Text('Account',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                ),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SecondaryAppScreen(initialIndex: 0),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings,
                  color: AppColors.active, size: 40),
              title: const Text('Settings',
                style: TextStyle(
                  color: AppColors.active,
                  fontSize: 24,
                ),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SecondaryAppScreen(initialIndex: 1),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline,
                  color: AppColors.active, size: 40),
              title: const Text('Contact',
                style: TextStyle(
                  color: AppColors.active,
                  fontSize: 24,
                ),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SecondaryAppScreen(initialIndex: 2),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout,
                  color: AppColors.active, size: 40),
              title: const Text('Logout',
                style: TextStyle(
                  color: AppColors.active,
                  fontSize: 24,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
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
            label: 'Sales',
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
