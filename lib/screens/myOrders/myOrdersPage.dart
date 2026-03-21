import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:aultra_paints_mobile/screens/myOrders/OrderDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../services/config.dart';
import '../../services/error_handling.dart';
import '../../utility/Utils.dart';
import '../../utility/size_config.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  _MyOrdersPageState createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _debounce;

  String? accesstoken;
  List<dynamic> myOrdersList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchLocalStorageData();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      getMyOrdersList();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadOrders();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reloadOrders();
  }

  void _reloadOrders() async {
    setState(() {
      myOrdersList.clear();
      currentPage = 1;
      hasMore = true;
    });
    await fetchLocalStorageData();
  }

  Future<void> fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    await getMyOrdersList();
  }

  Future<void> getMyOrdersList() async {
    if (isLoading || accesstoken == null || !hasMore) return;
    setState(() => isLoading = true);

    bool loaderShown = false;
    try {
      Utils.returnScreenLoader(context);
      loaderShown = true;

      final apiUrl = BASE_URL + GET_CART_ORDERS_LIST;
      var query = {
        'page': currentPage,
        'limit': 1000,
      };
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
        body: json.encode(query),
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('responseData======>${responseData}');

        if (responseData['orders'] is List) {
          List<dynamic> newData = responseData['orders'];
          if (mounted) {
            setState(() {
              myOrdersList.addAll(newData);
              currentPage++;
              hasMore = newData.length >= 10;
            });
          }
        }
      } else {
        error_handling.errorValidation(
          context,
          'Error fetching orders',
          response.body,
          false,
        );
      }
    } catch (error) {
      error_handling.errorValidation(
        context,
        'Failed to fetch orders',
        error.toString(),
        false,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
      if (loaderShown) {
        Navigator.pop(context);
      }
    }
  }

  // Future<void> getMyOrdersList() async {
  //   if (isLoading || accesstoken == null || !hasMore) return;
  //   setState(() => isLoading = true);
  //   Utils.returnScreenLoader(context);
  //   try {
  //     final apiUrl = BASE_URL + GET_CART_ORDERS_LIST;
  //     var query = {
  //       'page': currentPage,
  //       'limit': 10,
  //     };
  //     final response = await http.get(
  //       Uri.parse(apiUrl),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": accesstoken!,
  //       },
  //     );
  //     if (response.statusCode == 200) {
  //       Navigator.pop(context);
  //       final responseData = json.decode(response.body);

  //       if (responseData['orders'] is List) {
  //         List<dynamic> newData = responseData['orders'];
  //         if (mounted) {
  //           setState(() {
  //             myOrdersList.addAll(newData);
  //             currentPage++;
  //             hasMore = newData.length >= 10;
  //           });
  //         }
  //         print('myOrdersList responseData====>${myOrdersList}  ');
  //       }
  //     } else {
  //       Navigator.pop(context);
  //       error_handling.errorValidation(
  //         context,
  //         'Error fetching orders',
  //         response.body,
  //         false,
  //       );
  //     }
  //   } catch (error) {
  //     Navigator.pop(context);
  //     error_handling.errorValidation(
  //       context,
  //       'Failed to fetch orders',
  //       error.toString(),
  //       false,
  //     );
  //   } finally {
  //     if (mounted) {
  //       setState(() => isLoading = false);
  //       Navigator.pop(context);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        height: getScreenHeight(800),
        width: getScreenWidth(400),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFFFF7AD), // same as ProductsCatalogScreen
              Color(0xFFFFA9F9),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(left: getScreenWidth(20)),
              child: Text(
                'My Orders',
                style: TextStyle(
                  fontSize: getScreenWidth(20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3533CD),
                ),
              ),
            ),
            Expanded(
                child: myOrdersList.isEmpty && !isLoading
                    ? Center(
                        child: Text('No orders found',
                            style: TextStyle(color: Colors.white)))
                    : listBuilderCards())
          ],
        ),
      ),
    );
  }

  Widget listBuilderCards() {
    return ListView.builder(
      itemCount: myOrdersList.length,
      itemBuilder: (context, index) {
        final order = myOrdersList[index];
        final String orderId = order['orderId']?.toString() ?? '-';
        final String status =
            (order['status'] ?? 'PENDING').toString().toUpperCase();
        final String total = order['totalPrice']?.toString() ?? '-';
        final String createdAt = order['createdAt'] != null
            ? Utils.formatDate(order['createdAt']).split(' ')[0]
            : '-';

        // Color coding for status
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

        return InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsScreen(order: order),
              ),
            );
            if (result == true) {
              _reloadOrders();
            }
          },
          child: Card(
            margin: EdgeInsets.symmetric(
                horizontal: getScreenWidth(18), vertical: getScreenHeight(12)),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(getScreenWidth(16)),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: getScreenWidth(18.0),
                  vertical: getScreenHeight(18.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order ID: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: getScreenWidth(15),
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                          Text(
                            orderId,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: getScreenWidth(15),
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        createdAt,
                        style: TextStyle(
                            fontSize: getScreenWidth(15), color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(height: getScreenHeight(6)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (order['focusOrderId'] != null &&
                          order['focusOrderId'].toString().isNotEmpty)
                        Row(
                          children: [
                            Text(
                              'Invoice No: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: getScreenWidth(14),
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                            Text(
                              order['focusOrderId'].toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: getScreenWidth(14),
                                color: Colors.black,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Text(
                              'Total: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: getScreenWidth(14)),
                            ),
                            Text(
                              '₹$total',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: getScreenWidth(14),
                                  color: Color(0xFF3533CD)),
                            ),
                          ],
                        ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: getScreenWidth(16),
                            vertical: getScreenHeight(7)),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.18),
                          border: Border.all(color: statusColor, width: 1.2),
                          borderRadius:
                              BorderRadius.circular(getScreenWidth(20)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: getScreenWidth(13),
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order['focusOrderId'] != null &&
                      order['focusOrderId'].toString().isNotEmpty) ...[
                    SizedBox(height: getScreenHeight(6)),
                    Row(
                      children: [
                        Text(
                          'Total: ',
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: getScreenWidth(14)),
                        ),
                        Text(
                          '₹$total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: getScreenWidth(14),
                              color: Color(0xFF3533CD)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
