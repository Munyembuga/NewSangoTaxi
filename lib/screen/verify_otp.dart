import 'package:flutter/material.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/services/auth_service.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  _VerifyOtpScreenState createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool isLoading = false;
  bool isResending = false;
  String errorMessage = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await AuthService.verifyOtp(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result['data']['message'] ?? 'OTP verified successfully'),
          backgroundColor: Colors.green,
        ),
      );

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

  Future<void> _resendOtp() async {
    setState(() {
      isResending = true;
      errorMessage = '';
    });

    final result = await AuthService.resendOtp(email: widget.email);

    setState(() {
      isResending = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['data']['message'] ?? 'OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the OTP field for new OTP
      _otpController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF07723D),
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
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mail_outline,
                      size: 80,
                      color: Color(0xFF07723D),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Verify Your Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "We've sent a verification code to",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF07723D),
                      ),
                    ),
                    SizedBox(height: 30),

                    // OTP field
                    TextFormField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        labelText: 'Enter OTP',
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: Colors.grey, width: 2),
                        ),
                        prefixIcon: Icon(Icons.security, size: 20),
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the OTP';
                        }
                        if (value.length != 6) {
                          return 'OTP must be 6 digits';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Please enter a valid OTP';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 30),

                    // Error message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          errorMessage,
                          style: TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Verify button
                    isLoading
                        ? CircularProgressIndicator(color: Color(0xFF07723D))
                        : ElevatedButton(
                            onPressed: _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF07723D),
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text("Verify OTP"),
                          ),

                    SizedBox(height: 20),

                    // Resend OTP
                    isResending
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Color(0xFF07723D),
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Resending...",
                                style: TextStyle(
                                  color: Color(0xFF07723D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : TextButton(
                            onPressed: _resendOtp,
                            child: Text(
                              "Didn't receive the code? Resend",
                              style: TextStyle(
                                color: Color(0xFFF5141E),
                                fontWeight: FontWeight.w600,
                              ),
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
