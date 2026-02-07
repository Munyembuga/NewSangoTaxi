import 'package:flutter/material.dart';
import 'package:sango/screen/trackingScreen.dart';
import 'package:sango/screendriver/profiledriver.dart';
import 'package:sango/screendriver/toptabdriver/mainToptabdriver.dart';
import 'package:sango/screens/admin/notification_design_screen.dart';

class BottomNavigationDriver extends StatefulWidget {
  final int initialIndex; // Add this parameter

  const BottomNavigationDriver({Key? key, this.initialIndex = 0})
      : super(key: key);

  @override
  State<BottomNavigationDriver> createState() =>
      _BottomNavigationDriverScreenState();
}

class _BottomNavigationDriverScreenState extends State<BottomNavigationDriver> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // Set the initial tab
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        backgroundColor: Color(0xFFF5141E),
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        showUnselectedLabels: true, //
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.home),
          //   label: 'Home',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Ride',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.notification_important_outlined),
          //   label: 'Notification',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return rideScreenDriver();

      // case 1:
      //   return const NotificationDesignScreen();
      case 1:
        return const ProfileDriverScreen();
      default:
        return const TrackingScreen();
    }
  }
}
