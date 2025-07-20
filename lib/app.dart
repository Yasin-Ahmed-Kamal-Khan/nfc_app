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
      title: 'Receive Data',
      icon: Icons.download_outlined,
      activeIcon: Icons.download,
    ),
    TabItem(
      title: 'Enter Data',
      icon: Icons.edit_outlined,
      activeIcon: Icons.edit,
    ),
    TabItem(
      title: 'NFC Upload',
      icon: Icons.upload_outlined,
      activeIcon: Icons.upload,
    ),
    TabItem(
      title: 'NFC Transfer',
      icon: Icons.nfc_outlined,
      activeIcon: Icons.nfc,
    ),
  ];

  final List<Widget> _screens = [
    const EnterDataTab(),
    const NfcQrScannerScreen(),
    const JsonTransmitTab(),
    const JsonQrTab(),
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
        unselectedLabelStyle: TextStyle(fontSize: 11.0),
        selectedLabelStyle: TextStyle(fontSize: 12.5),
      ),
    );
  }
}
