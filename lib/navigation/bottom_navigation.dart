import 'package:flutter/material.dart';
import 'package:sango/screen/homeScreen.dart';
// Other imports

class AppBottomNavigation extends StatefulWidget {
  final Function(Locale)? setLocale;

  const AppBottomNavigation({Key? key, this.setLocale}) : super(key: key);

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(setLocale: widget.setLocale),
      // Other screens...
      ProfileScreen(setLocale: widget.setLocale),
    ];
  }

  // Rest of the navigation implementation...
}
