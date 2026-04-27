import 'dart:convert';
import 'dart:async';

import 'package:aultra_paints_mobile/screens/myOrders/OrderDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/config.dart';
import '../../services/secure_token_store.dart';
import '../../services/error_handling.dart';
import '../../utility/Utils.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_badge.dart';
import '../../widgets/primitives/app_empty_state.dart';
import '../../widgets/primitives/app_list_row.dart';

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
    accesstoken = await SecureTokenStore.instance.readToken();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          Expanded(
            child: myOrdersList.isEmpty && !isLoading
                ? AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'Your orders will appear here.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _reloadOrders(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(AppSpacing.md),
                      itemCount:
                          myOrdersList.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= myOrdersList.length) {
                          return Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          );
                        }
                        final order = myOrdersList[i];
                        final String orderId =
                            order['orderId']?.toString() ?? '-';
                        final String status =
                            (order['status'] ?? 'PENDING')
                                .toString()
                                .toUpperCase();
                        final String total =
                            order['totalPrice']?.toString() ?? '-';
                        final String createdAt =
                            order['createdAt'] != null
                                ? Utils.formatDate(order['createdAt'])
                                    .split(' ')[0]
                                : '-';
                        return Padding(
                          padding:
                              EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppListRow(
                            title: 'Order #$orderId',
                            subtitle:
                                '₹ $total · $createdAt',
                            trailing: AppBadge(
                              label: status,
                              tone: _toneForStatus(status),
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OrderDetailsScreen(order: order),
                                ),
                              );
                              if (result == true) {
                                _reloadOrders();
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
