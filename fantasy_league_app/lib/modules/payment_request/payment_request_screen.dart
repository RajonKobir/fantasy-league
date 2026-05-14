import 'dart:async';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';

class PaymentRequestScreen extends StatefulWidget {
  const PaymentRequestScreen({super.key});

  @override
  _PaymentRequestScreenState createState() => _PaymentRequestScreenState();
}

class _PaymentRequestScreenState extends State<PaymentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String? paymentMethod;
  final toController = TextEditingController();
  final fromController = TextEditingController();
  final trxController = TextEditingController();
  final amountController = TextEditingController();
  bool isLoading = false;
  String? error;
  late Future<List<Map<String, dynamic>>> _paymentMethodsFuture;

  /// Helper method to load payment methods with timeout protection
  Future<List<Map<String, dynamic>>> _loadPaymentMethodsWithTimeout() {
    return ApiProvider()
        .getPaymentMethods()
        .timeout(const Duration(seconds: 12), onTimeout: () {
      debugPrint(
          '[PaymentRequest] Payment methods load timed out after 12 seconds');
      throw TimeoutException(
          'Loading payment methods took too long. Please try again.');
    });
  }

  @override
  void initState() {
    super.initState();
    _paymentMethodsFuture = _loadPaymentMethodsWithTimeout();
    globals.themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    toController.dispose();
    fromController.dispose();
    trxController.dispose();
    amountController.dispose();
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (paymentMethod == null) {
      setState(() {
        error = 'Please select a payment method';
      });
      return;
    }
    setState(() {
      isLoading = true;
      error = null;
    });

    Timer? submitTimer;
    try {
      // Add a 12s timeout for the submission spinner
      submitTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        if (isLoading) {
          setState(() {
            isLoading = false;
            error = 'Request timed out. Please try again.';
          });
        }
      });

      final amt = double.parse(amountController.text.trim());
      final resp = await ApiProvider().submitPaymentRequest(
        paymentMethod: paymentMethod!,
        toNumber: toController.text.trim(),
        fromNumber: fromController.text.trim(),
        amount: amt,
        transactionNumber: trxController.text.trim(),
      );
      if (resp != null && resp['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment request submitted')));

        // Fetch updated wallet balance and broadcast to drawer
        try {
          final wallet = await ApiProvider().getWallet();
          final cached =
              await MySharedPreferences().getCacheJson('user_summary');
          if (cached != null) {
            final summary = {
              'profile': cached['profile'] ?? {},
              'wallet': wallet,
              'fetched_at': DateTime.now().toIso8601String()
            };
            await MySharedPreferences().setCacheJson('user_summary', summary);
            UserSummaryNotifier.update(summary);
          }
        } catch (_) {
          // Ignore wallet fetch errors
        }

        Navigator.pop(context);
      } else {
        setState(() {
          error = resp?['message'] ?? 'Submission failed';
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      try {
        submitTimer?.cancel();
      } catch (_) {}
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globals.themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Payment Request',
              style: TextStyle(
                color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
              ),
            ),
            backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close,
                  color: AllCoustomTheme.getReBlackAndWhiteThemeColors()),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ModalProgressHUD(
            inAsyncCall: isLoading,
            color: Colors.transparent,
            progressIndicator: const CircularProgressIndicator(),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    // Payment Methods Dropdown with FutureBuilder
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _paymentMethodsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                                labelText: 'Payment Method'),
                            items: const [],
                            onChanged: null,
                          );
                        }

                        if (snapshot.hasError) {
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              errorText: 'Failed to load payment methods',
                            ),
                            items: const [],
                            onChanged: null,
                          );
                        }

                        final paymentMethods = snapshot.data ?? [];
                        if (paymentMethods.isEmpty) {
                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Payment Method',
                              errorText: 'No payment methods available',
                            ),
                            items: const [],
                            onChanged: null,
                          );
                        }

                        // Set default payment method if not set
                        if (paymentMethod == null &&
                            paymentMethods.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setState(() {
                              paymentMethod =
                                  paymentMethods[0]['code'] as String?;
                            });
                          });
                        }

                        return DropdownButtonFormField<String>(
                          initialValue: paymentMethod,
                          decoration: const InputDecoration(
                              labelText: 'Payment Method'),
                          items: paymentMethods
                              .map((method) => DropdownMenuItem(
                                    value: method['code'] as String,
                                    child: Text(method['name'] as String),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => paymentMethod = v),
                          validator: (value) => value == null
                              ? 'Please select a payment method'
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: toController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'To Number (service number)'),
                      validator: (v) => (v == null || v.trim().length < 8)
                          ? 'Enter valid number'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: fromController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'From Number (your number)'),
                      validator: (v) => (v == null || v.trim().length < 8)
                          ? 'Enter valid number'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter amount';
                        final n = double.tryParse(v.trim());
                        if (n == null) return 'Enter number';
                        if (n < 100) return 'Minimum amount is 100';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: trxController,
                      decoration: const InputDecoration(
                          labelText: 'Transaction Number / TrxID'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter transaction id'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    ElevatedButton(
                        onPressed: _submit, child: const Text('Submit Request'))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
