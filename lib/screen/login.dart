import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:sango/main.dart';
import 'package:sango/screen/bottomTab.dart';
import 'package:sango/screen/bottomTabRole6.dart';
import 'package:sango/screen/forgetPassword.dart';
import 'package:sango/screen/registeraccount.dart';
import 'package:sango/screendriver/bottomNavigationdriver.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';
  bool isLoading = false;
  bool _passwordVisible = false;
  String callCenterNumber = '+236 73 08 08 08'; // Default call center number

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  Future<void> _loadCompanyData() async {
    try {
      final companyData = await StorageService.getCompanyData();
      if (companyData != null && companyData['call_center_number'] != null) {
        setState(() {
          callCenterNumber = companyData['call_center_number'];
        });
      }
    } catch (e) {
      print('Error loading company data: $e');
    }
  }

  Future<void> _callCenter() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: callCenterNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot make phone call to $callCenterNumber'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error making phone call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await AuthService.login(
      phoneNumber: '+236${_phoneController.text.trim()}',
      password: _passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      // Data is already saved in AuthService.login(), no need to save again
      final userData = result['data']['user'];
      final userRole = userData['role'].toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['data']['message'] ?? 'Login successful'),
          backgroundColor: Colors.green,
        ),
      );

      // Check user role and navigate accordingly
      if (userRole == '3') {
        // Navigate to driver screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationDriver(),
          ),
        );
      } else if (userRole == '6') {
        // Navigate to role 6 screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigationRole6(),
          ),
        );
      } else {
        // Navigate to regular bottom navigation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigation(),
          ),
        );
      }
    } else {
      setState(() {
        errorMessage = result['message'];
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForgotPasswordScreen(),
      ),
    );
  }

  String _getFlag(String code) {
    switch (code) {
      case 'fr':
        return '🇫🇷';
      case 'en':
      default:
        return '🇺🇸';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final locale = Localizations.localeOf(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(s.appName,
            style: const TextStyle(
              color: Colors.white,
            )),
        backgroundColor: const Color(0xFFF5141E),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 25.0), // Adjust as needed
            child: DropdownButton<Locale>(
              value: locale,
              icon: const Icon(Icons.language, color: Colors.white),
              underline: Container(),
              dropdownColor: const Color(0xFFF5141E),
              items: S.supportedLocales
                  .map<DropdownMenuItem<Locale>>((Locale locale) {
                final flag = _getFlag(locale.languageCode);
                return DropdownMenuItem<Locale>(
                  value: locale,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        locale.languageCode.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) {
                  localeProvider.setLocale(newLocale);
                }
              },
            ), // IconButton(
            //   icon: const Icon(Icons.notifications),
            //   onPressed: () {
            //     if (_isGuestMode) {
            //       _showLoginPrompt();
            //     } else {
            //       // Handle notifications
            //     }
            //   },
            // ),
            // if (_isGuestMode)
            //   Padding(
            //     padding: const EdgeInsets.only(right: 8.0),
            //     child: Chip(
            //       label: Text(l10n.guestMode),
            //       backgroundColor: Colors.amber.shade100,
            //       labelStyle: const TextStyle(fontSize: 12),
            //     ),
            //   )
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? screenSize.width * 0.25 : 16.0,
              vertical: 16.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : double.infinity,
                minHeight: 0, // Ensure flexible height
              ),
              padding: EdgeInsets.all(
                isTablet ? 32.0 : 20.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      s.signIn,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: isTablet ? 18 : 14,
                      ),
                    ),
                    SizedBox(height: isTablet ? 40 : 30),

                    // Phone input field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: s.phoneNumber,
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.w300, 
                            fontSize: isTablet ? 14 : 12),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 1),
                        ),
                        errorStyle: TextStyle(
                            fontWeight: FontWeight.w300, 
                            fontSize: isTablet ? 14 : 12),
                        prefixIcon: Icon(
                          Icons.phone,
                          size: isTablet ? 18 : 14,
                        ),
                        prefixText: '+236 ',
                      ),
                      style: TextStyle(
                          fontWeight: FontWeight.w300, 
                          fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12),
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.enterPhoneNumber;
                        }
                        if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                          return 'Please enter exactly 8 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password input field with visibility toggle
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        hintText: s.enterPassword,
                        hintStyle: const TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 12),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide:
                              const BorderSide(color: Colors.grey, width: 1),
                        ),
                        errorStyle: TextStyle(
                            fontWeight: FontWeight.w300, 
                            fontSize: isTablet ? 14 : 12),
                        labelStyle: TextStyle(
                            fontWeight: FontWeight.w300, 
                            fontSize: isTablet ? 14 : 12),
                        prefixIcon: Icon(
                          Icons.lock,
                          size: isTablet ? 18 : 14,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.grey,
                            size: isTablet ? 18 : 14,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                          tooltip: _passwordVisible
                              ? s.hidePassword
                              : s.showPassword,
                        ),
                      ),
                      obscureText: !_passwordVisible,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.enterPassword;
                        }
                        return null;
                      },
                    ),

                    // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: isLoading ? null : _navigateToForgotPassword,
                        child: Text(
                          s.forgotPassword,
                          style: const TextStyle(
                            color: Color(0xFFF5141E),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Error message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login button
                    Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Color(0xFFF5141E))
                          : ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF5141E),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 100 : 80, 
                                    vertical: isTablet ? 15 : 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(s.signIn,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12
                                  )),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Create account row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          s.dontHaveAccount,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegistrationNewAccount(),
                              ),
                            );
                          },
                          child: Text(
                            s.createAccount,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14 : 12),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 20 : 15),
                    
                    // Call center section
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            s.needHelp,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isTablet ? 14 : 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          GestureDetector(
                            onTap: _callCenter,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 8 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.phone,
                                    color: Colors.white,
                                    size: isTablet ? 18 : 16,
                                  ),
                                  SizedBox(width: isTablet ? 8 : 6),
                                  Text(
                                    '${s.callCenter}: $callCenterNumber',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isTablet ? 12 : 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
