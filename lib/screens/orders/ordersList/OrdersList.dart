import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/error_handling.dart';
import '../../../services/config.dart';
import '../../../utility/Utils.dart';
import 'package:http/http.dart' as http;
import '../../../services/secure_token_store.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_app_bar.dart';
import '../../../widgets/primitives/app_badge.dart';
import '../../../widgets/primitives/app_empty_state.dart';
import '../../../widgets/primitives/app_list_row.dart';

AppBadgeTone _toneForStatus(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'SHIPPED':
    case 'DELIVERED':
    case 'COMPLETED':
    case 'SUCCESS':
      return AppBadgeTone.success;
    case 'FAILED':
    case 'CANCELLED':
    case 'REJECTED':
      return AppBadgeTone.error;
    case 'PENDING':
    case 'IN PROGRESS':
    case 'IN_PROGRESS':
    case 'PROCESSING':
      return AppBadgeTone.info;
    default:
      return AppBadgeTone.neutral;
  }
}

class OrdersList extends StatefulWidget {
  const OrdersList({Key? key}) : super(key: key);

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  int? selected;

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
    _vehicleNumberController.dispose();
    _driverNameController.dispose();
    _driverMobileNoController.dispose();
    _driverLicenseNoController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  fetchLocalStorageData() async {
    accesstoken = await SecureTokenStore.instance.readToken();
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppAppBar(
          title: 'Orders List',
          leading: AppAppBarAction(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ordersList.isEmpty
                  ? AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      message: 'Your orders will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: getOrdersList,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppSpacing.md),
                        itemCount: ordersList.length,
                        itemBuilder: (context, index) {
                          final o =
                              ordersList[index] as Map<String, dynamic>;
                          final status = (o['status'] ?? '').toString();
                          final brand = o['brand']?.toString() ?? '';
                          final productName =
                              o['productName']?.toString() ?? '';
                          final quantity =
                              o['quantity']?.toString() ?? '';
                          final volume = o['volume']?.toString() ?? '';
                          return Padding(
                            padding:
                                EdgeInsets.only(bottom: AppSpacing.sm),
                            child: AppListRow(
                              title: productName.isNotEmpty
                                  ? productName
                                  : brand,
                              subtitle:
                                  'Qty: $quantity · Vol: $volume',
                              trailing: status.isNotEmpty
                                  ? AppBadge(
                                      label: status,
                                      tone: _toneForStatus(status),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/orderDetails',
                                  arguments: {'orderDetails': o},
                                ).then((result) {
                                  if (result == true) {
                                    getOrdersList();
                                    setState(() {});
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
