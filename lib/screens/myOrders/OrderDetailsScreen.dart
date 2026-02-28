import 'package:flutter/material.dart';
import '../../utility/size_config.dart';
import '../../utility/Utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_status_action.dart';
import '../../services/config.dart';
import '../../services/error_handling.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool isFocusEntitiesLoading = false;
  List<Map<String, dynamic>> focusEntities = [];
  String? selectedFocusEntity;

  // Primary color used in this screen
  final Color primaryColor = const Color(0xFF7A0180);

  @override
  void initState() {
    super.initState();
    // Fetch focus entities if needed, based on business logic
    // For now, we only fix compilation errors.
    // If this should be called on load, uncomment the following line:
    // fetchFocusEntities(context);
    // However, since it requires context which might not be ready,
    // typically we call it in addPostFrameCallback or separate init method.
    // Given the original code didn't call it, I'll leave it as is but accessible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accountType =
          Provider.of<AuthProvider>(context, listen: false).userAccountType;
      if (widget.order['status'] == 'PENDING' &&
          accountType == 'SalesExecutive') {
        fetchFocusEntities(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final accountType =
        Provider.of<AuthProvider>(context).userAccountType ?? '';
    print('accountType====>${accountType}');
    final String orderId = order['orderId']?.toString() ?? '-';

    final String status =
        (order['status'] ?? 'PENDING').toString().toUpperCase();

    final String createdAt = order['createdAt'] != null
        ? Utils.formatDate(order['createdAt']).split(' ')[0]
        : '-';
    final List<dynamic> items = order['items'] ?? [];
    Color statusColor;
    switch (status) {
      case 'VERIFIED':
        statusColor = Colors.green;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.orange;
    }

    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, true);
          return false;
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFFFF7AD), Color(0xFFFFA9F9)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (fixed)
                SafeArea(
                  child: Container(
                    margin: EdgeInsets.only(bottom: getScreenHeight(10)),
                    padding: EdgeInsets.symmetric(
                        vertical: getScreenWidth(10),
                        horizontal: getScreenWidth(20)),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: getScreenWidth(20),
                            ),
                            child: Icon(
                              Icons.keyboard_double_arrow_left_sharp,
                              color: primaryColor,
                              size: getScreenWidth(30),
                            ),
                          ),
                        ),
                        Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: getScreenWidth(18),
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scrollable order details
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(getScreenWidth(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: getScreenHeight(5),
                                horizontal: getScreenWidth(20)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order ID: $orderId',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: getScreenWidth(18),
                                            color: Color(0xFF6A1B9A))),
                                    Row(
                                      children: [
                                        Text(createdAt,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: getScreenWidth(18),
                                                color: Color(0xFF6A1B9A))),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: getScreenHeight(12)),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${order['createdBy']['name']}',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: getScreenWidth(14),
                                                  color: Color(0xFF6A1B9A))),
                                          Text(
                                              '${order['createdBy']['mobile']}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: getScreenWidth(14),
                                                  color: Color(0xFF6A1B9A))),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: getScreenWidth(16),
                                          vertical: getScreenHeight(7)),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.18),
                                        border: Border.all(
                                            color: statusColor, width: 1.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: getScreenWidth(14),
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: getScreenHeight(18)),
                        Divider(thickness: 1, color: Colors.grey[300]),
                        SizedBox(height: getScreenHeight(18)),
                        Text('Items',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: getScreenWidth(16))),
                        ...items.map((item) => Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: getScreenHeight(8)),
                              child: ListTile(
                                title: Text(
                                    item['productOfferDescription'] ?? '-',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: getScreenWidth(16))),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Qty: ${item['quantity'] ?? ""}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: getScreenWidth(16),
                                            color: Color(0xFF6A1B9A))),
                                    Visibility(
                                      visible: item['volume'] != "0",
                                      child: Text(
                                          'Volume: ${item['volume'] ?? ""}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: getScreenWidth(16),
                                              color: Color(0xFF6A1B9A))),
                                    ),
                                  ],
                                ),
                                trailing: Text('₹${item['productPrice'] ?? 0}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: getScreenWidth(16),
                                        color: Color(0xFF6A1B9A))),
                              ),
                            )),
                        SizedBox(height: getScreenHeight(18)),
                        Divider(thickness: 1, color: Colors.grey[300]),
                        SizedBox(height: getScreenHeight(18)),
                        Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: getScreenWidth(18),
                                vertical: getScreenHeight(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Final Price:',
                                        style: TextStyle(
                                            fontSize: getScreenWidth(16),
                                            fontWeight: FontWeight.bold)),
                                    Text('₹${order['finalPrice'] ?? '-'}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: getScreenWidth(17),
                                            color: Color(0xFF3533CD))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: getScreenHeight(18)),
                      ],
                    ),
                  ),
                ),
                // Bottom button (fixed)
                Visibility(
                  visible: order['status'] == 'PENDING' &&
                      accountType == 'SalesExecutive',
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: getScreenWidth(20),
                      right: getScreenWidth(20),
                      bottom: getScreenHeight(16),
                      top: getScreenHeight(8),
                    ),
                    child: SizedBox(
                        width: double.infinity,
                        child: Column(children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: getScreenWidth(12)),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius:
                                  BorderRadius.circular(getScreenWidth(8)),
                              color: Colors.white,
                            ),
                            child: isFocusEntitiesLoading
                                ? Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: getScreenWidth(12)),
                                      child: SizedBox(
                                        width: getScreenWidth(20),
                                        height: getScreenWidth(20),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  primaryColor),
                                        ),
                                      ),
                                    ),
                                  )
                                : DropdownButton<String>(
                                    hint: Text(
                                      'Select Focus Entity',
                                      style: TextStyle(
                                        fontSize: getScreenWidth(14),
                                        color: Colors.grey[600],
                                        fontFamily: 'Roboto',
                                      ),
                                    ),
                                    value: selectedFocusEntity,
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    items: focusEntities
                                        .map<DropdownMenuItem<String>>(
                                            (entity) {
                                      String displayText =
                                          entity['sName'] ?? 'Unknown';
                                      dynamic value =
                                          entity['iMasterId'].toString();

                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(
                                          displayText,
                                          style: TextStyle(
                                            fontSize: getScreenWidth(14),
                                            fontFamily: 'Roboto',
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedFocusEntity = newValue;
                                      });
                                    },
                                  ),
                          ),
                          SizedBox(height: getScreenHeight(16)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize:
                                  Size(double.infinity, getScreenHeight(50)),
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (selectedFocusEntity == null) {
                                _showSnackBar(
                                    'Select Focus Entity', context, false);
                              } else {
                                _onUpdateOrderStatus(context);
                              }
                            },
                            child: const Text(
                              'Update Order Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ])),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void _onUpdateOrderStatus(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return OrderStatusActionSheet(
          onAction: (String action) async {
            Navigator.of(ctx).pop();
            await _updateOrderStatusApi(context, action);
          },
        );
      },
    );
  }

  Future<void> fetchFocusEntities(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return;
    }

    setState(() {
      isFocusEntitiesLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_FOCUS_ENTITIES),
        headers: authProvider.authHeaders,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            focusEntities =
                List<Map<String, dynamic>>.from(responseData['data']);
            print('${focusEntities}');
          });
        }
      } else {
        print('Failed to load focus entities: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching focus entities: $e');
    } finally {
      setState(() {
        isFocusEntitiesLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatusApi(
      BuildContext context, String status) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    Utils.returnScreenLoader(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      final apiUrl = BASE_URL + UPDATE_ORDER_STATUS;
      final tempBody = json.encode({
        'orderId': widget.order['orderId'],
        'isVerified': status == 'APPROVED'
            ? 1
            : status == 'REJECTED'
                ? 0
                : null,
        'entityId': selectedFocusEntity,
      });
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': accessToken,
        },
        body: tempBody,
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ?? 'Order status updated'),
              backgroundColor:
                  status == 'APPROVED' ? Colors.green : Colors.red),
        );
        Navigator.pop(context, true);
      } else {
        error_handling.errorValidation(context, response.statusCode,
            responseData['message'] ?? 'Failed', false);
      }
    } catch (e) {
      Navigator.pop(context, true);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _orderDetailRow(String label, dynamic value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: getScreenHeight(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A1B9A),
                  fontSize: getScreenWidth(16))),
          Expanded(
            child: Text(
              value != null ? value.toString() : '-',
              style: TextStyle(
                  color: Colors.black87, fontSize: getScreenWidth(16)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
