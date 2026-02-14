import 'package:flutter/material.dart';
import 'package:sango/screen/profileScreen.dart';
import 'package:sango/screen/trackingScreen.dart';
import 'package:sango/screen/homeScreen.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/screen/mainRentScreen.dart';
import 'package:sango/screen/ordersScreen.dart';
import 'package:sango/l10n/l10n.dart';

class BottomNavigation extends StatefulWidget {
  final int initialIndex;
  final bool isGuestMode;

  const BottomNavigation({
    Key? key,
    this.initialIndex = 0,
    this.isGuestMode = false,
  }) : super(key: key);

  @override
  State<BottomNavigation> createState() => _BottomNavigationScreenState();
}

class _BottomNavigationScreenState extends State<BottomNavigation>
    with WidgetsBindingObserver {
  late int _selectedIndex;
  late bool _isGuestMode;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      _selectedIndex = widget.initialIndex.clamp(0, 4); // Ensure valid index
      _isGuestMode = widget.isGuestMode;

      // Add error handling for initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkGuestMode();
        }
      });
    } catch (e) {
      print('BottomNavigation init error: $e');
      _selectedIndex = 0; // Safe fallback
      _isGuestMode = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Handle app lifecycle changes safely
    if (state == AppLifecycleState.resumed && mounted) {
      // App resumed, ensure everything is still valid
      _validateState();
    }
  }

  void _validateState() {
    try {
      if (!mounted) return;

      // Ensure selected index is valid
      if (_selectedIndex < 0 || _selectedIndex > 4) {
        setState(() {
          _selectedIndex = 0;
        });
      }
    } catch (e) {
      print('State validation error: $e');
    }
  }

  Future<void> _checkGuestMode() async {
    if (!widget.isGuestMode) {
      final isGuest = await StorageService.isGuestMode();
      if (isGuest) {
        setState(() {
          _isGuestMode = true;
        });
      }
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const TrackingScreen();
      case 2:
        return const MainRentScreen();
      case 3:
        return const OrdersScreen();
      case 4:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }

  void _onItemTapped(int index) {
    // if (_isGuestMode && index == 3) {
    //   _showLoginPrompt();
    //   return;
    // }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showLoginPrompt() {
    final s = S.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(s.loginRequired),
          content: Text(s.loginMessage),
          actions: <Widget>[
            TextButton(
              child: Text(s.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                s.login,
                style: const TextStyle(color: Color(0xFFF5141E)),
              ),
              onPressed: () {
                StorageService.clearGuestSession().then((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        backgroundColor: const Color(0xFFF5141E),
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
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: s.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_car),
            label: s.ride,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.car_rental),
            label: s.rent,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: s.myOrders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_2_outlined),
            label: s.profile,
          ),
        ],
      ),
    );
  }
}
