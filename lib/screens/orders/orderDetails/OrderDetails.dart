import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../services/config.dart';
import '../../../services/error_handling.dart';
import '../../../utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_app_bar.dart';
import '../../../widgets/primitives/app_badge.dart';
import '../../../widgets/primitives/app_card.dart';

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

class OrderDetails extends StatefulWidget {
  const OrderDetails({Key? key}) : super(key: key);

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  int? selected;

  String? accessToken;
  dynamic orderDetails;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchLocalStorageData();
    });
  }

  Future<void> fetchLocalStorageData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      accessToken = prefs.getString('accessToken');

      final arguments = ModalRoute.of(context)?.settings.arguments as Map?;
      if (arguments != null && arguments.containsKey('orderDetails')) {
        final orderId = arguments['orderDetails']['_id'];
        await getOrderById(orderId);
      }
    } catch (e) {
      _showSnackBar('Failed to fetch data', context, false);
    }
  }

  void _showSnackBar(String message, BuildContext context, bool isSuccess) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      duration: Utils.returnStatusToastDuration(isSuccess),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> getOrderById(String orderId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$BASE_URL$GET_ORDER_BY_ID$orderId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accessToken ?? '',
        },
      );

      if (response.statusCode == 200) {
        final apiResp = json.decode(response.body);
        setState(() {
          orderDetails = apiResp['data'];
        });
      } else {
        error_handling.errorValidation(
          context,
          response.statusCode,
          response.body,
          false,
        );
      }
    } catch (e) {
      _showSnackBar('Failed to fetch order details', context, false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final brand = orderDetails?['brand']?.toString() ?? '';
    final productName = orderDetails?['productName']?.toString() ?? '';
    final volume = orderDetails?['volume']?.toString() ?? '';
    final quantity = orderDetails?['quantity']?.toString() ?? '';
    final status = orderDetails?['status']?.toString() ?? '';

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppAppBar(
          title: 'Order Details',
          leading: AppAppBarAction(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(strokeWidth: 2))
            : orderDetails != null
                ? ListView(
                    padding: EdgeInsets.all(AppSpacing.md),
                    children: [
                      AppCard(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ORDER #',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall!
                                            .copyWith(
                                                color: AppColors
                                                    .onSurfaceVariant),
                                      ),
                                      Text(
                                        productName.isNotEmpty
                                            ? productName
                                            : brand,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (status.isNotEmpty)
                                  AppBadge(
                                    label: status,
                                    tone: _toneForStatus(status),
                                  ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Qty: $quantity · Vol: $volume',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      color: AppColors.onSurfaceVariant),
                            ),
                            if (brand.isNotEmpty &&
                                productName.isNotEmpty) ...[
                              Divider(
                                  height: AppSpacing.md,
                                  color: AppColors.outline),
                              Row(
                                children: [
                                  Text('Brand'),
                                  Spacer(),
                                  Text(
                                    brand,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall!
                                        .copyWith(
                                            color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'ITEMS',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall!
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      AppCard(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.infoBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    productName.isNotEmpty
                                        ? productName
                                        : brand,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  if (brand.isNotEmpty)
                                    Text(
                                      brand,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color: AppColors
                                                  .onSurfaceVariant),
                                    ),
                                  Row(
                                    children: [
                                      if (quantity.isNotEmpty)
                                        Text(
                                          'Qty $quantity',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      Spacer(),
                                      if (volume.isNotEmpty)
                                        Text(
                                          'Vol: $volume',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  color:
                                                      AppColors.primary),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      'No order details available.',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: AppColors.onSurfaceVariant),
                    ),
                  ),
      ),
    );
  }
}
