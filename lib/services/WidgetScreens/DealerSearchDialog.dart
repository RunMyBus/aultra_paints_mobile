import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/Colors.dart';
import '../../utility/Fonts.dart';
import '../../utility/Utils.dart';
import '../../utility/size_config.dart';
import '../config.dart';
import '../error_handling.dart';

class DealerSearchDialog extends StatefulWidget {
  final Function(String, String) onDealerSelected;
  final VoidCallback onDealerComplete;

  DealerSearchDialog({
    required this.onDealerSelected,
    required this.onDealerComplete,
  });

  @override
  _DealerSearchDialogState createState() => _DealerSearchDialogState();
}

class _DealerSearchDialogState extends State<DealerSearchDialog> {
  var accesstoken;
  var USER_MOBILE_NUMBER;

  TextEditingController searchController = TextEditingController();
  // TextEditingController otpController = TextEditingController();
  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

  List<dynamic> dealerList = [];
  Map<String, dynamic>? selectedDealer;
  bool isOtpSent = false;
  String? otpReferenceId;
  bool isLoading = false;
  String verifyOtpError = '';

  @override
  void initState() {
    fetchLocalStorageData();
    super.initState();
  }

  fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER');

    // searchDealer('');
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

  Future<void> sendOtp() async {
    if (selectedDealer == null) return;
    setState(() => isLoading = true);
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_PARENT_DEALER_CODE_DETAILS;
    var tempBody =
        json.encode({'dealerCode': selectedDealer?['dealerCode'].trim()});
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
        isOtpSent = true;
        otpReferenceId = responseData['otpRefId'];
      });
    } else {
      Navigator.pop(context);
      setState(() {
        isOtpSent = false;
      });
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
    }
  }

  // Future saveDealerDetails(String dealerCode, String otp) async {
  //   Utils.clearToasts(context);
  //   Utils.returnScreenLoader(context);
  //   http.Response response;
  //   var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;
  //   var tempBody = json.encode({
  //     'dealerCode': dealerCode,
  //     'otp': otp,
  //     'mobile': userParentDealerMobile,
  //     'painterMobile': USER_MOBILE_NUMBER
  //   });
  //   response = await http.post(
  //     Uri.parse(apiUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       "Authorization": accesstoken
  //     },
  //     body: tempBody,
  //   );
  //   if (response.statusCode == 200) {
  //     Navigator.pop(context);
  //     var tempResp = json.decode(response.body);
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('USER_PARENT_DEALER_CODE',
  //         tempResp['data']?['parentDealerCode'] ?? '');
  //     Navigator.pop(context, true);
  //     _showSnackBar("Details saved successfully.", context, true);
  //   } else {
  //     Navigator.pop(context);
  //     final tempResp = json.decode(response.body);
  //     error_handling.errorValidation(
  //         context, response.statusCode, tempResp['message'], false);
  //   }
  // }

  Future<void> verifyOtp(String otp) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;
    var tempBody = json.encode({
      'dealerCode': selectedDealer?['dealerCode'],
      'otp': otp,
      'mobile': selectedDealer?['mobile'],
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
      verifyOtpError = '';
      Navigator.pop(context);
      var tempResp = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('USER_PARENT_DEALER_CODE',
          tempResp['data']?['parentDealerCode'] ?? '');
      await prefs.setString('USER_PARENT_DEALER_NAME',
          tempResp['data']?['parentDealerName'] ?? '');
      Navigator.pop(context, true);
      Navigator.pop(context, selectedDealer);
      widget.onDealerComplete();
      _showSnackBar("Details saved successfully.", context, true);
    } else {
      Navigator.pop(context);
      final tempResp = json.decode(response.body);
      verifyOtpError = tempResp['error'];
      error_handling.errorValidation(
          context, response.statusCode, tempResp['error'], false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "Edit Dealer",
                      style: TextStyle(
                        fontSize: unitHeightValue * 0.025,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7A0180),
                      ),
                    ),
                  ),
                  Divider(thickness: 1),
                  // Label for the field
                  Align(
                    alignment: Alignment
                        .centerLeft, // Explicitly aligns text to the left
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: screenHeight *
                              0.01), // Space between label and field
                      child: Text(
                        "Dealer",
                        style: TextStyle(
                          fontSize: unitHeightValue * 0.02,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7A0180),
                        ),
                      ),
                    ),
                  ),
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
                  selectedDealer != null
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(getScreenWidth(20)),
                            color: const Color(0x33800180),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 20,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.only(top: screenHeight * 0.01),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.02,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      // "Dealer Name: ${selectedDealer!['name']}",
                                      "${selectedDealer!['name']}",
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      "Phone Number: ${selectedDealer!['mobile']}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Address: ${selectedDealer!['address']}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "Dealer Code: ${selectedDealer!['dealerCode']}",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(),
                  selectedDealer != null
                      ? Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.01),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              isOtpSent
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // OTP Title
                                        Text(
                                          "Dealer OTP",
                                          style: TextStyle(
                                            color: const Color(0xFF7A0180),
                                            fontSize: getScreenWidth(16),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        // OTP Input Boxes
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: List.generate(6, (index) {
                                            return Container(
                                              width: getScreenWidth(40),
                                              // height: getScreenHeight(50), // Adjust for better spacing
                                              decoration: BoxDecoration(
                                                color: Colors.white,
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
                                              child: TextField(
                                                controller:
                                                    otpControllers[index],
                                                maxLength: 1,
                                                keyboardType:
                                                    TextInputType.number,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: getScreenWidth(
                                                      getTabletCheck()
                                                          ? 12
                                                          : 18),
                                                  color: Colors.white,
                                                  fontFamily: ffGMedium,
                                                ),
                                                decoration: InputDecoration(
                                                  counterText:
                                                      "", // Hide the character counter
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  filled: true,
                                                  fillColor: Colors
                                                      .transparent, // Transparent to show gradient
                                                ),
                                                onChanged: (value) {
                                                  if (value.isNotEmpty &&
                                                      index < 5) {
                                                    FocusScope.of(context)
                                                        .nextFocus();
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

                                        if (verifyOtpError.isNotEmpty)
                                          Container(
                                            child: Center(
                                              child: Text(
                                                verifyOtpError,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: getScreenWidth(
                                                      getTabletCheck()
                                                          ? 12
                                                          : 15),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        SizedBox(height: getScreenHeight(10)),

                                        // OTP Expiry Message
                                        Text(
                                          'The 6-digit OTP was sent to ${selectedDealer!['name']}. OTP expiry time is 10 minutes.',
                                          style: TextStyle(
                                            color: const Color(0xFF7A0180),
                                            fontSize: getScreenWidth(
                                                getTabletCheck() ? 12 : 15),
                                          ),
                                        ),

                                        SizedBox(height: getScreenHeight(5)),

                                        // Countdown Timer
                                        StreamBuilder<int>(
                                          stream: Stream.periodic(
                                              Duration(seconds: 1),
                                              (i) => 600 - i - 1).take(600),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              final remainingSeconds =
                                                  snapshot.data!;
                                              final minutes =
                                                  remainingSeconds ~/ 60;
                                              final seconds =
                                                  remainingSeconds % 60;
                                              if (remainingSeconds == 0) {
                                                // Clear OTP fields when timer expires
                                                for (var controller
                                                    in otpControllers) {
                                                  controller.clear();
                                                }

                                                // Show resend button
                                                return TextButton(
                                                  onPressed: () {
                                                    sendOtp();
                                                  },
                                                  child: Text(
                                                    'Resend OTP',
                                                    style: TextStyle(
                                                      color: const Color(
                                                          0xFF7A0180),
                                                      fontSize: getScreenWidth(
                                                          getTabletCheck()
                                                              ? 12
                                                              : 15),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                );
                                              }
                                              return Text(
                                                'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF7A0180),
                                                  fontSize: getScreenWidth(
                                                      getTabletCheck()
                                                          ? 12
                                                          : 15),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            }
                                            return SizedBox.shrink();
                                          },
                                        ),
                                        SizedBox(height: getScreenHeight(20)),
                                        Align(
                                          alignment: Alignment.centerRight,
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
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                String otp = otpControllers
                                                    .map((e) => e.text)
                                                    .join();
                                                // verifyOtp
                                                if (otp.length == 6) {
                                                  verifyOtp(otp);
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            "Please enter a valid 6-digit OTP.")),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                              ),
                                              child: Text(
                                                "OK",
                                                style: TextStyle(
                                                    fontSize:
                                                        unitHeightValue * 0.02,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    )
                                  : Align(
                                      alignment: Alignment.centerRight,
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
                                        child: ElevatedButton(
                                          onPressed: sendOtp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                          ),
                                          child: Text(
                                            "Confirm",
                                            style: TextStyle(
                                                fontSize:
                                                    unitHeightValue * 0.02,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ),
                                      ),
                                    )
                            ],
                          ))
                      : Container(),
                ],
              ),
            ),
          )),
    );
  }
}
