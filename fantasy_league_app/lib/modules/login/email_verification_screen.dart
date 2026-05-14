import 'dart:async';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/utils/dialogs.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final bool redirectToLogin;

  const EmailVerificationScreen(
      {super.key, required this.email, this.redirectToLogin = true});

  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _verificationCodeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  Timer? _verifyTimer;
  Timer? _resendTimer;

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    _verifyTimer?.cancel();
    _resendTimer?.cancel();
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _handleVerifyEmail() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      Dialogs.showDialogWithOneButton(
        context,
        'Error',
        'Please enter the verification code',
        onButtonPress: () => Navigator.pop(context),
      );
      return;
    }

    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => _isVerifying = true);

    try {
      // Cancel any existing timer
      _verifyTimer?.cancel();

      // Add 10s timeout for email verification
      _verifyTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted || !_isVerifying) return;
        setState(() => _isVerifying = false);
        Dialogs.showDialogWithOneButton(
          context,
          'Request Timeout',
          'Email verification took too long. Please try again.',
          onButtonPress: () => Navigator.pop(context),
        );
      });

      await ApiProvider().verifyEmail(
        email: widget.email,
        verificationCode: _verificationCodeController.text.trim(),
      );

      if (mounted) {
        setState(() => _isVerifying = false);

        if (widget.redirectToLogin) {
          Dialogs.showDialogWithOneButton(
            context,
            'Success',
            'Your email has been verified successfully. You can now login.',
            onButtonPress: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, Routes.LOGIN);
            },
          );
        } else {
          // When not redirecting to login, pop directly with result
          // Use Future.microtask to ensure proper async handling
          Future.microtask(() {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      }
    } catch (e) {
      _verifyTimer?.cancel();
      if (mounted) {
        setState(() => _isVerifying = false);

        String errorMessage = 'Email verification failed. Please try again.';
        if (e.toString().contains('Invalid')) {
          errorMessage = 'Invalid verification code.';
        }

        Dialogs.showDialogWithOneButton(
          context,
          'Verification Error',
          errorMessage,
          onButtonPress: () {
            Navigator.pop(context);
          },
        );
      }
    } finally {
      _verifyTimer?.cancel();
    }
  }

  Future<void> _handleResendCode() async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => _isResending = true);

    try {
      // Cancel any existing timer
      _resendTimer?.cancel();

      // Add 10s timeout for resend code request
      _resendTimer = Timer(const Duration(seconds: 10), () {
        if (!mounted || !_isResending) return;
        setState(() => _isResending = false);
        Dialogs.showDialogWithOneButton(
          context,
          'Request Timeout',
          'Resend code request took too long. Please try again.',
          onButtonPress: () => Navigator.pop(context),
        );
      });

      await ApiProvider().resendVerificationEmail(
        email: widget.email,
      );

      if (mounted) {
        setState(() => _isResending = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code resent to ${widget.email}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _resendTimer?.cancel();
      if (mounted) {
        setState(() => _isResending = false);

        Dialogs.showDialogWithOneButton(
          context,
          'Error',
          'Failed to resend verification code. Please try again.',
          onButtonPress: () => Navigator.pop(context),
        );
      }
    } finally {
      _resendTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Email',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isVerifying,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AllCoustomTheme.getThemeData().primaryColor,
                AllCoustomTheme.getThemeData().colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Icon(
                    Icons.mail_outline,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We sent a verification code to',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Verification Code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _verificationCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter verification code from email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isVerifying ? null : _handleVerifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AllCoustomTheme.getThemeData().primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Verify Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          "Didn't receive the code?",
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _isResending ? null : _handleResendCode,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend Code',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
