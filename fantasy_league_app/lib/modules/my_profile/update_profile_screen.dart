import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:flutter/foundation.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/validator/validator.dart';
import 'package:fantasyleague/utils/dialogs.dart';
import 'package:fantasyleague/utils/notification_service.dart';
import 'package:fantasyleague/modules/login/email_verification_screen.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';

class UpdateProfileScreen extends StatefulWidget {
  final UserData? loginUserData;

  const UpdateProfileScreen({super.key, this.loginUserData});
  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  UserData loginUserData = UserData();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isProcessing = false;
  bool _isSubmitting = false; // Prevent concurrent submissions
  var imageUrl = '';
  var nameController = TextEditingController();
  var emailController = TextEditingController();
  final nameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  File? _image;
  final _formKey = GlobalKey<FormState>();

  // Track original values to disable button until changes
  String _originalName = '';
  String _originalEmail = '';
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    if (widget.loginUserData != null) {
      loginUserData = widget.loginUserData!;
      nameController.text = loginUserData.name ?? '';
      emailController.text = loginUserData.email ?? '';
      imageUrl = loginUserData.image ?? '';

      // Store original values
      _originalName = loginUserData.name ?? '';
      _originalEmail = loginUserData.email ?? '';
    }

    // Load latest profile from cache and refresh from API so avatar/name are up-to-date
    _loadLatestProfile();

