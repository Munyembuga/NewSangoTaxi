import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sango/screen/HelpSupportScreen.dart';
import 'package:sango/screen/favoriteDestination.dart';
import 'package:sango/screen/paymentMode.dart';
import 'package:sango/services/storage_service.dart';
import 'package:sango/services/auth_service.dart';
import 'package:sango/screen/login.dart';
import 'package:sango/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:sango/main.dart';
import 'package:sango/services/stats_service.dart';
import 'package:sango/models/overall_stats_model.dart';
import 'package:sango/services/user_service.dart';
import 'package:sango/models/guest_user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSecurityExpanded = false;
  bool _enableDriverCalls = false;
  bool _shareLiveLocation = false;
  bool _privateMode = false;

  // User data variables
  String firstName = '';
  String lastName = '';
  String wallet = '';
  String email = '';
  String status = '';
  bool isLoading = true;

  // Add statistics variables
  OverallStatsModel? _overallStats;
  bool _isLoadingStats = true;
  bool _hasStatsError = false;
  String _statsErrorMessage = '';

  // Add guest user information variables
  bool _isGuestMode = false;
  GuestUserModel? _guestUserInfo;
  bool _isLoadingGuestInfo = false;
  bool _hasGuestInfoError = false;

  // Profile image variables
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
    _loadUserData();
    _fetchOverallStats();
    _loadProfileImage();
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await StorageService.isGuestMode();
    setState(() {
      _isGuestMode = isGuest;
    });

    if (_isGuestMode) {
      _fetchGuestUserInfo();
      _fetchOverallStats();
    }
  }

  Future<void> _fetchGuestUserInfo() async {
    setState(() {
      _isLoadingGuestInfo = true;
      _hasGuestInfoError = false;
    });

    final result = await UserService.getGuestUserInfo();

    if (result['success']) {
      setState(() {
        _guestUserInfo = result['data'];
        _isLoadingGuestInfo = false;

        // Update user profile info from guest data
        firstName = _guestUserInfo?.firstName ?? '';
        lastName = _guestUserInfo?.lastName ?? '';
        email = _guestUserInfo?.email ?? '';
        status = 'Guest';
      });
    } else {
      setState(() {
        _hasGuestInfoError = true;
        _isLoadingGuestInfo = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Skip this method if in guest mode, as we'll handle it in _fetchGuestUserInfo
      if (await StorageService.isGuestMode()) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final userData = await StorageService.getUserData();
      final clientData = await StorageService.getClientData();
      final driverData = await StorageService.getDriverData();
      print("Driver Data: $driverData");
      if (driverData != null) {
        setState(() {
          wallet = driverData['wallet_balance'] ?? '';
          print("Wallet balance: $wallet");
        });
      }
      if (userData != null) {
        setState(() {
          firstName = userData['fname'] ?? '';
          lastName = userData['lname'] ?? '';
          email = userData['email'] ?? '';
          status = userData['sts'] == '1' ? 'Active' : 'Inactive';
          isLoading = false;
        });
      } else if (clientData != null) {
        setState(() {
          firstName = clientData['f_name'] ?? '';
          lastName = clientData['l_name'] ?? '';
          email = clientData['email'] ?? '';
          status = clientData['status'] ?? 'Unknown';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Add method to fetch overall statistics
  Future<void> _fetchOverallStats() async {
    setState(() {
      _isLoadingStats = true;
      _hasStatsError = false;
    });

    final result = await StatsService.getOverallStats();

    if (result['success']) {
      setState(() {
        _overallStats = result['data'];
        _isLoadingStats = false;
      });
    } else {
      setState(() {
        _hasStatsError = true;
        _statsErrorMessage = result['message'];
        _isLoadingStats = false;
      });
    }
  }

  // Load profile image from API or local storage
  Future<void> _loadProfileImage() async {
    // First try to load from local storage
    final cachedUrl = await StorageService.getProfileImageUrl();
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      setState(() {
        _profileImageUrl = cachedUrl;
      });
    }

    // Then fetch from API to get latest
    if (!_isGuestMode) {
      final result = await UserService.getProfileImage();
      if (result['success'] && result['imageUrl'] != null) {
        setState(() {
          _profileImageUrl = result['imageUrl'];
        });
      }
    }
  }

  // Handle profile image update
  Future<void> _handleUpdateProfileImage() async {
    final s = S.of(context)!;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Update Profile Photo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Camera option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5141E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFFF5141E),
                  ),
                ),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5141E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFFF5141E),
                  ),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),

              const SizedBox(height: 10),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    s.cancel,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingImage = true;
        });

        final File imageFile = File(image.path);
        final result = await UserService.updateProfileImage(imageFile);

        setState(() {
          _isUploadingImage = false;
        });

        if (result['success']) {
          setState(() {
            _profileImageUrl = result['imageUrl'];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    result['message'] ?? 'Profile photo updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(result['message'] ?? 'Failed to update profile photo'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Edit profile method
  Future<void> _handleEditProfile() async {
    final s = S.of(context)!;

    // Controllers for the edit fields
    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final emailController = TextEditingController(text: email);

    bool isUpdating = false;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      s.editProfile,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // First Name Field
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        labelText: s.firstName,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF5141E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Last Name Field
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        labelText: s.lastName,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF5141E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: s.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFF5141E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isUpdating
                                ? null
                                : () => Navigator.of(dialogContext).pop(null),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              s.cancel,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isUpdating
                                ? null
                                : () async {
                                    // Validate inputs
                                    if (firstNameController.text
                                            .trim()
                                            .isEmpty ||
                                        lastNameController.text
                                            .trim()
                                            .isEmpty) {
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please fill in all required fields'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() {
                                      isUpdating = true;
                                    });

                                    // Capture values before any async operation
                                    final newFirstName =
                                        firstNameController.text.trim();
                                    final newLastName =
                                        lastNameController.text.trim();
                                    final newEmail =
                                        emailController.text.trim();

                                    // Call the API
                                    final apiResult =
                                        await UserService.updateProfile(
                                      firstName: newFirstName,
                                      lastName: newLastName,
                                      email: newEmail,
                                    );

                                    setModalState(() {
                                      isUpdating = false;
                                    });

                                    // Return the result to be handled outside the modal
                                    Navigator.of(dialogContext).pop({
                                      'success': apiResult['success'],
                                      'message': apiResult['message'],
                                      'firstName': newFirstName,
                                      'lastName': newLastName,
                                      'email': newEmail,
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5141E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isUpdating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    s.save,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    // Handle the result after modal is fully closed
    if (result != null && result['success'] == true) {
      setState(() {
        firstName = result['firstName'];
        lastName = result['lastName'];
        email = result['email'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (result != null && result['success'] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Warning icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Message
              const Text(
                'Are you sure you want to permanently delete your account? This action cannot be undone and all your data will be permanently removed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Delete button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        navigator.pop(); // Close the dialog first

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.red,
                            ),
                          ),
                        );

                        final result = await AuthService.deleteAccount();

                        // Close loading indicator
                        navigator.pop();

                        if (result['success']) {
                          // Show success message
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.green,
                            ),
                          );

                          // Logout and navigate to login
                          await AuthService.logout();
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        } else {
                          // Show error message
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Delete Permanently',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final s = S.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Logout icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF07723D).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  size: 40,
                  color: Color(0xFFF5141E),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                s.logout,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),

              // Message
              Text(
                s.areYouSureLogout,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        s.cancel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),

                  // Logout button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF5141E),
                            ),
                          ),
                        );

                        await AuthService.logout();

                        // Close loading indicator and navigate
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF5141E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        s.logout,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog() {
    final s = S.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar (optional)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Text(
                s.selectLanguage,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Language options
              ...S.supportedLocales.map((locale) {
                final flag = _getFlag(locale.languageCode);
                final languageName =
                    locale.languageCode == 'en' ? s.english : s.french;

                return ListTile(
                  leading: Text(flag, style: const TextStyle(fontSize: 24)),
                  title: Text(languageName),
                  trailing: Icon(
                    Localizations.localeOf(context).languageCode ==
                            locale.languageCode
                        ? Icons.check_circle
                        : null,
                    color: Theme.of(context).primaryColor,
                  ),
                  onTap: () {
                    localeProvider.setLocale(locale);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
              // Cancel button (optional, since users can swipe down or tap outside)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(s.cancel),
                ),
              ),
            ],
          ),
        );
      },
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

    if (isLoading || _isLoadingGuestInfo) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5141E),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top row with title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.yourProfile,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        // Edit profile will be implemented in next version
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Profile info row
                    Row(
                      children: [
                        // Profile avatar with edit icon
                        GestureDetector(
                          onTap:
                              _isGuestMode ? null : _handleUpdateProfileImage,
                          child: Stack(
                            children: [
                              // Avatar with profile image or initials
                              _isUploadingImage
                                  ? Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.2),
                                      backgroundImage:
                                          _profileImageUrl != null &&
                                                  _profileImageUrl!.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  _profileImageUrl!)
                                              : null,
                                      child: _profileImageUrl == null ||
                                              _profileImageUrl!.isEmpty
                                          ? Text(
                                              firstName.isNotEmpty
                                                  ? '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}'
                                                      .toUpperCase()
                                                  : 'U',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                              // Edit icon overlay (only for non-guest users)
                              if (!_isGuestMode)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFF5141E),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 12,
                                      color: Color(0xFFF5141E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$firstName $lastName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              if (_guestUserInfo?.phone != null &&
                                  _guestUserInfo!.phone.isNotEmpty)
                                Text(
                                  _guestUserInfo!.phone,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              if (_guestUserInfo != null)
                                Text(
                                  'Member since: ${_formatDate(_guestUserInfo!.memberSince)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isGuestMode
                                ? Colors.amber
                                : (status.toLowerCase() == 'active'
                                    ? Color(0xFFF5141E)
                                    : Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isGuestMode
                                    ? 'Guest'
                                    : (status.toLowerCase() == 'active'
                                        ? s.active
                                        : s.inactive),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header with real statistics
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Statistics section with loading states
                  _isLoadingStats
                      ? _buildStatsShimmer()
                      : _hasStatsError
                          ? _buildStatsError()
                          : _buildRealStats(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Options
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Edit Profile option - only show for authenticated users
                  if (!_isGuestMode)
                    _buildProfileOption(Icons.person_outline, s.editProfile,
                        _handleEditProfile),
                  _buildProfileOption(Icons.favorite, s.favoriteDestinations,
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const FavoriteDestinationsScreen()),
                    );
                  }),
                  _buildProfileOption(
                      Icons.language, s.language, _showLanguageDialog),
                  _buildProfileOption(Icons.help_outline, s.helpSupport, () {}),
                  if (!_isGuestMode)
                    _buildProfileOption(Icons.person_off, 'Delete Account',
                        _handleDeleteAccount),
                  _buildProfileOption(Icons.logout, s.logout, _handleLogout,
                      isLast: true, isLogout: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build real statistics from API
  Widget _buildRealStats() {
    final s = S.of(context)!;
    final stats = _overallStats?.overallStats;

    if (stats == null) {
      return _buildDefaultStats();
    }

    // Use the formatted month display or month name
    final monthDisplay = _overallStats!.monthName.isNotEmpty
        ? _overallStats!.monthName
        : _overallStats!.formattedCurrentMonth;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickStat(
            s.totalRides, stats.totalRides.toString(), Icons.directions_car),
        _buildQuickStat(s.thisMonth, monthDisplay, Icons.calendar_month),
        _buildQuickStat(s.rating, '${stats.completionRate}%', Icons.star),
      ],
    );
  }

  // Build default stats when no data available
  Widget _buildDefaultStats() {
    final s = S.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildQuickStat(s.totalRides, '0', Icons.directions_car),
        _buildQuickStat(s.thisMonth, '0', Icons.calendar_month),
        _buildQuickStat(s.rating, '0%', Icons.star),
      ],
    );
  }

  // Build shimmer loading for statistics
  Widget _buildStatsShimmer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        3,
        (index) => Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 30,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build error state for statistics
  Widget _buildStatsError() {
    final s = S.of(context)!;
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.grey, size: 40),
        const SizedBox(height: 8),
      Text(
  'No data available to load statistics',
  style: TextStyle(color: Colors.grey, fontSize: 12),
),

        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _fetchOverallStats,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF07723D),
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 30),
          ),
          child: Text('Retry', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFA77D55),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA77D55),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFA77D55),
          size: 30,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFA77D55),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap,
      {bool isLast = false, bool isLogout = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Color(0xFF07723D) : Colors.black87,
              weight: 700,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isLogout ? Color(0xFF07723D) : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isLogout ? Color(0xFF07723D) : Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(IconData icon, String title, String subtitle,
      bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFFA77D55),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFA77D55),
          ),
        ],
      ),
    );
  }

  // Helper method to format date
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}
