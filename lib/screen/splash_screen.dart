import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sango/screen/bottomTab.dart';
import 'package:sango/screen/bottomTabRole6.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/screendriver/bottomNavigationdriver.dart';
import 'package:sango/services/authDriverServices.dart';
import 'package:sango/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  final Function(Locale)? setLocale;

  const SplashScreen({Key? key, this.setLocale}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Give the splash screen some time to display
    await Future.delayed(const Duration(seconds: 2));

    // Check if user is logged in
    final isLoggedIn = await StorageService.isLoggedIn();

    if (!isLoggedIn) {
      _navigateToLogin();
      return;
    }

    // User is logged in, now check role
    final userRole = await StorageService.getUserRole();

    if (userRole == '3') {
      // Driver role - start location updates
      await _startDriverLocationService();
      _navigateToDriverScreen();
    } else if (userRole == '6') {
      // Role 6 user
      _navigateToRole6Screen();
    } else {
      // Client or other role
      _navigateToClientScreen();
    }
  }

  Future<void> _startDriverLocationService() async {
    try {
      // Start the location service for drivers
      await DriverLocationService.instance.startLocationUpdates();
      print('Driver location service started');
    } catch (e) {
      print('Error starting location service: $e');
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _navigateToDriverScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavigationDriver()),
    );
  }

  void _navigateToRole6Screen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavigationRole6()),
    );
  }

  void _navigateToClientScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => BottomNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5141E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // You can add your app logo here
            const Icon(
              Icons.local_taxi,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Sango Taxi',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