    // Add listeners to detect changes
    nameController.addListener(_checkForChanges);
    emailController.addListener(_checkForChanges);
  }

  Future<void> _loadLatestProfile() async {
    try {
      // Try cached summary first for instant UI
      final cached = await MySharedPreferences().getCacheJson('user_summary');

      if (cached != null && cached['profile'] != null) {
        try {
          final profileMap = Map<String, dynamic>.from(cached['profile'] ?? {});
          if (profileMap.isNotEmpty) {
            final fresh = UserData.fromJson(profileMap);

            setState(() {
              loginUserData = fresh;
              nameController.text = loginUserData.name ?? '';
              emailController.text = loginUserData.email ?? '';
              imageUrl = loginUserData.image ?? '';
              _originalName = loginUserData.name ?? '';
              _originalEmail = loginUserData.email ?? '';
            });
          }
        } catch (e) {
          // Silently continue if cache load fails
        }
      }

      // Then refresh from backend to get any newly uploaded avatar
      try {
        final profileDetail = await ApiProvider().getProfile();

        final UserData? apiUser = profileDetail.data;
        if (apiUser != null) {
          setState(() {
            loginUserData = apiUser;
            nameController.text = loginUserData.name ?? '';
            emailController.text = loginUserData.email ?? '';
            imageUrl = loginUserData.image ?? '';
            _originalName = loginUserData.name ?? '';
            _originalEmail = loginUserData.email ?? '';
          });
        }
      } catch (e) {
        // Silently continue if API call fails
      }
    } catch (e) {
      // Silently continue if unexpected error
    }
  }

  void _checkForChanges() {
    final nameChanged = nameController.text != _originalName;
    final emailChanged = emailController.text != _originalEmail;
    final imageChanged = _image != null;

    final changed = nameChanged || emailChanged || imageChanged;

    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    nameController.removeListener(_checkForChanges);
    emailController.removeListener(_checkForChanges);
    nameController.dispose();
    emailController.dispose();
    nameFocusNode.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: isProcessing,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AllCoustomTheme.getThemeData().primaryColor,
              AllCoustomTheme.getThemeData().primaryColor,
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: AppBar().preferredSize.height,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: AppBar().preferredSize.height,
                          width: AppBar().preferredSize.height,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.arrow_back,
                            color: AllCoustomTheme.getThemeData().primaryColor,
                            size: 28,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Update Profile',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: AllCoustomTheme.getThemeData()
                                  .colorScheme
                                  .surface,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: AppBar().preferredSize.height,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 60),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Stack(
                          children: <Widget>[
                            Container(
                              height: 96,
                              width: 96,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                      color: Colors.black45,
                                      offset: Offset(1.1, 1.1),
                                      blurRadius: 3.0),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(48.0),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.transparent,
                                      child: _image == null
                                          ? loginUserData.image == '' ||
                                                  loginUserData.image == null
                                              ? Container(
                                                  padding:
                                                      const EdgeInsets.all(0.0),
                                                  child: Image.asset(
                                                    ConstanceData.playerImage,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                              : AvatarImage(
                                                  sizeValue: 100,
                                                  radius: 100,
                                                  isCircle: true,
                                                  imageUrl:
                                                      loginUserData.image ?? '',
                                                )
                                          : Image.file(
                                              _image!,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 70.0,
                              top: 70.0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.transparent,
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                        color: Colors.black54,
                                        offset: Offset(1.1, 1.1),
                                        blurRadius: 2.0),
                                  ],
                                ),
                                height: 24,
                                width: 24,
                                child: FloatingActionButton(
                                  onPressed: () async {
                                    final ImagePicker picker = ImagePicker();
                                    final XFile? picked =
                                        await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked != null && mounted) {
                                      setState(() {
                                        _image = File(picked.path);
                                      });
                                      _checkForChanges();
                                    }
                                  },
                                  backgroundColor: Colors.white,
                                  mini: true,
                                  elevation: 0,
                                  child: Icon(Icons.camera_alt,
                                      color: AllCoustomTheme.getThemeData()
                                          .primaryColor,
                                      size: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextFormField(
                                        controller: nameController,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                          color: AllCoustomTheme
                                              .getBlackAndWhiteThemeColors(),
                                        ),
                                        autofocus: false,
                                        focusNode: nameFocusNode,
                                        keyboardType: TextInputType.text,
                                        decoration: const InputDecoration(
                                          labelText: 'Name',
                                          icon: Padding(
                                            padding: EdgeInsets.only(top: 16),
                                          ),
                                        ),
                                        onEditingComplete: () {
                                          FocusScope.of(context)
                                              .requestFocus(emailFocusNode);
                                        },
                                        validator: _validateName,
                                        onSaved: (value) {
                                          loginUserData.name = value;
                                        },
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    TextFormField(
                                      controller: emailController,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getBlackAndWhiteThemeColors(),
                                      ),
                                      autofocus: false,
                                      focusNode: emailFocusNode,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        helperText:
                                            'Changing email will require verification',
                                        icon: Padding(
                                          padding: EdgeInsets.only(top: 14),
                                        ),
                                      ),
                                      validator: _validateEmail,
                                      onSaved: (value) {
                                        loginUserData.email = value;
                                      },
                                    ),
                                    const SizedBox(
                                      height: 32,
                                    ),
                                    Container(
                                      height: 40,
                                      padding: const EdgeInsets.only(
                                          left: 50, right: 50, bottom: 0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _hasChanges
                                              ? AllCoustomTheme.getThemeData()
                                                  .primaryColor
                                              : Colors.grey.withAlpha(150),
                                          borderRadius:
                                              BorderRadius.circular(4.0),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(128),
                                                offset: const Offset(0, 1),
                                                blurRadius: 5.0),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                            onTap:
                                                (_hasChanges && !_isSubmitting)
                                                    ? () {
                                                        FocusScope.of(context)
                                                            .requestFocus(
                                                                FocusNode());
                                                        _submit();
                                                      }
                                                    : null,
                                            child: const Center(
                                              child: Text(
                                                'Update Profile',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: ConstanceData
                                                      .SIZE_TITLE12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name can not be empty';
    } else {
      return null;
    }
  }

  String? _validateEmail(String? value) {
    if (value!.isEmpty) {
      return 'Email can not be empty';
    } else {
      if (!Validators().emailValidator(value)) {
        return 'Email is not valid';
      } else {
        return null;
      }
    }
  }

  void _submit() async {
    // Prevent concurrent submissions
    if (_isSubmitting) return;
    _isSubmitting = true;

    try {
      FocusScope.of(context).requestFocus(FocusNode());

      if (_formKey.currentState!.validate() == false) {
        _isSubmitting = false;
        return;
      }

      _formKey.currentState!.save();
      final name = nameController.text.trim();
      final email = emailController.text.trim();

      if (!mounted) {
        _isSubmitting = false;
        return;
      }

      setState(() {
        isProcessing = true;
      });

      try {
        final nameChanged = name != _originalName;
        final emailChanged = email != _originalEmail;

        // Only send fields that actually changed so backend will perform
        // a partial update. This allows updating only name, or only email,
        // or only avatar independently.
        final sendName = nameChanged ? name : null;
        final sendEmail = emailChanged ? email : null;
        final sendAvatar = _image; // null if unchanged

        if (kDebugMode) {
          debugPrint(
              '[UPDATE] Original email: $_originalEmail, New email: $email, Changed: $emailChanged');
          debugPrint('[UPDATE] Sending email: $sendEmail');
        }

        final resp = await ApiProvider().updateProfile(
          name: sendName,
          email: sendEmail,
          avatarFile: sendAvatar,
          onSendProgress: (sent, total) {
            // Upload progress tracked silently
          },
        );

        if (!mounted) {
          _isSubmitting = false;
          return;
        }

        if (resp.isEmpty) {
          throw Exception('Empty response from server');
        }

        // ApiProvider.updateProfile() returns the user data directly (not wrapped in 'data' key)
        // So we can use resp directly as the user object
        final updatedUser = UserData.fromJson(resp);

        // Check if email was changed according to backend response
        // The backend sends email_changed=true if email was actually updated
        final emailVerificationNeeded = resp['email_changed'] == true;

        if (kDebugMode) {
          debugPrint(
              '[UPDATE] Email verification needed: $emailVerificationNeeded');
        }

        if (!mounted) {
          _isSubmitting = false;
          return;
        }

        // Show success message using SnackBar instead of Fluttertoast to avoid toast errors
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        try {
          // Preserve any existing wallet data in cache when updating profile
          Map<String, dynamic>? cached =
              await MySharedPreferences().getCacheJson('user_summary');
          Map<String, dynamic> wallet = {};
          try {
            if (cached != null && cached['wallet'] != null) {
              wallet = Map<String, dynamic>.from(cached['wallet']);
            }
          } catch (_) {
            wallet = {};
          }

          final Map<String, dynamic> _summary = {
            'profile': updatedUser.toJson(),
            'wallet': wallet,
            'fetched_at': DateTime.now().toIso8601String(),
          };
          await MySharedPreferences().setCacheJson('user_summary', _summary);
          UserSummaryNotifier.update(_summary);

          if (kDebugMode) {
            // Profile updated and cache refreshed
          }
        } catch (e) {
          if (kDebugMode) {
            // Cache update failed, but profile was updated on backend
          }
        }

        if (!mounted) {
          _isSubmitting = false;
          return;
        }

        if (emailVerificationNeeded) {
          final verified = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(
                email: email,
                redirectToLogin: false,
              ),
            ),
          );

          if (!mounted) {
            _isSubmitting = false;
            return;
          }

          if (verified == true) {
            try {
              final profileDetail = await ApiProvider().getProfile();
              if (!mounted) {
                _isSubmitting = false;
                return;
              }
              final freshUser = profileDetail.data ?? updatedUser;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email verified and profile updated'),
                  duration: Duration(seconds: 2),
                ),
              );
              try {
                // Preserve existing wallet when updating with fresh profile
                Map<String, dynamic>? cached =
                    await MySharedPreferences().getCacheJson('user_summary');
                Map<String, dynamic> wallet = {};
                try {
                  if (cached != null && cached['wallet'] != null) {
                    wallet = Map<String, dynamic>.from(cached['wallet']);
                  }
                } catch (_) {
                  wallet = {};
                }

                final Map<String, dynamic> _summary = {
                  'profile': freshUser.toJson(),
                  'wallet': wallet,
                  'fetched_at': DateTime.now().toIso8601String(),
                };
                await MySharedPreferences()
                    .setCacheJson('user_summary', _summary);
                UserSummaryNotifier.update(_summary);
              } catch (_) {}
              if (mounted) {
                // Use small delay to ensure navigation stack is ready
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  _isSubmitting = false;
                  Navigator.pop(context, freshUser);
                  return;
                }
              }
            } catch (e) {
              if (mounted) {
                AppNotification.showError(
                  context,
                  title: 'Profile Update Failed',
                  message: 'Could not fetch updated profile. Please try again.',
                );
              }
              _isSubmitting = false;
              return;
            }
          } else {
            if (!mounted) {
              _isSubmitting = false;
              return;
            }
            // Reset flag before showing dialog to allow retry
            _isSubmitting = false;

            final bool? dialogResult = await Dialogs.showDialogWithTwoButtons(
              context,
              'Email Not Verified',
              'Your new email is not verified. Verify now or continue without verifying.',
              button1Label: 'Verify Now',
              button2Label: 'Continue',
            );

            if (dialogResult == true) {
              // Verify Now flow
              _isSubmitting = true;
              try {
                final retry = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmailVerificationScreen(
                      email: email,
                      redirectToLogin: false,
                    ),
                  ),
                );

                if (!mounted) {
                  _isSubmitting = false;
                  return;
                }

                if (retry == true) {
                  try {
                    final profileDetail = await ApiProvider().getProfile();
                    if (!mounted) {
                      _isSubmitting = false;
                      return;
                    }
                    final freshUser = profileDetail.data ?? updatedUser;

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email verified and profile updated'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    try {
                      Map<String, dynamic>? cached = await MySharedPreferences()
                          .getCacheJson('user_summary');
                      Map<String, dynamic> wallet = {};
                      try {
                        if (cached != null && cached['wallet'] != null) {
                          wallet = Map<String, dynamic>.from(cached['wallet']);
                        }
                      } catch (_) {
                        wallet = {};
                      }

                      final Map<String, dynamic> _summary = {
                        'profile': freshUser.toJson(),
                        'wallet': wallet,
                        'fetched_at': DateTime.now().toIso8601String(),
                      };
                      await MySharedPreferences()
                          .setCacheJson('user_summary', _summary);
                      UserSummaryNotifier.update(_summary);
                    } catch (_) {}

                    if (mounted) {
                      _isSubmitting = false;
                      Navigator.pop(context, freshUser);
                      return;
                    }
                  } catch (e) {
                    if (mounted) {
                      AppNotification.showError(
                        context,
                        title: 'Profile Update Failed',
                        message:
                            'Could not fetch updated profile. Please try again.',
                      );
                    }
                    _isSubmitting = false;
                    return;
                  }
                } else {
                  // User cancelled verification
                  _isSubmitting = false;
                }
              } catch (e) {
                if (mounted) debugPrint('Error in Verify Now: $e');
                _isSubmitting = false;
              }
            } else if (dialogResult == false) {
              // Continue without verification
              if (mounted) {
                _isSubmitting = false;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Profile updated. Email verification pending.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              }
            }
            return;
          }
        } else {
          if (mounted) {
            _isSubmitting = false;
            Navigator.pop(context, updatedUser);
          }
        }
      } on DioException catch (e) {
        if (!mounted) {
          _isSubmitting = false;
          return;
        }

        String msg = 'Failed to update profile';

        // Handle 401 Unauthenticated specifically
        if (e.response?.statusCode == 401) {
          if (kDebugMode) {
            // Unauthenticated - user session may have expired
          }
          msg = 'Authentication failed. Please log in again.';
        } else if (e.response != null && e.response?.statusCode == 422) {
          final data = e.response?.data;
          if (data is Map && data['errors'] != null) {
            final errors = data['errors'] as Map;
            final first = errors.entries.first;
            msg = first.value is List
                ? first.value.first.toString()
                : first.value.toString();
          } else if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        } else if (e.message != null) {
          msg = e.message ?? msg;
        }

        if (kDebugMode) {
          debugPrint(
              '[UpdateProfile] DioException: statusCode=${e.response?.statusCode}, msg=$msg');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _isSubmitting = false;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Network error: ${e.toString()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        _isSubmitting = false;
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
      _isSubmitting = false;
    }
  }
}
