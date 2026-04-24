import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/config.dart';
import '../../../utility/Utils.dart';
import '../../../utility/validations.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_card.dart';
import '../../../widgets/primitives/app_button.dart';

import 'package:http/http.dart' as http;

class OtpPage extends StatefulWidget {
  const OtpPage({Key? key}) : super(key: key);

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int? selected = 1;

  late var names = [];
  late var totalList = [];
  late var searchData = [];

  var stringResponse = '';
  Map mapResponse = {};

  var loggedUserName;
  var loggedUserPhoneNumber;
  var loggedUserRole;
  bool isOTPButtonEnabled = true;
  int resendDelay = 90;
  Timer? timer;

  // Initialize FocusNodes and Controllers as class-level variables
  List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  String verificationCode = '';

  @override
  void dispose() {
    // Dispose the controllers and focus nodes when the widget is disposed
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    for (var controller in controllers) {
      controller.dispose();
    }
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    fetchArguments();
    super.initState();
  }

  onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pop(context, true);
  }

  fetchArguments() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    loggedUserPhoneNumber = prefs.getString('USER_MOBILE_NUMBER');
    setState(() {
      loggedUserPhoneNumber;
    });
    startOTPTimer();
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> onVerifyOTP(otpCodes) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    Map map = {"mobile": loggedUserPhoneNumber, "otp": int.parse(otpCodes)};
    var body = json.encode(map);
    response = await http.post(Uri.parse(BASE_URL + POST_VERIFY_LOGIN_OTP),
        headers: {"Content-Type": "application/json"}, body: body);
    stringResponse = response.body;
    mapResponse = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context);
      _showSnackBar(mapResponse['message'], context, true);
      onSuccess(mapResponse);
    } else {
      _showSnackBar(mapResponse['message'], context, false);
      Navigator.pop(context);
    }
  }

  onSuccess(userData) async {
    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    var tempToken = "Bearer " + userData['token'];
    await authProvider.setAuthData(
      accessToken: tempToken,
      userId: userData['id'] ?? '',
      userFullName: userData['fullName'] ?? '',
      userMobileNumber: userData['mobile'] ?? '',
      userAccountType: userData['accountType'] ?? '',
      userEmail: userData['email'] ?? '',
      userParentDealerCode: userData['parentDealerCode'] ?? '',
      userParentDealerMobile: userData['parentDealerMobile'] ?? '',
      userParentDealerName: userData['parentDealerName'] ?? '',
    );

    // Initialize cart with user ID
    await cartProvider.setUserId(userData['id']);

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/dashboardPage',
      (route) => false,
    );
  }

  // Add this method to clear the fields when OTP is resent
  void clearOTPFields() {
    for (var controller in controllers) {
      controller.clear();
    }
    setState(() {
      verificationCode = '';
    });
  }

  void startOTPTimer() {
    setState(() {
      isOTPButtonEnabled = false;
      resendDelay = 90;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendDelay == 0) {
        setState(() {
          isOTPButtonEnabled = true;
        });
        timer.cancel();
      } else {
        setState(() {
          resendDelay--;
        });
      }
    });
  }

  resendOTP() async {
    startOTPTimer();
    Utils.returnScreenLoader(context);
    http.Response response;
    Map map = {"mobile": loggedUserPhoneNumber};
    var body = json.encode(map);
    response = await http.post(Uri.parse(BASE_URL + POST_SEND_LOGIN_OTP),
        headers: {"Content-Type": "application/json"}, body: body);
    stringResponse = response.body;
    mapResponse = json.decode(response.body);
    if (response.statusCode == 200) {
      clearOTPFields();
      Navigator.pop(context);
      _showSnackBar(mapResponse['message'], context, true);
    } else {
      _showSnackBar(mapResponse['message'], context, false);
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  void _handleVerify() {
    Utils.clearToasts(context);
    if (verificationCode != null) {
      if (verificationCode.length == 6) {
        if (onlyNumberRegex.hasMatch(verificationCode)) {
          onVerifyOTP(verificationCode);
        } else {
          _showSnackBar("Please enter only numbers", context, false);
        }
      } else {
        _showSnackBar("Please enter 6 digit OTP", context, false);
      }
    } else {
      _showSnackBar("Please enter OTP", context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter OTP',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Sent to +91 ${loggedUserPhoneNumber ?? ''}',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  emphasis: AppCardEmphasis.form,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      // 6-cell OTP row — focus-shift logic preserved exactly
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 44,
                            child: TextField(
                              controller: controllers[index],
                              focusNode: focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              onTapOutside: (event) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              style: Theme.of(context).textTheme.titleMedium,
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.surfaceContainerHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppColors.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  if (index < focusNodes.length - 1) {
                                    FocusScope.of(context)
                                        .requestFocus(focusNodes[index + 1]);
                                  } else {
                                    FocusScope.of(context).unfocus();
                                  }
                                } else if (index > 0) {
                                  FocusScope.of(context)
                                      .requestFocus(focusNodes[index - 1]);
                                }
                                setState(() {
                                  verificationCode = controllers
                                      .map((c) => c.text)
                                      .join('');
                                });
                              },
                              onSubmitted: (value) {
                                if (index == focusNodes.length - 1) {
                                  FocusScope.of(context).unfocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton.filled(
                        label: 'Verify OTP',
                        onPressed: _handleVerify,
                        fullWidth: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: isOTPButtonEnabled
                      ? AppButton.text(
                          label: 'Resend OTP',
                          onPressed: () {
                            Utils.clearToasts(context);
                            resendOTP();
                          },
                        )
                      : Text(
                          'Resend in ${resendDelay}s',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: AppColors.onSurfaceVariant),
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
