import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../../../services/error_handling.dart';
import '../../../utility/loader.dart';
import '/utility/check_internet.dart';
import '/utility/size_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/config.dart';
import '/utility/Colors.dart';
import '/utility/Fonts.dart';
import '/utility/Utils.dart';

import '/model/request/LoginRequest.dart';
import 'package:http/http.dart' as http;

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
    // print('userdata====>${userData}');
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
                    children: [
                      Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Stack(
                                children: [
                                  SizedBox(
                                    width: screenWidth,
                                    child: Row(children: [
                                      InkWell(
                                        onTap: () => Navigator.pushNamed(
                                            context, '/launchPage'),
                                        child: Container(
                                          margin: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: screenHeight * 0.02,
                                          ),
                                          child: Icon(
                                            Icons
                                                .keyboard_double_arrow_left_sharp,
                                            color: Color(0xFF7A0180),
                                            size: screenWidth * 0.08,
                                          ),
                                        ),
                                      ),
                                    ]),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: screenHeight * 0.66,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: screenWidth * 0.5,
                                      // width: getScreenWidth(300),
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
                                        vertical: screenHeight * 0.01,
                                      ),
                                      decoration: BoxDecoration(
                                        color: white,
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFF000000),
                                            Color(0xFF3533CD),
                                          ],
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: screenHeight * 0.06,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          // keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                                10),
                                          ],
                                          onTapOutside: (event) {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                          },
                                          style: TextStyle(
                                            fontSize: getScreenWidth(18),
                                            color: Colors.white,
                                            fontFamily: ffGMedium,
                                          ),
                                          decoration: InputDecoration(
                                            // labelText: '',
                                            labelStyle: TextStyle(
                                              fontFamily: ffGMedium,
                                              fontSize: getScreenWidth(18),
                                              color: textInputPlaceholderColor,
                                            ),
                                            hintText:
                                                'Mobile Number', // Placeholder text
                                            hintStyle: TextStyle(
                                              fontSize: unitHeightValue * 0.02,
                                              color: textInputPlaceholderColor
                                                  .withOpacity(0.7),
                                              fontFamily: ffGMedium,
                                            ),
                                            floatingLabelBehavior:
                                                FloatingLabelBehavior
                                                    .auto, // Default behavior
                                            prefixIcon: Icon(
                                              Icons.phone_android_rounded,
                                              color: Color(0xFF7A0180),
                                              size: unitHeightValue * 0.03,
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.1,
                                              // vertical: screenHeight * 0.02,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10), // Optional border
                                              borderSide: BorderSide.none,
                                            ),
                                            filled:
                                                true, // Optional for a filled background
                                            fillColor: Colors.grey.withOpacity(
                                                0.1), // Optional background color
                                          ),
                                          onChanged: (value) {
                                            _loginRequest.phoneNumber =
                                                value.trim();
                                          },
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Utils.clearToasts(context);
                                        var tempFirstValue =
                                            _loginRequest.phoneNumber.trim();
                                        var tempSecondValue =
                                            _loginRequest.password.trim();
                                        if (tempFirstValue == '') {
                                          _showSnackBar(
                                              "Please enter Mobile Number",
                                              context,
                                              false);
                                        } else {
                                          checkUserLogin(
                                              tempFirstValue, tempSecondValue);
                                        }
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.1,
                                          vertical: screenHeight * 0.01,
                                        ),
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    getProportionateScreenWidth(
                                                        20))),
                                            side: BorderSide(
                                                width: 1, color: appThemeColor),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              gradient: const LinearGradient(
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
                                              "Generate OTP",
                                              style: TextStyle(
                                                  fontSize:
                                                      unitHeightValue * 0.02,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w300),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                  width: screenWidth,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.1,
                                    vertical: screenHeight * 0.050,
                                  ),
                                  decoration: const BoxDecoration(
                                      border: Border(
                                          top: BorderSide(
                                    color: Colors.white,
                                    width: 1.0,
                                  ))),
                                  child: Column(children: [
                                    Text("DIDN'T HAVE ACCOUNT",
                                        style: TextStyle(
                                          color: QA_Build_Check
                                              ? Color.fromARGB(255, 1, 128, 48)
                                              : Color(0xFF7A0180),
                                          fontSize: unitHeightValue * 0.016,
                                          fontWeight: FontWeight.w400,
                                        )),
                                    const SizedBox(height: 5),
                                    GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                            context, '/signupPage'),
                                        child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Color(0xFF000000),
                                                  Color(0xFF3533CD),
                                                ],
                                              ),
                                            ),
                                            width: screenWidth * 0.4,
                                            height: screenHeight * 0.04,
                                            child: Center(
                                              child: Text(
                                                'SIGN UP NOW',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize:
                                                        unitHeightValue * 0.02,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                            )))
                                  ]))
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ))),
    );
  }
}
