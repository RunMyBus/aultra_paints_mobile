import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../services/error_handling.dart';
import '../../utility/loader.dart';
import '../../utility/size_config.dart';
import '/utility/Colors.dart';
import '/utility/Fonts.dart';
import '/utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../services/config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var accesstoken;
  var USER_ID;
  var USER_FULL_NAME;
  var USER_EMAIL;
  var USER_MOBILE_NUMBER;
  var USER_ACCOUNT_TYPE;
  var USER_PARENT_DEALER_CODE;
  var userParentDealerMobile;
  var userParentDealerName;

  String USER_NAME = "";
  String USER_ROLE = "";
  String BACKEND_ROLE = "";

  var _selectedRadioButtonOption = 0;

  String stringResponse = '';

  var noVehiclePlaced = '0';
  var delivered = '0';
  var readyToPickup = '0';
  var inTransit = '0';
  var booked = '0';

  String roleCheck = "BA_LOGIN"; //DEALER_LOGIN,DRIVER_LOGIN, CONSIGNEE_LOGIN,

  String searchValue = '';
  var searchListData = [];

  TextEditingController _searchController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  var loggedUserRole;

  String pendingTitle = "PENDING ASSIGNMENT";
  String pendingSubTitle = "Vehicle, Driver to be assigned";
  String pendingStatus = "PENDING_ASSIGNMENT";

  String pickupTitle = "READY TO PICKUP";
  String pickupSubTitle = "Vehicle assigned, on the way to pickup";
  String pickupStatus = "READY_TO_PICKUP";

  String intransitTitle = "INTRANSIT";
  String intransitSubTitle = "Orders dispatched and on the way to destination";
  String intransitStatus = "INTRANSIT";

  String deliveredTitle = "DELIVERED";
  String deliveredSubTitle = "Orders delivered with ePOD";
  String deliveredStatus = "DELIVERED";

  String bookedTitle = "BOOKED";
  String bookedSubTitle = "Orders created, to be dispatched";
  String bookedStatus = "BOOKED";

  List dashboardArray = [];

  var dashBoardList = [
    // {"title": "PENDING", "description": "Pending Confirmation", "count": "0"},
    // {"title": "CONFIRMED", "description": "Orders Confirmed", "count": "0"},
    // {"title": "INTRANSIT", "description": "Orders Intransit", "count": "0"},
    // {"title": "DELIVERED", "description": "Orders Delivered", "count": "0"},
  ];
  var accountType = '';
  var parentDealerCode = '';

  @override
  void initState() {
    fetchLocalStorageData();
    super.initState();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          searchValue = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Map mapResponse = {};

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));

    // Find the Scaffold in the Widget tree and use it to show a SnackBar!
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    USER_FULL_NAME = prefs.getString('USER_FULL_NAME');
    USER_ID = prefs.getString('USER_ID');
    USER_EMAIL = prefs.getString('USER_EMAIL');
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER');
    USER_ACCOUNT_TYPE = prefs.getString('USER_ACCOUNT_TYPE');
    getDashboardCounts();
  }

  clearStorage() async {
    Utils.clearToasts(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context).pushNamed('/splashPage');
  }

  Future getDashboardCounts() async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_DETAILS + USER_ID;

    response = await http.get(Uri.parse(apiUrl), headers: {
      "Content-Type": "application/json",
      "Authorization": accesstoken
    });

    if (response.statusCode == 200) {
      Navigator.pop(context);
      var tempResp = json.decode(response.body);
      var apiResp = tempResp['data'];
      dashBoardList = [
        {
          "title": "Redeemed Points",
          "description": "Redeemed Points Confirmation",
          "count": apiResp['rewardPoints']
        },
        {
          "title": "Earned Cash Reward",
          "description": "Earned Cash Reward Confirmation",
          "count": apiResp['cash'] ?? '0'
        },
      ];
      setState(() {
        dashBoardList = dashBoardList;
        accountType = USER_ACCOUNT_TYPE;
        parentDealerCode = apiResp['parentDealerCode'] ?? '';
        if (parentDealerCode.isEmpty && accountType == 'Painter') {
          showPopupForDealerCode(context, {
            'dealerCode': parentDealerCode,
            'dealerName': userParentDealerName
          });
        }
      });
    } else {
      Navigator.pop(context);
      error_handling.errorValidation(
          context, response.body, response.body, false);
    }
  }

  Future fetchOtp(String dealerCode) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_PARENT_DEALER_CODE_DETAILS;
    try {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken
        },
        body: json.encode({'dealerCode': dealerCode}),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
        final responseData = json.decode(response.body);
        // Assume the API returns {"success": true/false, "message": "..."}
        if (['', null, 0, false].contains(responseData["data"]['dealerCode'])) {
          throw Exception(responseData["message"] ?? "Failed to fetch OTP.");
        } else {
          userParentDealerMobile = responseData["data"]['mobile'];
          userParentDealerName = responseData["data"]['name'];
          return true;
        }
      } else {
        Navigator.pop(context);
        if (response.statusCode == 400) {
          // throw Exception("Failed to fetch Dealer Code. Status code");
          final responseData = json.decode(response.body);
          _showSnackBar(
            "${responseData['message']}.",
            context,
            false,
          );
          return false;
        } else {
          throw Exception(
              "Failed to fetch OTP. Status code: ${response.statusCode}");
        }
      }
    } catch (error) {
      Navigator.pop(context);
      throw Exception("An error occurred while requesting OTP.");
    }
  }

  Future saveDealerDetails(String dealerCode, String otp) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;

    try {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": accesstoken
        },
        body: json.encode({
          'dealerCode': dealerCode,
          'otp': otp,
          'mobile': userParentDealerMobile,
          'painterMobile': USER_MOBILE_NUMBER
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (['', null, 0, false]
            .contains(responseData?["data"]?['parentDealerCode'])) {
          throw Exception(responseData["message"] ?? "Failed to save details.");
        } else {
          return true;
        }
      } else {
        throw Exception(
            "Failed to save details. Status code: ${response.statusCode}");
      }
    } catch (error) {
      throw Exception("An error occurred while saving dealer details.");
    }
  }

  void logOut(context) async {
    clearStorage();
    // print('logout api check====');
    // Utils.returnScreenLoader(context);
    // http.Response response;
    // Map map = {
    //   "userid": USER_ID,
    // };
    // var body = json.encode(map);
    // response = await http.post(
    //   Uri.parse(BASE_URL + API_LOGOUT),
    //   headers: {"Content-Type": "application/json", "Authorization": accesstoken},
    //   body: body,
    // );
    // stringResponse = response.body;
    // mapResponse = json.decode(response.body);
    // if (response.statusCode == 200) {
    //   Navigator.pop(context);
    //   if (mapResponse["status"] == "success") {
    //     _showSnackBar(mapResponse['message'], context, true);
    //     clearStorage();
    //   } else {
    //     error_handling.errorValidation(
    //         context, response.statusCode, mapResponse['message'], false);
    //   }
    // } else {
    //   Navigator.pop(context);
    //   error_handling.errorValidation(
    //       context, response.statusCode, mapResponse['message'], false);
    // }
  }

  Future deleteUserAccount() async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + DELETE_USER_ACCOUNT + USER_ID;

    // print('delete apiturl====>${apiUrl}');

    response = await http.put(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": accesstoken
      },
      body: jsonEncode({}),
    );

    // print('error====>${response.body}======>${response.statusCode}');

    if (response.statusCode == 200) {
      Navigator.pop(context);
      Navigator.pop(context);
      _showSnackBar('Account deleted successfully.', context, true);
      clearStorage();
    } else {
      Navigator.pop(context);
      error_handling.errorValidation(
          context, response.body, response.body, false);
    }
  }

  void showAccountDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  // backgroundColor: Colors.red,
                  ),
              onPressed: () {
                // Add your account deletion logic here
                // Navigator.of(context).pop();
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: Text('Account deleted successfully.'),
                //   ),
                // );
                deleteUserAccount();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
    // print('back button hitted');
    Utils.clearToasts(context);
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // final double screenHeight = MediaQuery.of(context).size.height;
    // FocusNode _focusNode = FocusNode();
    // TextEditingController _searchController = TextEditingController();
    final double screenWidth = MediaQuery.of(context).size.width;
    SizeConfig().init(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: white,
        drawer: MyDrawer(
          accountName: USER_FULL_NAME.toString(),
          accountRole: USER_ID.toString(),
          backendRole: BACKEND_ROLE,
          accountEmail: USER_EMAIL.toString(),
          accountMobile: USER_MOBILE_NUMBER.toString(),
          accountType: USER_ACCOUNT_TYPE.toString(),
          onLogout: () => {logOut(context)},
          onAccountDelete: () => {showAccountDeletionDialog(context)},
        ),
        body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 1,
                child: Center(
                    child: Container(
                        color: white,
                        child: Column(
                          children: [
                            Container(
                                margin: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height *
                                        0.07,
                                    left: MediaQuery.of(context).size.width *
                                        0.05,
                                    right: MediaQuery.of(context).size.width *
                                        0.05),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      // width: getScreenWidth(300),
                                      // height: getScreenWidth(40),
                                      child: Row(
                                        children: [
                                          Container(
                                              height: getScreenWidth(40),
                                              child: Image.asset(
                                                  'assets/images/app_icon.png')),
                                          Container(
                                              height: getScreenWidth(25),
                                              child: Image.asset(
                                                  'assets/images/app_name.png')),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            _scaffoldKey.currentState
                                                ?.openDrawer();
                                          },
                                          child: Container(
                                            height: getScreenWidth(30),
                                            width: getScreenWidth(30),
                                            decoration: BoxDecoration(
                                              color: loginBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      getScreenWidth(15)),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: getScreenHeight(4),
                                                  horizontal:
                                                      getScreenWidth(4)),
                                              child: Image.asset(
                                                'assets/images/menu@3x.png',
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () {
                                            Navigator.pushNamed(
                                                    context, '/qrScanner')
                                                .then((result) {
                                              if (result == true) {
                                                getDashboardCounts();
                                                setState(() {});
                                              }
                                            });
                                          },
                                          child: Container(
                                            height: getScreenWidth(30),
                                            width: getScreenWidth(30),
                                            decoration: BoxDecoration(
                                              color: loginBgColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      getScreenWidth(15)),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(
                                                  getScreenWidth(6)),
                                              child: Center(
                                                child: Icon(
                                                  FontAwesomeIcons.qrcode,
                                                  size: getScreenWidth(22),
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            ),


                            


                            Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: getScreenHeight(16),
                                  horizontal: getScreenWidth(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ' Dashboard',
                                    style: TextStyle(
                                      color: HeadingTextColor,
                                      fontSize: getScreenWidth(14),
                                      fontFamily: ffGSemiBold,
                                    ),
                                  ),
                                  SizedBox(height: getScreenHeight(10)),
                                  Container(
                                    // onRefresh: getDashboardCounts,
                                    color: whiteBgColor,
                                    child: dashBoardList.isEmpty
                                        ? Container(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.6,
                                            child: ListView(
                                              physics:
                                                  AlwaysScrollableScrollPhysics(), // Ensures scroll behavior
                                              children: [],
                                            ),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(), // Ensures scrollability
                                            padding: EdgeInsets.zero,
                                            itemCount: dashBoardList.length,
                                            itemBuilder: (context, index) {
                                              var dashboardCard =
                                                  dashBoardList[index];
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  InkWell(
                                                    onTap: () {},
                                                    child: _buildDashboardCard(
                                                      dashboardCard['title']
                                                          .toString(),
                                                      dashboardCard[
                                                              'description']
                                                          .toString(),
                                                      dashboardCard['count']
                                                          .toString(),
                                                      buttonTextBgColor,
                                                      buttonTextBgColor,
                                                      '',
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          getScreenHeight(5)),
                                                ],
                                              );
                                            },
                                          ),
                                  ),
                                  Container(
                                      child: accountType == 'Painter'
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                    height: getScreenHeight(
                                                        20)), // Add some space between sections
                                                Text(' Dealer details',
                                                    style: TextStyle(
                                                        color: HeadingTextColor,
                                                        fontSize:
                                                            getScreenWidth(14),
                                                        fontFamily:
                                                            ffGSemiBold)),
                                                SizedBox(
                                                    height:
                                                        getScreenHeight(10)),
                                                Container(
                                                  color: whiteBgColor,
                                                  child: Column(
                                                    children: [
                                                      _buildDealerDetailCard(
                                                        "Dealer Code ",
                                                        parentDealerCode != ''
                                                            ? parentDealerCode
                                                            : 'NA',
                                                        buttonTextBgColor,
                                                        buttonTextBgColor,
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column()),
                                ],
                              ),
                            ),
                          ],
                        ))),
              ),
            )),
      ),
    );
  }

  Widget _buildDealerDetailCard(
      String title, String value, Color bgColor, Color borderColor) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getProportionateScreenWidth(10)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(15),
          horizontal: getProportionateScreenWidth(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(16),
                  fontFamily: ffGSemiBold,
                  color: buttonBorderColor,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: getProportionateScreenWidth(16),
                  fontWeight: FontWeight.bold,
                  fontFamily: ffGMedium,
                  color: appButtonColor,
                ),
              ),
            ]),
            Container(
              child: value.isNotEmpty
                  ? InkWell(
                      onTap: () {
                        showPopupForDealerCode(context, {
                          'dealerCode': parentDealerCode,
                          'dealerName': userParentDealerName
                        });
                      },
                      child: Container(
                        child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Icon(Icons.edit,
                                size: 25, weight: 600, color: appButtonColor)),
                      ),
                    )
                  : Container(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(String productName, String units, totalData) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: () async {
        Utils.clearToasts(context);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('tripNumber', totalData['tripNumber']);
        await prefs.setString('tripId', totalData['tripId'].toString());
        Navigator.pushNamed(context, '/tripDetails', arguments: {
          "responseData": totalData,
          "lrNumber": totalData['lrNumber'],
          "fromScreen": 'dashBoard'
        }).then((result) {
          setState(() {
            searchValue = '';
            searchListData = [];
            _searchController.clear();
          });
        });
      },
      child: Container(
        margin: EdgeInsets.only(top: 5),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: Icon(
                  Icons.book,
                  size: 18,
                  color: backButtonCircleIconColor,
                )),
            Container(
              width: screenWidth * 0.5,
              child: Text(productName,
                  style: TextStyle(fontFamily: ffGMedium, fontSize: 16)),
            ),
            Text(units, style: TextStyle(fontFamily: ffGMedium, fontSize: 16)),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: backButtonCircleIconColor,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(String title, String subtitle, String count,
      Color bgColor, Color borderColor, String fromButton) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(getScreenWidth(10)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
            top: getScreenHeight(20),
            bottom: getScreenHeight(20),
            left: getScreenWidth(14),
            right: (fromButton == 'indent_create'
                ? getScreenWidth(30)
                : getScreenWidth(0))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: fromButton == 'indent_create'
                  ? getScreenWidth(200)
                  : getScreenWidth(200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        fontSize: getScreenWidth(16),
                        fontFamily: ffGSemiBold,
                        color: buttonBorderColor),
                  ),
                  SizedBox(height: getScreenHeight(8)),
                  Container(
                    width: fromButton == 'indent_create'
                        ? getScreenWidth(200)
                        : getScreenWidth(190),
                    child: Text(subtitle,
                        style: TextStyle(
                            fontSize: getScreenWidth(14),
                            height: 1,
                            fontFamily: ffGMediumItalic,
                            color: subHeadingTextColor)),
                  ),
                ],
              ),
            ),
            count == "#123"
                ? Container(
                    width: getScreenWidth(60),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: appThemeColor,
                      size: getScreenWidth(50),
                    ),
                  )
                : Container(
                    width: getScreenWidth(120),
                    alignment: Alignment.center,
                    child: Text(
                      count,
                      style: TextStyle(
                          fontSize: getScreenWidth(37),
                          fontWeight: FontWeight.bold,
                          color: appButtonColor,
                          fontFamily: ffGBold),
                    ),
                  )
          ],
        ),
      ),
    );
  }

  void showPopupForDealerCode(
      BuildContext context, Map<String, dynamic> response) {
    final
        // showPopupForDealerCode(context, {'dealerCode': parentDealerCode, 'dealerName': userParentDealerName});

        // Controller for the input fields
        TextEditingController dealerCodeController = TextEditingController();
    List<TextEditingController> otpControllers =
        List.generate(6, (index) => TextEditingController());

    bool isOtpVisible = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent closing the dialog by clicking outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: () async => false, // Disable the back button
              child: Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(getScreenWidth(10)),
                ),
                elevation: 10,
                child: Container(
                  width: 400,
                  padding: EdgeInsets.all(getScreenWidth(16)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Dealer Details",
                        style: TextStyle(
                            fontSize: getScreenWidth(20),
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: getScreenHeight(10)),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(getScreenWidth(10)),
                          border: Border.all(
                            width: getScreenWidth(1),
                            color: Colors.grey,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: TextField(
                          controller: dealerCodeController,
                          keyboardType: TextInputType.text,
                          onTapOutside: (event) {
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          decoration: InputDecoration(
                            labelText: 'Enter Dealer Code',
                            labelStyle: TextStyle(
                              fontFamily: 'Medium',
                              fontSize: getScreenWidth(18),
                              color: Colors.grey,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: getScreenHeight(15),
                                horizontal: getScreenWidth(15)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (isOtpVisible) ...[
                        SizedBox(height: getScreenHeight(20)),
                        Text("Enter OTP",
                            style: TextStyle(fontSize: getScreenWidth(16))),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: getScreenWidth(40),
                              child: TextField(
                                controller: otpControllers[index],
                                maxLength: 1,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  counterText: "",
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    FocusScope.of(context).nextFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    FocusScope.of(context).previousFocus();
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: getScreenHeight(10)),
                        Text(
                            'The 6-digit OTP was sent to the ${userParentDealerName}. OTP expiry time is 10 minutes.',
                            style: TextStyle(fontSize: getScreenWidth(15))),
                        StreamBuilder<int>(
                          stream: Stream.periodic(
                                  Duration(seconds: 1), (i) => 600 - i - 1)
                              .take(600),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final remainingSeconds = snapshot.data!;
                              final minutes = remainingSeconds ~/ 60;
                              final seconds = remainingSeconds % 60;
                              return Text(
                                'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    fontSize: getScreenWidth(15),
                                    fontWeight: FontWeight.bold),
                              );
                            }
                            return SizedBox.shrink();
                          },
                        ),
                      ],
                      SizedBox(height: getScreenHeight(20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!response['dealerCode'].isEmpty)
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("Cancel"),
                            ),
                          if (!isOtpVisible)
                            TextButton(
                              onPressed: () async {
                                if (dealerCodeController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text("Please enter Dealer Code."),
                                    ),
                                  );
                                  return;
                                }

                                setState(() => isLoading = true);

                                try {
                                  bool success =
                                      await fetchOtp(dealerCodeController.text);
                                  if (success) {
                                    setState(() {
                                      isOtpVisible = true;
                                      isLoading = false;
                                      Navigator.pop(context);
                                    });
                                  } else {
                                    setState(() {
                                      isOtpVisible = false;
                                      isLoading = false;
                                      Navigator.pop(context);
                                    });
                                  }
                                } catch (error) {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              },
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : Text("Get OTP"),
                            ),
                          if (isOtpVisible)
                            TextButton(
                              onPressed: () async {
                                String otp =
                                    otpControllers.map((e) => e.text).join();
                                if (otp.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Please enter a valid 6-digit OTP.")),
                                  );
                                  return;
                                }

                                setState(() => isLoading = true);

                                try {
                                  bool saveSuccess = await saveDealerDetails(
                                    dealerCodeController.text,
                                    otp,
                                  );
                                  if (saveSuccess) {
                                    setState(() => isLoading = false);
                                    getDashboardCounts();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Details saved successfully.")),
                                    );
                                    Navigator.pop(context, true);
                                    Navigator.pop(context, true);
                                  }
                                } catch (error) {
                                  setState(() => isLoading = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error.toString())),
                                  );
                                }
                              },
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : Text("Save"),
                            ),
                        ],
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

