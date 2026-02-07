import 'package:flutter/material.dart';
import 'package:sango/l10n/l10n.dart'; // Add this import
import 'package:sango/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String errorMessage = '';
  bool isLoading = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Step management: 1 = Email, 2 = OTP, 3 = New Password
  int currentStep = 1;
  String userEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result =
          await AuthService.sendOTP(email: _emailController.text.trim());

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        setState(() {
          userEmail = _emailController.text.trim();
          currentStep = 2;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.of(context)!.resetTokenSent),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          errorMessage = result['message'] ?? S.of(context)!.failedToSendToken;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '${S.of(context)!.error}: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await AuthService.verifyOTP(
        email: userEmail,
        otp: _otpController.text.trim(),
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        setState(() {
          currentStep = 3;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? S.of(context)!.tokenVerified),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          errorMessage = result['message'] ?? S.of(context)!.invalidToken;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '${S.of(context)!.error}: ${e.toString()}';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await AuthService.resetPassword(
        email: userEmail,
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      setState(() {
        isLoading = false;
      });

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(result['message'] ?? S.of(context)!.passwordResetSuccess),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate back to login screen
        Navigator.pop(context);
      } else {
        setState(() {
          errorMessage =
              result['message'] ?? S.of(context)!.passwordResetFailed;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = '${S.of(context)!.error}: ${e.toString()}';
      });
    }
  }

  void _goBackStep() {
    setState(() {
      if (currentStep > 1) {
        currentStep--;
        errorMessage = '';
      }
    });
  }

  String _getStepTitle() {
    final s = S.of(context)!;
    switch (currentStep) {
      case 1:
        return s.resetPassword;
      case 2:
        return s.verifyOTP;
      case 3:
        return s.newPassword;
      default:
        return s.resetPassword;
    }
  }

  String _getStepDescription() {
    final s = S.of(context)!;
    switch (currentStep) {
      case 1:
        return s.enterEmailForReset;
      case 2:
        return s.enterTokenSentTo(userEmail);
      case 3:
        return s.createNewPassword;
      default:
        return '';
    }
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(1, currentStep >= 1),
        _buildStepLine(currentStep >= 2),
        _buildStepCircle(2, currentStep >= 2),
        _buildStepLine(currentStep >= 3),
        _buildStepCircle(3, currentStep >= 3),
      ],
    );
  }

  Widget _buildStepCircle(int step, bool isActive) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFF5141E) : Colors.grey.shade300,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Container(
      width: 40,
      height: 2,
      color: isActive ? const Color(0xFFF5141E) : Colors.grey.shade300,
    );
  }

  Widget _buildEmailStep() {
    final s = S.of(context)!;
    return Column(
      children: [
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: s.emailAddress,
            hintStyle:
                const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            prefixIcon: const Icon(Icons.email, size: 20),
          ),
          style: const TextStyle(fontWeight: FontWeight.w300),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return s.enterEmail;
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return s.enterValidEmail;
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5141E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(s.sendResetToken, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildOTPStep() {
    final s = S.of(context)!;
    return Column(
      children: [
        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            hintText: s.enterResetToken,
            hintStyle:
                const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            prefixIcon: const Icon(Icons.security, size: 20),
          ),
          style: const TextStyle(fontWeight: FontWeight.w300),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return s.enterResetToken;
            }
            if (value.length < 4) {
              return s.tokenMinLength;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: isLoading ? null : _sendOTP,
          child: Text(
            s.resendResetToken,
            style: const TextStyle(
              color: Color(0xFFF5141E),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5141E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(s.verifyResetToken,
                    style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    final s = S.of(context)!;
    return Column(
      children: [
        TextFormField(
          controller: _newPasswordController,
          decoration: InputDecoration(
            hintText: s.newPassword,
            hintStyle:
                const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            prefixIcon: const Icon(Icons.lock, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _newPasswordVisible = !_newPasswordVisible;
                });
              },
            ),
          ),
          style: const TextStyle(fontWeight: FontWeight.w300),
          obscureText: !_newPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return s.enterNewPassword;
            }
            if (value.length < 6) {
              return s.passwordMinLength;
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            hintText: s.confirmNewPassword,
            hintStyle:
                const TextStyle(fontWeight: FontWeight.w300, fontSize: 14),
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.grey, width: 1),
            ),
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: Colors.grey,
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
          ),
          style: const TextStyle(fontWeight: FontWeight.w300),
          obscureText: !_confirmPasswordVisible,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return s.confirmPassword;
            }
            if (value != _newPasswordController.text) {
              return s.passwordsDoNotMatch;
            }
            return null;
          },
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading ? null : _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5141E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(s.resetPassword, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _getStepTitle(),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF5141E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (currentStep > 1) {
              _goBackStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Step Indicator
                    _buildStepIndicator(),
                    const SizedBox(height: 30),

                    // Step Description
                    Text(
                      _getStepDescription(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Error message
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Step Content
                    if (currentStep == 1) _buildEmailStep(),
                    if (currentStep == 2) _buildOTPStep(),
                    if (currentStep == 3) _buildNewPasswordStep(),
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
