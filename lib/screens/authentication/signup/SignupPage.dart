import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../services/config.dart';
import '../../../utility/Utils.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_button.dart';
import '../../../widgets/primitives/app_card.dart';
import '../../../widgets/primitives/app_text_field.dart';

import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Map mapResponse = {};

  late TextEditingController _userName;
  late TextEditingController _userEmail;
  late TextEditingController _userNewPassword;
  late TextEditingController _userConfirmPassword;
  late TextEditingController _userMobileNumber;

  @override
  void initState() {
    super.initState();
    _userName = TextEditingController();
    _userEmail = TextEditingController();
    _userNewPassword = TextEditingController();
    _userConfirmPassword = TextEditingController();
    _userMobileNumber = TextEditingController();
  }

  @override
  void dispose() {
    _userName.dispose();
    _userEmail.dispose();
    _userNewPassword.dispose();
    _userConfirmPassword.dispose();
    _userMobileNumber.dispose();
    super.dispose();
  }

  void _showSnackBar(
      String message, BuildContext context, ColorCheck, screenValidation) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: screenValidation
            ? const Duration(milliseconds: 800)
            : Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> postRegisterDetails() async {
    setState(() => _isLoading = true);
    try {
      http.Response response;
      Map map = {
        "name": _userName.text,
        "email": _userEmail.text,
        "password": _userConfirmPassword.text,
        "mobile": _userMobileNumber.text
      };
      var body = json.encode(map);
      response = await http.post(Uri.parse(BASE_URL + REGISTER_USER),
          headers: {"Content-Type": "application/json"}, body: body);
      mapResponse = json.decode(response.body);
      if (response.statusCode == 200) {
        _showSnackBar(mapResponse['message'], context, true, false);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(mapResponse['message'], context, false, false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void validateFeilds() {
    Utils.clearToasts(context);
    final nameRegex = RegExp(r"^[a-zA-Z\s]{3,}$");
    final phoneNumberRegax = RegExp(r'^[0-9]{10}$');

    if (_userName.text.isEmpty || !nameRegex.hasMatch(_userName.text)) {
      _showSnackBar('Enter a valid name (only letters, min 3 characters)',
          context, false, true);
    } else if (_userMobileNumber.text.isEmpty ||
        !phoneNumberRegax.hasMatch(_userMobileNumber.text)) {
      _showSnackBar('Enter a valid Mobile Number', context, false, true);
    } else {
      postRegisterDetails();
    }
  }

  void onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    }
    if (value != _userNewPassword.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button row — preserves existing back behavior
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.onSurface,
                    onPressed: onBackPressed,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Brand tile
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppGradients.signatureCompact,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                Text(
                  'Create your account',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "We'll verify your details and set you up.",
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Form card
                AppCard(
                  emphasis: AppCardEmphasis.form,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Full name
                        AppTextField(
                          label: 'Full Name',
                          hint: 'Enter Name',
                          controller: _userName,
                          keyboardType: TextInputType.text,
                          prefix: const Icon(Icons.assignment_ind_sharp),
                          onChanged: (value) {
                            setState(() {
                              if (_userName.text != value) {
                                final cursorPosition = _userEmail.selection;
                                _userName.text = value;
                                _userName.selection = cursorPosition;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Mobile number
                        AppTextField(
                          label: 'Mobile Number',
                          hint: 'Enter Number',
                          controller: _userMobileNumber,
                          keyboardType: TextInputType.phone,
                          prefix: const Icon(Icons.phone_android_rounded),
                          onChanged: (value) {
                            setState(() {
                              _userMobileNumber.text = value;
                              _userMobileNumber.selection =
                                  TextSelection.collapsed(
                                      offset: value.length);
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Submit button
                        AppButton.filled(
                          label: 'Create Account',
                          onPressed: validateFeilds,
                          fullWidth: true,
                          loading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Sign-in link
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
