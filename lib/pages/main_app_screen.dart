import 'package:flutter/material.dart';
import 'package:sales_app_mvp/pages/home_page.dart';
import 'package:sales_app_mvp/pages/secondary_app_screen.dart';
import 'package:sales_app_mvp/pages/shopping_list_page.dart';
import 'package:sales_app_mvp/pages/favorites_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    FavoritesPage(),
    ShoppingListPage(),
  ];

  final List<String> _titles = [
    'All Sales',
    'Favorites',
    'Grocery Lists',
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
        title: Text(_titles[_currentIndex],
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 24,
          fontWeight: FontWeight.bold,),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle,),
            iconSize: 40,
            color: Colors.greenAccent,
            onPressed: _openDrawer,
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 119,
              width: double.infinity,
              child: const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                ),
                child: Text(
                  'User Avatar',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person,
              color: Colors.deepPurple,
              size: 40),
              title: const Text('Account',
              style: TextStyle(
                color: Colors.deepPurple,
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
                color: Colors.deepPurple,
                size: 40),
              title: const Text('Settings',
                style: TextStyle(
                  color: Colors.deepPurple,
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
                  color: Colors.deepPurple,
                  size: 40),
              title: const Text('Contact',
                style: TextStyle(
                  color: Colors.deepPurple,
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
                  color: Colors.deepPurple,
                  size: 40),
              title: const Text('Logout',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 24,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                // Navigate to login screen or splash
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey[300],
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money,
          size: 36,), label: 'Sales'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite,
          size: 36,), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.list,
          size: 36,), label: 'Grocery List'),
        ],
      ),
    );
  }
}
