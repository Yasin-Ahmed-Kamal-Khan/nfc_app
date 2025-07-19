import 'package:flutter/material.dart';
import 'package:nfc_app/models/tab_item.dart';
import 'package:nfc_app/screens/screens.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  final List<TabItem> _tabs = [
    TabItem(
      title: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    TabItem(
      title: 'Search',
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
    ),
    TabItem(
      title: 'Profile',
      icon: Icons.person_outlined,
      activeIcon: Icons.person,
    ),
    TabItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
    ),
  ];

  final List<Widget> _screens = [
    const HomeTab(),
    const SearchTab(),
    const ProfileTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: _tabs
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                activeIcon: Icon(tab.activeIcon),
                label: tab.title,
              ),
            )
            .toList(),
      ),
    );
  }
}

