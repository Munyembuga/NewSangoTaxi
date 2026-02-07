import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import 'package:sango/screen/bottomTab.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';

class RegistrationNewAccount extends StatefulWidget {
  @override
  _RegistrationNewAccountState createState() => _RegistrationNewAccountState();
}

class _RegistrationNewAccountState extends State<RegistrationNewAccount> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String errorMessage = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await AuthService.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phoneNumber: '+236${_phoneController.text.trim()}',
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['data']['message'] ??
              S.of(context)!.registrationSuccessful),
          backgroundColor: Color(0xFFF5141E),
        ),
      );

      // Navigate directly to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    } else {
      setState(() {
        errorMessage = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!; // Get localization

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.createNewAccount,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFF5141E),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.completeYourProfile,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      s.provideDetailsForAccount,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // First Name field
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: s.firstName,
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
                        prefixIcon: const Icon(Icons.person, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.enterFirstName;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // Last Name field
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: s.lastName,
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
                        prefixIcon: const Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.enterLastName;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: s.phoneNumber,
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
                        prefixIcon: const Icon(Icons.phone, size: 20),
                        prefixText: '+236 ',
                        hintText: '12345678',
                      ),
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
                    const SizedBox(height: 15),
                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: '${s.emailAddress} (Optional)',
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
                        prefixIcon: const Icon(Icons.email, size: 20),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        // Email is optional, only validate format if provided
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return s.enterValidEmail;
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: s.password,
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
                        prefixIcon: const Icon(Icons.lock, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.enterPassword;
                        }
                        if (value.length < 6) {
                          return s.passwordMinLength;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 15),

                    // Confirm Password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: s.confirmPassword,
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
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return s.confirmPassword;
                        }
                        if (value != _passwordController.text) {
                          return s.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    // Error message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Submit button
                    isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFFA77D55))
                        : ElevatedButton(
                            onPressed: _registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5141E),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(s.createAccount),
                          ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.alreadyHaveAccount),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            s.login,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                        ),
                      ],
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
