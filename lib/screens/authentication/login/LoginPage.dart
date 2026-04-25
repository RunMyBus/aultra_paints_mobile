import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../../../services/error_handling.dart';
import '../../../utility/loader.dart';
import '/utility/check_internet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/config.dart';
import '/utility/Utils.dart';

import '/model/request/LoginRequest.dart';
import 'package:http/http.dart' as http;

import '../../../theme/app_colors.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_card.dart';
import '../../../widgets/primitives/app_button.dart';
import '../../../widgets/primitives/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int? selected = 1;

  final LoginRequest _loginRequest = LoginRequest();

  String stringResponse = '';
  Map mapResponse = {};
  late var names = [];
  late var totalList = [];
  late var searchData = [];
  String? selectedRole;
  String? selectedRoleValue;
  FocusNode inputNode = FocusNode();

  @override
  void initState() {
    handleLocalStorage();
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      openKeyboard();
    });
  }

  @override
  void dispose() {
    inputNode.dispose();
    super.dispose();
  }

  void openKeyboard() {
    FocusScope.of(context).requestFocus(inputNode);
  }

  handleLocalStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('counter', 10);
  }

  onBackPressed() {
    Navigator.pop(context, true);
  }

  Future<void> checkUserLogin(
      String tempFirstValue, String tempSecondValue) async {
    try {
      bool isConnected = await CheckInternet.isInternet();
      if (!isConnected) {
        _showSnackBar(
          "No internet connection. Please try again.",
          context,
          false,
        );
        return;
      }

      Loader.showLoader(context);

      final apiURL = '$BASE_URL$POST_SEND_LOGIN_OTP';
      Map<String, String> requestBody = {"mobile": tempFirstValue};
      final body = json.encode(requestBody);

      final response = await http.post(
        Uri.parse(apiURL),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      final apiResp = json.decode(response.body);

      if (response.statusCode == 200) {
        Loader.hideLoader(context);
        onLogin(tempFirstValue);
      } else {
        Loader.hideLoader(context);
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
      Loader.hideLoader(context);
      error_handling.errorValidation(context, '', e.toString(), false);
    }
  }

  onLogin(tempFirstValue) async {
    FocusScope.of(context).unfocus();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('USER_MOBILE_NUMBER', tempFirstValue);

    Navigator.pushNamed(context, '/otpPage', arguments: {});
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> _onWillPop() async {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
    return false;
  }

  void _handleSendOtp() {
    Utils.clearToasts(context);
    final tempFirstValue = _loginRequest.phoneNumber.trim();
    final tempSecondValue = _loginRequest.password.trim();
    if (tempFirstValue == '') {
      _showSnackBar("Please enter Mobile Number", context, false);
    } else {
      checkUserLogin(tempFirstValue, tempSecondValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 44),

                  // Gradient brand tile
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: AppGradients.signatureCompact,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3F10278C),
                            blurRadius: 22,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Center(
                    child: Text(
                      'Aultra Paints',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Center(
                    child: Text(
                      'Experience colour like never before',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
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
                          Text(
                            'Sign in',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "We'll send an OTP to your phone",
                            style:
                                Theme.of(context).textTheme.bodySmall!.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Mobile number field
                          AppTextField(
                            label: 'Mobile number',
                            hint: '9xxxxxxxxx',
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            prefix: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '+91',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            onChanged: (value) {
                              _loginRequest.phoneNumber = value.trim();
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          AppButton.filled(
                            label: 'Send OTP',
                            onPressed: _handleSendOtp,
                            fullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/signupPage'),
                      child: const Text('New here? Create an account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
