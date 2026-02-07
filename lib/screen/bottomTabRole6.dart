import 'package:flutter/material.dart';
import 'role6/services_screen.dart';
import 'role6/history_screen.dart';
import 'role6/profile_screen.dart';

class BottomNavigationRole6 extends StatefulWidget {
  @override
  _BottomNavigationRole6State createState() => _BottomNavigationRole6State();
}

class _BottomNavigationRole6State extends State<BottomNavigationRole6> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    ServicesScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF07723D),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
