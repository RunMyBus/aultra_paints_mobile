import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/error_handling.dart';
import '../../../utility/SingleParamHeader.dart';
import '../../../utility/size_config.dart';
import '/utility/Colors.dart';
import '/utility/Fonts.dart';
import '/utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../services/config.dart';

class OrdersList extends StatefulWidget {
  const OrdersList({Key? key}) : super(key: key);

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  int? selected;
  List<Color> redColors = [reportIncidentStartColor, reportIncidentEndColor];
  List<Color> whiteColors = [white, white];

  var accesstoken;
  var USER_ID;
  var Company_ID;

  String stringResponse = '';
  Map mapResponse = {};

  bool showProductDetailsCard = false;

  var selectedCardIndex;

  var ordersList = [];

  var argumentData;
  String argumentStatus = '';

  var loggedUserRole;

  var vehicleType;
  var gpsDeviceId;
  var gpsDeviceName = "GPS Device";
  var gpsDisplayName = "GPS Device";
  var vehicleId;
  var driverId;
  var driverLicenseNo = '';
  bool isVehicleVerified = false;
  bool isDriverVerified = false;
  var gpsDeviceId_new;
  var gpsDeviceName_new = "GPS Device";
  var gpsDisplayName_new = "GPS Device";
  var driverName = "Select a Driver";
  var driverMobileNo;
  var vehicleNumber = "Select a Vehicle";
  String selectedCard = '';
  Map<String, dynamic> fetchSearchData = {};
  late TextEditingController _vehicleNumberController;
  late TextEditingController _driverNameController;
  late TextEditingController _driverMobileNoController;
  late TextEditingController _driverLicenseNoController;
  TextEditingController _dobController = TextEditingController();

  String selectedLrNumber = "";
  String selectedVehicle = "";
  String selectedChallan = "";
  String selectedState = "";

  @override
  void initState() {
    fetchLocalStorageData();
    super.initState();
    _vehicleNumberController = TextEditingController();
    _driverNameController = TextEditingController();
    _driverMobileNoController = TextEditingController();
    _driverLicenseNoController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose of each controller when done
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverMobileNoController.dispose();
    _driverLicenseNoController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    getOrdersList();
  }

  onBackPressed() {
    Navigator.pop(context, true);
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future getOrdersList() async {
    Utils.returnScreenLoader(context);
    http.Response response;

    response = await http.get(Uri.parse(BASE_URL + GET_ORDERS), headers: {
      "Content-Type": "application/json",
      "Authorization": accesstoken
    });

    if (response.statusCode == 200) {
      Navigator.pop(context);
      setState(() {
        stringResponse = response.body;
        mapResponse = json.decode(response.body);
        ordersList = mapResponse['data'];
      });
    } else {
      Navigator.pop(context);
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, true);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: whiteBgColor,
        body: Column(
          children: [
            SingleParamHeader('Orders List', '', context, false,
                () => Navigator.pop(context, true)),
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    height: screenHeight * 0.8,
                    child: ordersList.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: ffGBold,
                                    color: buttonBorderColor),
                              ),
                            ],
                          )
                        : RefreshIndicator(
                            onRefresh: getOrdersList,
                            color: appThemeColor,
                            backgroundColor: Colors.white,
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.all(16),
                              itemCount: ordersList.length,
                              itemBuilder: (context, index) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCard(ordersList[index], index),
                                  ],
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> orderDetails, index) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: () {
        Navigator.pushNamed(
          context,
          '/orderDetails',
          arguments: {'orderDetails': orderDetails},
        ).then((result) {
          if (result == true) {
            getOrdersList();
            setState(() {});
          }
        });
        ;
      },
      child: Card(
        color: colorFBFBFD,
        elevation:
            selectedCardIndex == index ? getProportionateScreenWidth(1) : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(getProportionateScreenWidth(10)),
          side: BorderSide(
              width: getProportionateScreenWidth(1), color: colorD6D6D6),
        ),
        child: Padding(
          padding: EdgeInsets.only(
              left: getScreenWidth(10),
              right: getScreenWidth(10),
              top: getProportionateScreenWidth(10),
              bottom: getProportionateScreenWidth(10)),
          child: Row(
            // mainAxisAlignment: MainAxisAlignment.spaceAround,
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoWidthColumn(
                            "Brand", orderDetails['brand'], ''),
                        _buildInfoWidthColumn(
                            "Volume", orderDetails['volume'].toString(), ''),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/qrScanner');
                          },
                          child: Icon(
                            Icons.qr_code,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoWidthColumn(
                            "Product Name", orderDetails['productName'], ''),
                        _buildInfoWidthColumn("Quantity",
                            orderDetails['quantity'].toString(), ''),
                        Icon(Icons.arrow_forward_ios),
                      ],
                    ),
                  ],
                ),
              ),
              // SizedBox(width: getProportionateScreenWidth(10)),
              // Expanded(
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.end,
              //     children: [
              //       Icon(Icons.qr_code),
              //       SizedBox(width: getProportionateScreenWidth(10)),
              //       Icon(Icons.arrow_forward_ios),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: 12, color: labelTextColor, fontFamily: ffGSemiBold),
        ),
        // SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              fontSize: 14,
              color: labelValueTextColor,
              fontFamily: ffGSemiBold),
        ),
      ],
    );
  }

  Widget _buildInfoWidthColumn(
      String label, String value, String placementSide) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: placementSide == 'totalLength'
          ? screenWidth * 0.84
          : screenWidth * 0.35,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        // placementSide == 'left' || placementSide == 'totalLength'
        //     ? CrossAxisAlignment.start
        //     : CrossAxisAlignment.end,
        children: [
          Text(
            label,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12, color: labelTextColor, fontFamily: ffGSemiBold),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 14,
                color: labelValueTextColor,
                fontFamily: ffGSemiBold),
          ),
        ],
      ),
    );
  }
}
