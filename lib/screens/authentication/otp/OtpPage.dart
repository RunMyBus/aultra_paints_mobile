import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/config.dart';
import '../../../utility/SingleParamHeader.dart';
import '../../../utility/Utils.dart';
import '/utility/Colors.dart';
import '/utility/Fonts.dart';
import '../../../utility/validations.dart';
import '../../../utility/size_config.dart';
import '../../../utility/FooterButton.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';

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

  // var verificationCode;

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

  // @override
  // void dispose() {
  //   timer?.cancel();
  //   super.dispose();
  // }

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

  Widget returnOTPfields() {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.only(top: 20),
      width: getScreenWidth(300),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return SizedBox(
            width: getScreenWidth(43),
            child: TextField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              onTapOutside: (event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              style: TextStyle(
                fontSize: getScreenWidth(24),
                fontFamily: ffGSemiBold,
                color: otpTextinputColor,
              ),
              decoration: const InputDecoration(
                fillColor: whiteBgColor,
                counterText: "", // Hide the counter text (default "0/1")
                border: OutlineInputBorder(
                  // borderRadius: BorderRadius.circular(1.0),
                  borderSide: BorderSide(color: otpTextinputBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  // borderRadius: BorderRadius.circular(1.0),
                  borderSide: BorderSide(color: otpTextinputColor),
                ),
                filled: true,
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  if (index < focusNodes.length - 1) {
                    FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                } else if (index > 0) {
                  FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                }
                setState(() {
                  verificationCode =
                      controllers.map((controller) => controller.text).join('');
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
    // print('resend body===>$body');
    response = await http.post(Uri.parse(BASE_URL + POST_SEND_LOGIN_OTP),
        headers: {"Content-Type": "application/json"}, body: body);
    stringResponse = response.body;
    mapResponse = json.decode(response.body);
    if (response.statusCode == 200) {
      // print('otp resp ==== $mapResponse');
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

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return WillPopScope(
        onWillPop: _onWillPop,
        child: SafeArea(
            child: Scaffold(
          resizeToAvoidBottomInset: true,
          key: _scaffoldKey,
          body: Container(
              // Apply the gradient background
              height: screenHeight, // 100% height
              width: screenWidth, // 100% width
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFF7AD),
                    Color(0xFFFFA9F9),
                  ],
                ),
              ),
              child: SafeArea(
                  child: Stack(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: screenWidth,
                              child: Row(children: [
                                InkWell(
                                  onTap: () => Navigator.pop(context, true),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.02,
                                      vertical: screenHeight * 0.02,
                                    ),
                                    child: Icon(
                                      Icons.keyboard_double_arrow_left_sharp,
                                      color: const Color(0xFF7A0180),
                                      size: screenWidth * 0.08,
                                    ),
                                  ),
                                ),
                                Text(
                                  'OTP',
                                  style: TextStyle(
                                      fontSize: unitHeightValue * 0.03,
                                      color: const Color(0xFF7A0180),
                                      fontWeight: FontWeight.bold),
                                )
                              ]),
                            ),
                            Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0,
                                  vertical: screenHeight * 0.04,
                                ),
                                height: screenHeight * 0.88,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.5,
                                        // height: getScreenWidth(40),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                                height: screenHeight * 0.2,
                                                child: Image.asset(
                                                    'assets/images/app_file_icon.png')),
                                            SizedBox(
                                                height: screenHeight * 0.14,
                                                child: Image.asset(
                                                    'assets/images/app_name.png')),
                                          ],
                                        ),
                                      ),
                                      Container(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.1,
                                            vertical: screenHeight * 0,
                                          ),
                                          child: Column(children: [
                                            Row(children: [
                                              Text("Enter OTP",
                                                  style: TextStyle(
                                                    color:
                                                        const Color(0xFF7A0180),
                                                    fontSize:
                                                        unitHeightValue * 0.03,
                                                    fontWeight: FontWeight.bold,
                                                  )),
                                            ]),
                                            Container(
                                              alignment: Alignment.center,
                                              margin: EdgeInsets.symmetric(
                                                horizontal: screenWidth * 0,
                                                vertical: screenHeight * 0.01,
                                              ),
                                              width: screenWidth * 1,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children:
                                                    List.generate(6, (index) {
                                                  return Container(
                                                    width: getScreenWidth(43),
                                                    decoration: BoxDecoration(
                                                      color: white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      gradient:
                                                          const LinearGradient(
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                        colors: [
                                                          Color(0xFF000000),
                                                          Color(0xFF3533CD),
                                                        ],
                                                      ),
                                                    ),
                                                    child: TextField(
                                                      controller:
                                                          controllers[index],
                                                      focusNode:
                                                          focusNodes[index],
                                                      keyboardType:
                                                          TextInputType.number,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLength: 1,
                                                      onTapOutside: (event) {
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                      },
                                                      style: TextStyle(
                                                        fontSize:
                                                            getScreenWidth(24),
                                                        fontFamily: ffGSemiBold,
                                                        color: Colors.white,
                                                      ),
                                                      decoration:
                                                          InputDecoration(
                                                        fillColor: Colors
                                                            .transparent, // Let the Container's background show
                                                        counterText:
                                                            "", // Hide the counter text (default "0/1")
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                  10), // Optional border
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(10),
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                        filled: true,
                                                      ),
                                                      onChanged: (value) {
                                                        if (value.isNotEmpty) {
                                                          if (index <
                                                              focusNodes
                                                                      .length -
                                                                  1) {
                                                            FocusScope.of(
                                                                    context)
                                                                .requestFocus(
                                                                    focusNodes[
                                                                        index +
                                                                            1]);
                                                          } else {
                                                            FocusScope.of(
                                                                    context)
                                                                .unfocus();
                                                          }
                                                        } else if (index > 0) {
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  focusNodes[
                                                                      index -
                                                                          1]);
                                                        }
                                                        setState(() {
                                                          verificationCode =
                                                              controllers
                                                                  .map((controller) =>
                                                                      controller
                                                                          .text)
                                                                  .join('');
                                                        });
                                                      },
                                                      onSubmitted: (value) {
                                                        if (index ==
                                                            focusNodes.length -
                                                                1) {
                                                          FocusScope.of(context)
                                                              .unfocus();
                                                        }
                                                      },
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: !isOTPButtonEnabled
                                                  ? null
                                                  : () {
                                                      Utils.clearToasts(
                                                          context);
                                                      resendOTP();
                                                    },
                                              child: Container(
                                                alignment:
                                                    Alignment.centerRight,
                                                // margin: EdgeInsets.only(right: screenWidth * 0),
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: screenWidth * 0,
                                                  vertical: screenHeight * 0.01,
                                                ),
                                                child: Text(
                                                  isOTPButtonEnabled
                                                      ? 'Resend OTP'
                                                      : 'Resend OTP in $resendDelay s',
                                                  style: TextStyle(
                                                      decorationThickness: 1.5,
                                                      fontSize:
                                                          getScreenHeight(14),
                                                      fontFamily: ffGMedium,
                                                      color: isOTPButtonEnabled
                                                          ? const Color(
                                                              0xFF7A0180)
                                                          : drawerSubListColor),
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                if (verificationCode != null) {
                                                  if (verificationCode.length ==
                                                      6) {
                                                    if (onlyNumberRegex
                                                        .hasMatch(
                                                            verificationCode)) {
                                                      onVerifyOTP(
                                                          verificationCode);
                                                    } else {
                                                      _showSnackBar(
                                                          "Please enter only numbers",
                                                          context,
                                                          false);
                                                    }
                                                  } else {
                                                    _showSnackBar(
                                                        "Please enter 6 digit OTP",
                                                        context,
                                                        false);
                                                  }
                                                } else {
                                                  _showSnackBar(
                                                      "Please enter OTP",
                                                      context,
                                                      false);
                                                }
                                              },
                                              child: Container(
                                                margin: EdgeInsets.symmetric(
                                                  horizontal: screenWidth * 0,
                                                  vertical: screenHeight * 0.03,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  gradient:
                                                      const LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      Color(0xFF000000),
                                                      Color(0xFF3533CD),
                                                    ],
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                height: screenHeight * 0.06,
                                                child: Text(
                                                  "Login",
                                                  style: TextStyle(
                                                      fontSize:
                                                          unitHeightValue *
                                                              0.02,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w300),
                                                ),
                                              ),
                                            ),

                                            // FooterButton('Login', '', context, () => {
                                            //   Utils.clearToasts(context),
                                            //   if (verificationCode != null)
                                            //     {
                                            //       if (verificationCode.length == 6)
                                            //         {
                                            //           if (onlyNumberRegex.hasMatch(verificationCode))
                                            //             {onVerifyOTP(verificationCode)}
                                            //           else
                                            //             {
                                            //               _showSnackBar("Please enter only numbers", context, false)
                                            //             }
                                            //         }
                                            //       else
                                            //         {
                                            //           _showSnackBar("Please enter 6 digit OTP", context, false)
                                            //         }
                                            //     }
                                            //   else
                                            //     {_showSnackBar("Please enter OTP", context, false)}
                                            // }),
                                          ]))
                                    ]))
                          ],
                        ))),
                  ]))),
        )));

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: whiteBgColor,
        body: Column(
          children: [
            SingleParamHeader(
              'OTP',
              '',
              context,
              false,
              () => Navigator.pop(context, true),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 2,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    margin: EdgeInsets.only(top: getScreenHeight(100)),
                    child: Column(
                      children: [
                        returnOTPsetup(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  returnOTPsetup() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Container(
          width: screenWidth * 0.5,
          // height: getScreenWidth(40),
          child: Column(
            children: [
              SizedBox(
                  height: screenHeight * 0.2,
                  child: Image.asset('assets/images/app_file_icon.png')),
              SizedBox(
                  height: screenHeight * 0.14,
                  child: Image.asset('assets/images/app_name.png')),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              left: getScreenWidth(35), right: getScreenWidth(25)),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Enter OTP received on your mobile number. ',
              style: TextStyle(
                fontFamily: ffGRegular,
                color: loginSubHeadingColor,
                fontSize: getScreenWidth(17),
              ),
            ),
          ),
        ),
        returnOTPfields(),
        SizedBox(height: getScreenHeight(10)),
        InkWell(
          onTap: !isOTPButtonEnabled
              ? null
              : () {
                  Utils.clearToasts(context);
                  resendOTP();
                },
          child: Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(right: screenWidth * 0.11),
            child: Text(
              isOTPButtonEnabled
                  ? 'Resend OTP'
                  : 'Resend OTP in $resendDelay s',
              style: TextStyle(
                  decoration: TextDecoration.underline,
                  decorationThickness: 1.5,
                  fontSize: getScreenHeight(14),
                  fontFamily: ffGMedium,
                  color:
                      isOTPButtonEnabled ? appThemeColor : drawerSubListColor),
            ),
          ),
        ),
        FooterButton(
            'Next',
            '',
            context,
            () => {
                  Utils.clearToasts(context),
                  if (verificationCode != null)
                    {
                      if (verificationCode.length == 6)
                        {
                          if (onlyNumberRegex.hasMatch(verificationCode))
                            {onVerifyOTP(verificationCode)}
                          else
                            {
                              _showSnackBar(
                                  "Please enter only numbers", context, false)
                            }
                        }
                      else
                        {
                          _showSnackBar(
                              "Please enter 6 digit OTP", context, false)
                        }
                    }
                  else
                    {_showSnackBar("Please enter OTP", context, false)}
                }),
      ],
    );
  }
}
