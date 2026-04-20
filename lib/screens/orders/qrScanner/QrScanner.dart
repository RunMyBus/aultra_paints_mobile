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

class QrScanner extends StatefulWidget {
  const QrScanner({Key? key}) : super(key: key);

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  int? selected;

  var accesstoken;
  var USER_ID;
  var Company_ID;

  var ewbNumber;

  var argumentData;
  bool allowScanner = true;

  var scannedValue;

  @override
  void initState() {
    fetchLocalStorageDate();
    super.initState();
  }

  fetchLocalStorageDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
  }

  Future sendScannedValue(scannedValue) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;

    // var QRCodeId = scannedValue.split('tx=')[1];
    Map<String, String> requestBody = {"qrCodeUrl": scannedValue};
    final body = json.encode(requestBody);

    var apiUrl = BASE_URL + POST_SCANNED_DATA;

    response = await http.post(Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken
        },
        body: body);
    if (response.statusCode == 200) {
      Navigator.pop(context);
      var apiResp = json.decode(response.body);
      // Navigator.pop(context, true);
      showApiResponsePopup(context, apiResp);
    } else {
      Navigator.pop(context);
      var apiResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, apiResp['message'], false);
      setState(() {
        allowScanner = true;
      });
    }
  }

  onBackPressed() {
    Utils.clearToasts(context);
    // Navigator.pop(context, true);
    Navigator.pushNamed(context, '/dashboardPage', arguments: {});
    // Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  Future<bool> _onPopUpBack() async {
    // onBackPressed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
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
            SingleParamHeader('QR Scanner', '', context, false,
                () => Navigator.pop(context, true)),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        color: greyButtonBgColor,
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width * 0.03,
                            right: MediaQuery.of(context).size.width * 0.03),
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: allowScanner == false
                            ? null
                            : QrCamera(
                                qrCodeCallback: (code) {
                                  HapticFeedback.vibrate();
                                  if (code != null) {
                                    setState(() {
                                      allowScanner = false;
                                    });
                                    sendScannedValue(code);
                                  }
                                },
                              ),
                      )
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: _onPopUpBack,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Container(
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.28,
                  // padding: EdgeInsets.symmetric(
                  //   horizontal: screenWidth * 0.1,
                  //   vertical: screenHeight * 0.01,
                  // ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(getScreenWidth(20)),
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
                      Text(
                        rewardPoints.toString(),
                        style: TextStyle(
                          fontSize: unitHeightValue * 0.1,
                          fontFamily: ffGSemiBold,
                          color: const Color(0xFF3533CD),
                        ),
                      ),
                      Text(
                        "Reward Points",
                        style: TextStyle(
                          fontSize: getScreenWidth(14),
                          color: const Color(0xFF3533CD),
                          fontFamily: ffGSemiBold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Center(
                        child: Text(
                          "With Coupon : $couponCode",
                          style: TextStyle(
                            fontSize: getScreenWidth(16),
                            color: Color(0xFF3533CD),
                            fontFamily: ffGSemiBold,
                          ),
                        ),
                      ),
                      SizedBox(height: getScreenHeight(2)),
                      // Text(
                      //   "Reward Points: ${data['rewardPoints'] ?? 0}",
                      //   style: TextStyle(
                      //     fontSize: getScreenWidth(14),
                      //     color: Colors.white,
                      //     fontFamily: ffGSemiBold,
                      //   ),
                      // ),
                      // SizedBox(height: screenHeight * 0.02),
                      Divider(thickness: 1),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            Navigator.pop(context, true);
                          },
                          child: Text("OK",
                              style: TextStyle(
                                fontSize: getScreenWidth(16),
                                color: Color(0xFF3533CD),
                                fontFamily: ffGSemiBold,
                              )),
                        ),
                      ),
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
