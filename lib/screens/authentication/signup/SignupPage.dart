import 'dart:convert';

import 'package:aultra_paints_mobile/utility/FooterButton.dart';
import 'package:aultra_paints_mobile/utility/size_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/config.dart';
import '../../../utility/SingleParamHeader.dart';
import '../../../utility/Utils.dart';
import '/utility/Colors.dart';
import '/utility/Fonts.dart';

import 'package:http/http.dart' as http;

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int? selected = 1;

  late var names = [];
  late var totalList = [];
  late var searchData = [];

  Map mapResponse = {};

  bool passwordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;
  FocusNode inputNode = FocusNode();

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
            ? Duration(milliseconds: 800)
            : Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  postRegisterDetails() async {
    Utils.returnScreenLoader(context);
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
    // print('register statusCode====>${response.statusCode}');
    mapResponse = json.decode(response.body);
    // print('register resp====>${mapResponse}');
    if (response.statusCode == 200) {
      Navigator.pop(context);
      _showSnackBar(mapResponse['message'], context, true, false);
      Navigator.pop(context, true);
    } else {
      _showSnackBar(mapResponse['message'], context, false, false);
      Navigator.pop(context);
    }
  }

  validateFeilds() {
    Utils.clearToasts(context);
    final nameRegex = RegExp(r"^[a-zA-Z\s]{3,}$");
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    final passwordRegex = RegExp(
        r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>])[A-Za-z0-9!@#$%^&*(),.?":{}|<>]{8,}$');
    final phoneNumberRegax = RegExp(r'^[0-9]{10}$');

    if (_userName.text.isEmpty || !nameRegex.hasMatch(_userName.text)) {
      _showSnackBar('Enter a valid name (only letters, min 3 characters)',
          context, false, true);
    }
    // else if (_userEmail.text.isEmpty ||
    //     !emailRegex.hasMatch(_userEmail.text)) {
    //   _showSnackBar('Enter a valid email', context, false, true);
    // }
    else if (_userMobileNumber.text.isEmpty ||
        !phoneNumberRegax.hasMatch(_userMobileNumber.text)) {
      _showSnackBar('Enter a valid Mobile Number', context, false, true);
    }
    //  else if (_userNewPassword.text.isEmpty) {
    //   _showSnackBar('Enter a valid new password', context, false, true);
    // } else if (_userConfirmPassword.text.isEmpty) {
    //   _showSnackBar('Enter a valid confirm password', context, false, true);
    // }
    // else if (_userNewPassword.text.isEmpty ||
    //     !passwordRegex.hasMatch(_userNewPassword.text)) {
    //   _showSnackBar('Enter a valid new password', context, false, true);
    // } else if (_userConfirmPassword.text.isEmpty ||
    //     !passwordRegex.hasMatch(_userConfirmPassword.text)) {
    //   _showSnackBar('Enter a valid confirm password', context, false, true);
    // }
    // else if (_userNewPassword.text != _userConfirmPassword.text) {
    //   _showSnackBar('Passwords are not matching', context, false, true);
    // }
    else {
      postRegisterDetails();
    }
  }

  onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          // backgroundColor: whiteBgColor,
          body: Container(
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
        child: Column(
          children: [
            SingleParamHeader(
              'User\nRegistration',
              '',
              context,
              false,
              () => Navigator.pop(context, true),
            ),
            Expanded(
              child: Container(
                height: screenHeight * 0.9,
                // thumbVisibility: true,
                // thickness: screenWidth * 0.01,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    // height: screenHeight * 0.9,
                    margin: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.01,
                        vertical: screenHeight * 0.01),
                    child: Column(
                      children: [
                        returnFormFeilds(),
                        // FooterButton(
                        //   "Register",
                        //   'fullWidth',
                        //   context,
                        //   () => validateFeilds(),
                        // )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    }
    if (value != _userConfirmPassword.text) {
      return 'Passwords do not match';
    }
    return null;
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

  Widget returnFormFeilds() {
    // final _formKey = GlobalKey<FormState>();
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight,
      child: SafeArea(
          child: Stack(children: [
          Form(
            // key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
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
                                height: screenHeight * 0.15,
                                child: Image.asset('assets/images/app_file_icon.png')),
                            SizedBox(
                                height: screenHeight * 0.14,
                                child: Image.asset('assets/images/app_name.png')),
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
                        height: screenHeight * 0.06,
                        child: TextFormField(
                          // keyboardType: TextInputType.number,
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          autofocus: false,
                          keyboardType: TextInputType.text,
                          controller: _userName,
                          style: TextStyle(
                            fontSize: unitHeightValue * 0.02,
                            color: Colors.white,
                            fontFamily: ffGMedium,
                          ),
                          decoration: InputDecoration(
                            // labelText: '',
                            labelStyle: TextStyle(
                              fontFamily: ffGMedium,
                              fontSize: unitHeightValue * 0.02,
                              color: textInputPlaceholderColor,
                            ),
                            hintText: 'Enter Name', // Placeholder text
                            hintStyle: TextStyle(
                              fontSize: unitHeightValue * 0.02,
                              color: textInputPlaceholderColor.withOpacity(0.7),
                              fontFamily: ffGMedium,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto, // Default behavior
                            prefixIcon: Icon(
                              Icons.assignment_ind_sharp,
                              color: Color(0xFF7A0180),
                              size: unitHeightValue * 0.03,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.02,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), // Optional border
                              borderSide: BorderSide.none,
                            ),
                            filled: true, // Optional for a filled background
                            fillColor: Colors.grey.withOpacity(0.1), // Optional background color
                          ),
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
                        height: screenHeight * 0.06,
                        child: TextFormField(
                          // keyboardType: TextInputType.number,
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          autofocus: false,
                          keyboardType: TextInputType.phone,
                          controller: _userMobileNumber,
                          style: TextStyle(
                            fontSize: unitHeightValue * 0.02,
                            color: Colors.white,
                            fontFamily: ffGMedium,
                          ),
                          decoration: InputDecoration(
                            // labelText: '',
                            labelStyle: TextStyle(
                              fontFamily: ffGMedium,
                              fontSize: unitHeightValue * 0.02,
                              color: textInputPlaceholderColor,
                            ),
                            hintText: 'Enter Number', // Placeholder text
                            hintStyle: TextStyle(
                              fontSize: unitHeightValue * 0.02,
                              color: textInputPlaceholderColor.withOpacity(0.7),
                              fontFamily: ffGMedium,
                            ),
                            floatingLabelBehavior: FloatingLabelBehavior.auto, // Default behavior
                            prefixIcon: Icon(
                              Icons.phone_android_rounded,
                              color: Color(0xFF7A0180),
                              size: unitHeightValue * 0.03,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.02,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10), // Optional border
                              borderSide: BorderSide.none,
                            ),
                            filled: true, // Optional for a filled background
                            fillColor: Colors.grey.withOpacity(0.1), // Optional background color
                          ),
                          // onChanged: (value) {
                          //   setState(() {
                          //     if (_userMobileNumber.text != value) {
                          //       final cursorPosition = _userMobileNumber.selection;
                          //       _userMobileNumber.text = value;
                          //       _userMobileNumber.selection = cursorPosition;
                          //     }
                          //   });
                          // },
                          onChanged: (value) {
                            setState(() {
                              _userMobileNumber.text = value;
                              _userMobileNumber.selection = TextSelection.collapsed(offset: value.length);
                            });
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          validateFeilds();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.1,
                            vertical: screenHeight * 0.01,
                          ),
                          child: Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20)),
                              side: BorderSide(width: 1, color: appThemeColor),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
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
                              alignment: Alignment.center,
                              height: screenHeight * 0.06,
                              child: Text(
                                "Register",
                                style: TextStyle(
                                    fontSize: unitHeightValue * 0.02,
                                    color: Colors.white, fontWeight: FontWeight.w300
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]
                  )
                ),
                //user name
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text("Name", style: TextStyle(
                //       color: const Color(0xFF7A0180),
                //       fontSize: unitHeightValue * 0.02,
                //       fontWeight: FontWeight.bold,
                //     )),
                //     Container(
                //       margin: EdgeInsets.only(top: getScreenHeight(5)),
                //       padding:
                //           EdgeInsets.symmetric(vertical: getScreenHeight(10)),
                //       decoration: BoxDecoration(
                //         color: textinputBgColor,
                //         borderRadius: BorderRadius.circular(getScreenWidth(5)),
                //       ),
                //       width: screenWidth * 0.9,
                //       child: TextFormField(
                //         onTapOutside: (event) {
                //           FocusManager.instance.primaryFocus?.unfocus();
                //         },
                //         autofocus: false,
                //         keyboardType: TextInputType.text,
                //         controller: _userName,
                //         style: TextStyle(
                //           fontSize: getScreenWidth(15),
                //           color: Colors.black,
                //           fontFamily: ffGMedium,
                //         ),
                //         decoration: InputDecoration(
                //             hintText: 'Enter Name',
                //             hintStyle: TextStyle(
                //                 fontFamily: ffGMedium,
                //                 fontSize: getScreenWidth(15),
                //                 color: Colors.grey),
                //             contentPadding: EdgeInsets.all(15),
                //             border: InputBorder.none),
                //         onChanged: (value) {
                //           setState(() {
                //             if (_userName.text != value) {
                //               final cursorPosition = _userEmail.selection;
                //               _userName.text = value;
                //               _userName.selection = cursorPosition;
                //             }
                //           });
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // SizedBox(height: getScreenHeight(5)),
                // //mobile number
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Text("Mobile Number", style: TextStyle(
                //       color: const Color(0xFF7A0180),
                //       fontSize: unitHeightValue * 0.02,
                //       fontWeight: FontWeight.bold,
                //     )),
                //     Container(
                //       margin: EdgeInsets.only(top: getScreenHeight(5)),
                //       padding:
                //           EdgeInsets.symmetric(vertical: getScreenHeight(10)),
                //       decoration: BoxDecoration(
                //         color: textinputBgColor,
                //         borderRadius: BorderRadius.circular(getScreenWidth(5)),
                //       ),
                //       width: screenWidth * 0.9,
                //       child: TextFormField(
                //         onTapOutside: (event) {
                //           FocusManager.instance.primaryFocus?.unfocus();
                //         },
                //         autofocus: false,
                //         keyboardType: TextInputType.phone,
                //         controller: _userMobileNumber,
                //         style: TextStyle(
                //           fontSize: getScreenWidth(15),
                //           color: Colors.black,
                //           fontFamily: ffGMedium,
                //         ),
                //         decoration: InputDecoration(
                //             hintText: 'Enter Mobile Number',
                //             hintStyle: TextStyle(
                //                 fontFamily: ffGMedium,
                //                 fontSize: getScreenWidth(15),
                //                 color: Colors.grey),
                //             contentPadding: EdgeInsets.all(15),
                //             border: InputBorder.none),
                //         onChanged: (value) {
                //           setState(() {
                //             if (_userMobileNumber.text != value) {
                //               final cursorPosition = _userMobileNumber.selection;
                //               _userMobileNumber.text = value;
                //               _userMobileNumber.selection = cursorPosition;
                //             }
                //           });
                //         },
                //       ),
                //     ),
                //   ],
                // ),
              ],
            ),
          )
      ])),
    );
  }
}