void _navigateTo(BuildContext context, String routeName) {
  Utils.clearToasts(context);
  Navigator.pop(context);
  Navigator.pushNamed(context, routeName);
}

TextStyle drawerItemStyle = TextStyle(
  color: drawerSubListColor,
  fontFamily: ffGMedium,
  fontSize: getScreenWidth(16),
);

class MyDrawer extends StatelessWidget {
  final String accountName;
  final String accountRole;
  final String backendRole;
  final String accountEmail;
  final String accountMobile;
  final String accountType;
  final VoidCallback onLogout;
  final VoidCallback onAccountDelete;

  MyDrawer({
    required this.accountName,
    required this.accountRole,
    required this.backendRole,
    required this.accountEmail,
    required this.accountMobile,
    required this.accountType,
    required this.onLogout,
    required this.onAccountDelete,
  });
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Drawer(
      width: getScreenWidth(200),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.1, horizontal: getScreenWidth(20)),
          children: <Widget>[
            Text(
              accountName,
              style: TextStyle(
                color: drawerTitleColor,
                fontFamily: ffGBold,
                fontSize: getScreenWidth(24),
              ),
            ),
            Text(
              accountMobile,
              style: TextStyle(
                color: drawerTitleColor,
                fontFamily: ffGMedium,
                fontSize: getScreenWidth(14),
              ),
            ),
            Divider(thickness: getScreenHeight(1)),
            SizedBox(
                height: getScreenHeight(
                    15)), // Consistent spacing before the ListTile items
            Container(
              height: screenHeight * 0.6,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Home',
                      style: TextStyle(
                        color: appThemeColor,
                        fontFamily: ffGSemiBold,
                        fontSize: getScreenWidth(22),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                onAccountDelete();
              },
              child: ListTile(
                title: Center(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                        decoration: TextDecoration.underline,
                        decorationThickness: 1.5,
                        fontSize: getScreenWidth(14),
                        fontFamily: ffGMedium,
                        color: appThemeColor),
                  ),
                ),
              ),
            ),
            // SizedBox(height: 10),
            Divider(thickness: getScreenHeight(1)),
            // Container(
            //   margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.2),
            //   child: Divider(thickness: 2),
            // ),
            InkWell(
              onTap: () {
                // Navigator.pop(context);
                onLogout();
              },
              child: ListTile(
                title: Center(
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      decorationThickness: 1.5,
                      color: drawerSubListColor,
                      fontFamily: ffGMedium,
                      fontSize: getScreenWidth(22),
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
}
