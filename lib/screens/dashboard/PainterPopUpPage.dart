import 'dart:convert';

import 'package:aultra_paints_mobile/utility/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/config.dart';
import '../../../services/error_handling.dart';
import '../../../utility/SingleParamHeader.dart';
import '/utility/Colors.dart';
import '/utility/Fonts.dart';
import '/utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:http/http.dart' as http;

class PainterPopUpPage extends StatefulWidget {
  const PainterPopUpPage({Key? key}) : super(key: key);

  @override
  State<PainterPopUpPage> createState() => _PainterPopUpPageState();
}

class _PainterPopUpPageState extends State<PainterPopUpPage> {
  int? selected;

  var accesstoken;
  var USER_ID;
  var Company_ID;

  var ewbNumber;

  var argumentData;
  bool allowScanner = true;

  var scannedValue;

  var userParentDealerName;
  var userParentDealerMobile;
  var USER_MOBILE_NUMBER;

  // Controller for the input fields
  TextEditingController dealerCodeController = TextEditingController();
  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

  bool isOtpVisible = false;
  bool isLoading = false;

  List<dynamic> dealerList = [];
  Map<String, dynamic>? selectedDealer;
  bool isOtpSent = false;

  @override
  void initState() {
    fetchLocalStorageDate();
    super.initState();
  }

  fetchLocalStorageDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER');
    userParentDealerName = prefs.getString('userParentDealerName');
  }

  Future<void> searchDealer(String query) async {
    // Utils.clearToasts(context);
    // Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_DEALERS;
    if (query.isEmpty) {
      selectedDealer = null;
      return;
    }

    response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": accesstoken
      },
      body: json.encode({'searchQuery': query}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      // Navigator.pop(context);
      setState(() {
        dealerList = responseData['data'];
      });
      // setState(() => isLoading = false);
      // return true;
    } else {
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }

    // if (response.statusCode == 200) {
    //   setState(() {
    //     dealerList = json.decode(response.body)['data'];
    //   });
    // }
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future fetchOtp(String dealerCode) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_PARENT_DEALER_CODE_DETAILS;
    var tempBody = json.encode({'dealerCode': dealerCode.trim()});
    response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": accesstoken
      },
      body: tempBody,
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Navigator.pop(context);
      setState(() {
        isOtpVisible = true;
        isOtpSent = true;
        userParentDealerMobile = responseData["data"]['mobile'];
        userParentDealerName = responseData["data"]['name'];
      });
    } else {
      Navigator.pop(context);
      setState(() {
        isOtpVisible = false;
        isOtpSent = false;
      });
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
    }
  }

  Future saveDealerDetails(String dealerCode, String otp) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;
    var tempBody = json.encode({
      'dealerCode': dealerCode,
      'otp': otp,
      'mobile': userParentDealerMobile,
      'painterMobile': USER_MOBILE_NUMBER
    });
    response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": accesstoken
      },
      body: tempBody,
    );
    if (response.statusCode == 200) {
      Navigator.pop(context);
      var tempResp = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('USER_PARENT_DEALER_CODE',
          tempResp['data']?['parentDealerCode'] ?? '');
      // Navigator.pop(context, true);
      Navigator.pushNamed(context, '/dashboardPage');
      _showSnackBar("Details saved successfully.", context, true);
    } else {
      Navigator.pop(context);
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
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
        child: Column(
          children: [
            SingleParamHeader('Enter\nPartner Details', '', context, true,
                () => Navigator.pop(context, true)),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: getScreenWidth(20)),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dealer Code",
                        style: TextStyle(
                            color: const Color(0xFF7A0180),
                            fontSize: getScreenWidth(16),
                            fontWeight: FontWeight.bold),
                      ),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     color: white,
                      //     borderRadius: BorderRadius.circular(20),
                      //     gradient: const LinearGradient(
                      //       begin: Alignment.centerLeft,
                      //       end: Alignment.centerRight,
                      //       colors: [
                      //         Color(0xFF000000),
                      //         Color(0xFF3533CD),
                      //       ],
                      //     ),
                      //   ),
                      //   child: SizedBox(
                      //     height: screenHeight * 0.06,
                      //     child: TextField(
                      //       // keyboardType: TextInputType.number,
                      //       controller: dealerCodeController,
                      //       keyboardType: TextInputType.text,
                      //       onTapOutside: (event) {
                      //         FocusManager.instance.primaryFocus?.unfocus();
                      //       },
                      //       style: TextStyle(
                      //         fontSize: getScreenWidth(18),
                      //         color: Colors.white,
                      //         fontFamily: ffGMedium,
                      //       ),
                      //       decoration: InputDecoration(
                      //         // labelText: '',
                      //         labelStyle: TextStyle(
                      //           fontFamily: ffGMedium,
                      //           fontSize: getScreenWidth(18),
                      //           color: textInputPlaceholderColor,
                      //         ),
                      //         hintText: 'Enter Dealer Code', // Placeholder text
                      //         hintStyle: TextStyle(
                      //           fontSize: getScreenWidth(14),
                      //           color:
                      //               textInputPlaceholderColor.withOpacity(0.7),
                      //           fontFamily: ffGMedium,
                      //         ),
                      //         floatingLabelBehavior: FloatingLabelBehavior
                      //             .auto, // Default behavior
                      //         contentPadding: EdgeInsets.symmetric(
                      //           horizontal: screenWidth * 0.1,
                      //           // vertical: screenHeight * 0.02,
                      //         ),
                      //         border: OutlineInputBorder(
                      //           borderRadius: BorderRadius.circular(
                      //               10), // Optional border
                      //           borderSide: BorderSide.none,
                      //         ),
                      //         filled: true, // Optional for a filled background
                      //         fillColor: Colors.grey.withOpacity(
                      //             0.1), // Optional background color
                      //       ),
                      //       // onChanged: (value) {
                      //       //   _loginRequest.phoneNumber = value.trim();
                      //       // },
                      //     ),
                      //   ),
                      // ),
                      Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.isEmpty) {
                            setState(() {
                              selectedDealer = null;
                            });
                            return const Iterable<Map<String, dynamic>>.empty();
                          }
                          await searchDealer(textEditingValue.text);
                          return dealerList.cast<Map<String, dynamic>>();
                        },
                        displayStringForOption: (Map<String, dynamic> option) =>
                        option['name'],
                        onSelected: (Map<String, dynamic> selection) {
                          setState(() {
                            selectedDealer = selection;
                          });
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(20),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: screenHeight *
                                      0.3, // Limits max height but allows auto expansion
                                ),
                                child: Container(
                                  width: screenWidth * 0.7,
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
                                  child: ListView.builder(
                                    shrinkWrap: true, // Auto height adjustment
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final option = options.elementAt(index);
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              screenWidth * 0.2),
                                        ),
                                        margin: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.001),
                                        child: ListTile(
                                          title: Text(
                                            '${option['name']} - ${option['mobile']}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          onTap: () {
                                            onSelected(option);
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder: (context, textEditingController,
                            focusNode, onFieldSubmitted) {
                          return Container(
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
                            child: SizedBox(
                              height: screenHeight * 0.06,
                              child: TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                enabled: !isOtpSent,
                                style: TextStyle(
                                  fontSize: unitHeightValue * 0.02,
                                  color: Colors.white,
                                  fontFamily: ffGMedium,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter Dealer Name & Mobile',
                                  hintStyle: TextStyle(
                                    fontSize: unitHeightValue * 0.02,
                                    color:
                                    textInputPlaceholderColor.withOpacity(0.7),
                                    fontFamily: ffGMedium,
                                  ),
                                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.1),
                                  suffixIcon: const Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      !isOtpVisible
                          ? SizedBox.shrink()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(height: getScreenHeight(20)),
                                Row(children: [
                                  Text(
                                    "Dealer OTP",
                                    style: TextStyle(
                                        color: const Color(0xFF7A0180),
                                        fontSize: getScreenWidth(16),
                                        fontWeight: FontWeight.bold),
                                  ),
                                ]),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(6, (index) {
                                    return Container(
                                      width: getScreenWidth(40),
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
                                      child: TextField(
                                        controller: otpControllers[index],
                                        maxLength: 1,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: getScreenWidth(
                                              getTabletCheck() ? 12 : 18),
                                          color: Colors.white,
                                          fontFamily: ffGMedium,
                                        ),
                                        decoration: InputDecoration(
                                          fillColor: Colors
                                              .transparent, // Let the Container's background show
                                          counterText:
                                              "", // Hide the counter text (default "0/1")
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                20), // Optional border
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                        ),
                                        onChanged: (value) {
                                          if (value.isNotEmpty && index < 5) {
                                            FocusScope.of(context).nextFocus();
                                          } else if (value.isEmpty &&
                                              index > 0) {
                                            FocusScope.of(context)
                                                .previousFocus();
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                                SizedBox(height: getScreenHeight(10)),
                                Text(
                                    'The 6-digit OTP was sent to the ${userParentDealerName}. OTP expiry time is 10 minutes.',
                                    style: TextStyle(
                                        color: const Color(0xFF7A0180),
                                        fontSize: getScreenWidth(
                                            getTabletCheck() ? 12 : 15))),
                                StreamBuilder<int>(
                                  stream: Stream.periodic(Duration(seconds: 1),
                                      (i) => 600 - i - 1).take(600),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final remainingSeconds = snapshot.data!;
                                      final minutes = remainingSeconds ~/ 60;
                                      final seconds = remainingSeconds % 60;
                                      return Text(
                                        'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                            color: const Color(0xFF7A0180),
                                            fontSize: getScreenWidth(
                                                getTabletCheck() ? 12 : 15),
                                            fontWeight: FontWeight.bold),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                      SizedBox(height: getScreenHeight(20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isOtpVisible)
                            TextButton(
                              onPressed: () async {
                                fetchOtp(selectedDealer?['dealerCode'].trim());
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.01,
                                ),
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
                                  "Get OTP",
                                  style: TextStyle(
                                      fontSize: unitHeightValue * 0.02,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300),
                                ),
                              ),
                            ),
                          if (isOtpVisible)
                            TextButton(
                              onPressed: () async {
                                String otp =
                                    otpControllers.map((e) => e.text).join();
                                if (otp.length == 6) {
                                  saveDealerDetails(
                                      selectedDealer?['dealerCode'].trim(), otp);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Please enter a valid 6-digit OTP.")),
                                  );
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.1,
                                  vertical: screenHeight * 0.01,
                                ),
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
                                  "OK",
                                  style: TextStyle(
                                      fontSize: unitHeightValue * 0.02,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300),
                                ),
                              ),
                              //   child: Text("OK",
                              //       style: TextStyle(
                              //           fontSize: unitHeightValue * 0.02,
                              //           fontWeight: FontWeight.w500,
                              //         color: const Color(0xFF7A0180),)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  void showApiResponsePopup(
      BuildContext context, Map<String, dynamic> response) {
    final message = response["message"] ?? "No message";
    final data = response["data"] ?? {};
    var couponCode = data["couponCode"] ?? '';
    var rewardPoints = data["rewardPoints"] ?? '';
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: _onWillPop,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Container(
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.25,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.1,
                    vertical: screenHeight * 0.01,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFFFF7AD),
                        Color(0xFFFFA9F9),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          rewardPoints.toString(),
                          style: TextStyle(
                            fontSize: unitHeightValue * 0.1,
                            fontFamily: ffGSemiBold,
                            color: const Color(0xFF3533CD),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Center(
                        child: Text(
                          "With Coupon : $couponCode",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF3533CD),
                            fontFamily: ffGSemiBold,
                          ),
                        ),
                      ),
                      // SizedBox(height: 2),
                      // Text("Reward Points: ${data['rewardPoints'] ?? 0}", style: TextStyle(fontSize: 14, color: Colors.white, fontFamily: ffGSemiBold,),),
                      // SizedBox(height: screenHeight * 0.02),
                      // Align(
                      //   alignment: Alignment.center,
                      //   child: TextButton(
                      //     onPressed: () {
                      //       Navigator.pop(context, true);
                      //       Navigator.pop(context, true);
                      //     },
                      //     child: const Text(
                      //         "OK",
                      //         style: TextStyle(
                      //           fontSize: 14,
                      //           color: Color(0xFF3533CD),
                      //           fontFamily: ffGSemiBold,
                      //         )
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
