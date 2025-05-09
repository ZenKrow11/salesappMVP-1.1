import 'package:flutter/material.dart';
import 'package:sales_app_mvp/pages/account_page.dart';
import 'package:sales_app_mvp/pages/settings_page.dart';
import 'package:sales_app_mvp/pages/contact_page.dart';

class SecondaryAppScreen extends StatefulWidget {
  final int initialIndex;
  const SecondaryAppScreen({super.key, this.initialIndex = 0});

  @override
  State<SecondaryAppScreen> createState() => _SecondaryAppScreenState();
}

class _SecondaryAppScreenState extends State<SecondaryAppScreen> {
  late int _currentIndex;

  final List<Widget> _pages = [
    AccountPage(),
    SettingsPage(),
    ContactPage(),
  ];

  final List<String> _titles = [
    'Account',
    'Settings',
    'Contact',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
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
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 36), label: 'Account'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 36), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline, size: 36), label: 'Contact'),
        ],
      ),
    );
  }
}
