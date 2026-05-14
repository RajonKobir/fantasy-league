import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/validator/validator.dart';

class LoginView extends StatefulWidget {
  final void Function(String? emailtxt, String? password)? loginCallBack;

  const LoginView({super.key, this.loginCallBack});
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  DateTime date = DateTime.now();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var emailFocusNode = FocusNode();
  var passwordFocusNode = FocusNode();
  var _obscureConfirmText = true;
  final _formKey = GlobalKey<FormState>();

  var emailtxt = '';
  var password = '';

  @override
  void dispose() {
    emailFocusNode.dispose();
    passwordController.dispose();
    emailController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  String? _validateLogin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    if (!Validators().loginValidator(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value!.isEmpty) {
      return 'Password can not be empty';
    } else {
      if (!Validators().passwordValidator(value)) {
        return 'Password length should be greater than 6 chars.';
      } else {
        return null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4, right: 16),
      child: Stack(
        alignment: AlignmentDirectional.bottomCenter,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(bottom: 19),
            child: Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AllCoustomTheme.getThemeData().colorScheme.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  width: 1.0,
                  color: AllCoustomTheme.getTextThemeColors()
                      .withValues(alpha: 128),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                      color: AllCoustomTheme.getTextThemeColors()
                          .withValues(alpha: 128),
                      offset: const Offset(0, 1),
                      blurRadius: 3.0),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: TextFormField(
                          controller: emailController,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: ConstanceData.SIZE_TITLE16,
                            color:
                                AllCoustomTheme.getBlackAndWhiteThemeColors(),
                          ),
                          autofocus: false,
                          focusNode: emailFocusNode,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                              labelText: 'Email',
                              icon: Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: Icon(Icons.person),
                              )),
                          onEditingComplete: () {
                            FocusScope.of(context)
                                .requestFocus(passwordFocusNode);
                          },
                          validator: _validateLogin,
                          onSaved: (value) {
                            emailtxt = value!;
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Container(
                        child: TextFormField(
                          controller: passwordController,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: ConstanceData.SIZE_TITLE16,
                            color:
                                AllCoustomTheme.getBlackAndWhiteThemeColors(),
                          ),
                          autofocus: false,
                          focusNode: passwordFocusNode,
                          keyboardType: TextInputType.text,
                          obscureText: _obscureConfirmText,
                          decoration: InputDecoration(
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                            ),
                            labelText: 'Password',
                            icon: const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Icon(Icons.lock),
                            ),
                            suffixIcon: GestureDetector(
                              dragStartBehavior: DragStartBehavior.down,
                              onTap: () {
                                setState(() {
                                  _obscureConfirmText = !_obscureConfirmText;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Icon(
                                  _obscureConfirmText
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  semanticLabel: _obscureConfirmText
                                      ? 'show password'
                                      : 'hide password',
                                ),
                              ),
                            ),
                          ),
                          onEditingComplete: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            _submit();
                          },
                          validator: _validatePassword,
                          onSaved: (value) {
                            password = value!;
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AllCoustomTheme.getThemeData().primaryColor,
              borderRadius: BorderRadius.circular(50.0),
              boxShadow: <BoxShadow>[
                BoxShadow(
                    color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                        .withValues(alpha: 128),
                    offset: const Offset(0, 1),
                    blurRadius: 5.0),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(50.0),
                onTap: () {
                  _submit();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 10, left: 75, right: 75, bottom: 10),
                  child: Text(
                    'Login',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: AllCoustomTheme.getThemeData().colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    FocusScope.of(context).requestFocus(FocusNode());

    if (_formKey.currentState!.validate() == false) {
      return;
    }
    _formKey.currentState!.save();
    widget.loginCallBack!(emailtxt, password);
  }
}




