import 'package:flutter/material.dart';
import '../../utility/Utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'order_status_action.dart';
import '../../services/config.dart';
import '../../services/error_handling.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_app_bar.dart';
import '../../widgets/primitives/app_badge.dart';
import '../../widgets/primitives/app_button.dart';
import '../../widgets/primitives/app_card.dart';

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

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool isFocusEntitiesLoading = false;
  bool isFocusWarehousesLoading = false;
  bool isFocusBranchesLoading = false;
  bool isOrderLoading = false;
  List<Map<String, dynamic>> focusEntities = [];
  List<Map<String, dynamic>> focusWarehouses = [];
  List<Map<String, dynamic>> focusBranches = [];
  String? selectedFocusEntity;
  String? selectedWarehouse;
  String? selectedBranch;
  final _narrationController = TextEditingController();
  Map<String, dynamic>? orderDetails;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrderDetails();
    });
  }

  Future<void> fetchOrderDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => isOrderLoading = true);

    try {
      final orderId = widget.order['orderId']?.toString() ?? '';
      final url = BASE_URL + GET_ORDER_DETAILS + orderId;
      final response = await http.get(
        Uri.parse(url),
        headers: authProvider.authHeaders,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          orderDetails =
              responseData['order'] ?? responseData['data'] ?? responseData;
        });
        final accountType = authProvider.userAccountType;
        if ((orderDetails?['status'] ?? widget.order['status']) == 'PENDING' &&
            accountType == 'SalesExecutive') {
          fetchFocusEntities(context);
          fetchFocusWarehouses(context);
          fetchFocusBranches(context);
        }
      } else {
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isOrderLoading = false);
    }
  }

  Future<void> fetchFocusEntities(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;

    setState(() => isFocusEntitiesLoading = true);

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
          });
        }
      }
    } catch (e) {
    } finally {
      setState(() => isFocusEntitiesLoading = false);
    }
  }

  @override
  void dispose() {
    _narrationController.dispose();
    super.dispose();
  }

  Future<void> fetchFocusWarehouses(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;
    setState(() => isFocusWarehousesLoading = true);
    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_FOCUS_WAREHOUSES),
        headers: authProvider.authHeaders,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['warehouses'] != null) {
          setState(() {
            focusWarehouses = List<Map<String, dynamic>>.from(data['warehouses']);
          });
        }
      }
    } catch (e) {
    } finally {
      setState(() => isFocusWarehousesLoading = false);
    }
  }

  Future<void> fetchFocusBranches(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) return;
    setState(() => isFocusBranchesLoading = true);
    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_FOCUS_BRANCHES),
        headers: authProvider.authHeaders,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['warehouses'] != null) {
          setState(() {
            focusBranches = List<Map<String, dynamic>>.from(data['warehouses']);
          });
        }
      }
    } catch (e) {
    } finally {
      setState(() => isFocusBranchesLoading = false);
    }
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

  Future<void> _updateOrderStatusApi(
      BuildContext context, String status) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    Utils.returnScreenLoader(context);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) return;
      final apiUrl = BASE_URL + UPDATE_ORDER_STATUS;
      final tempBody = json.encode({
        'orderId': widget.order['orderId'],
        'isVerified': status == 'APPROVED'
            ? 1
            : status == 'REJECTED'
                ? 0
                : null,
        'entityId': selectedFocusEntity,
        'warehouseId': selectedWarehouse,
        'branchId': selectedBranch,
        if (_narrationController.text.trim().isNotEmpty)
          'narration': _narrationController.text.trim(),
      });
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: authProvider.authHeaders,
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

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final order = orderDetails ?? widget.order;
    final accountType =
        Provider.of<AuthProvider>(context).userAccountType ?? '';
    final String orderId = order['orderId']?.toString() ?? '-';
    final String status =
        (order['status'] ?? 'PENDING').toString().toUpperCase();
    final String createdAt = order['createdAt'] != null
        ? Utils.formatDate(order['createdAt']).split(' ')[0]
        : '-';
    final List<dynamic> items = order['items'] ?? [];
    final String finalPrice = order['finalPrice']?.toString() ?? '-';

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppAppBar(
          title: 'Order Details',
          leading: AppAppBarAction(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: isOrderLoading
            ? Center(child: CircularProgressIndicator(strokeWidth: 2))
            : ListView(
                padding: EdgeInsets.all(AppSpacing.md),
                children: [
                  // --- Summary card ---
                  AppCard(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ORDER #',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall!
                                        .copyWith(
                                            color:
                                                AppColors.onSurfaceVariant),
                                  ),
                                  Text(
                                    orderId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                ],
                              ),
                            ),
                            AppBadge(
                              label: status,
                              tone: _toneForStatus(status),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '$createdAt · ${items.length} item${items.length == 1 ? '' : 's'}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                  color: AppColors.onSurfaceVariant),
                        ),
                        // Invoice IDs if present
                        if (order['focusDCInvoiceId'] != null &&
                            (order['focusDCInvoiceId'] is List
                                ? (order['focusDCInvoiceId'] as List)
                                    .isNotEmpty
                                : order['focusDCInvoiceId']
                                    .toString()
                                    .isNotEmpty)) ...[
                          SizedBox(height: 4),
                          Text(
                            'Invoice: ${order['focusDCInvoiceId'] is List ? (order['focusDCInvoiceId'] as List).join(', ') : order['focusDCInvoiceId'].toString()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    color: AppColors.onSurfaceVariant),
                          ),
                        ],
                        Divider(
                            height: AppSpacing.md, color: AppColors.outline),
                        Row(
                          children: [
                            Text('Total'),
                            Spacer(),
                            Text(
                              '₹ $finalPrice',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // --- Placed by / SalesExecutive dealer context ---
                  if (order['createdBy'] != null) ...[
                    Text(
                      'PLACED BY',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall!
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    AppCard(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['createdBy']?['name'] ?? '-',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (order['createdBy']?['mobile'] != null)
                            Text(
                              order['createdBy']['mobile'].toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      color: AppColors.onSurfaceVariant),
                            ),
                          if (accountType == 'SalesExecutive' &&
                              order['dealerId'] != null) ...[
                            SizedBox(height: AppSpacing.sm),
                            Text(
                              'Order placed for',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall!
                                  .copyWith(
                                      color: AppColors.onSurfaceVariant),
                            ),
                            Text(
                              '${order['dealerId']?['name'] ?? '-'}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (order['dealerId']?['mobile'] != null)
                              Text(
                                order['dealerId']['mobile'].toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                        color: AppColors.onSurfaceVariant),
                              ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ],

                  // --- Items ---
                  Text(
                    'ITEMS',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall!
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  for (final item in items)
                    Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['productOfferDescription'] ?? '-',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  if (item['volume'] != null &&
                                      item['volume'].toString() != '0')
                                    Text(
                                      'Volume: ${item['volume']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color:
                                                  AppColors.onSurfaceVariant),
                                    ),
                                  Row(
                                    children: [
                                      if (item['quantity'] != null)
                                        Text(
                                          'Qty ${item['quantity']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      Spacer(),
                                      if (item['productPrice'] != null)
                                        Text(
                                          '₹ ${item['productPrice']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                  color: AppColors.primary),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // --- SalesExecutive action: Entity + Warehouse + Branch + Narration ---
                  if (order['status'] == 'PENDING' &&
                      accountType == 'SalesExecutive') ...[
                    SizedBox(height: AppSpacing.lg),
                    _focusDropdown(
                      context: context,
                      hint: 'Select Entity',
                      items: focusEntities,
                      value: selectedFocusEntity,
                      isLoading: isFocusEntitiesLoading,
                      onChanged: (v) => setState(() => selectedFocusEntity = v),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _focusDropdown(
                      context: context,
                      hint: 'Select Warehouse',
                      items: focusWarehouses,
                      value: selectedWarehouse,
                      isLoading: isFocusWarehousesLoading,
                      onChanged: (v) => setState(() => selectedWarehouse = v),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _focusDropdown(
                      context: context,
                      hint: 'Select Branch',
                      items: focusBranches,
                      value: selectedBranch,
                      isLoading: isFocusBranchesLoading,
                      onChanged: (v) => setState(() => selectedBranch = v),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: _narrationController,
                      decoration: InputDecoration(
                        labelText: 'Narration (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppButton.filled(
                      label: 'Update Order Status',
                      onPressed: () {
                        if (selectedFocusEntity == null) {
                          _showSnackBar('Select an entity', context, false);
                        } else if (selectedWarehouse == null) {
                          _showSnackBar('Select a warehouse', context, false);
                        } else if (selectedBranch == null) {
                          _showSnackBar('Select a branch', context, false);
                        } else {
                          _onUpdateOrderStatus(context);
                        }
                      },
                      fullWidth: true,
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ],
                ],
              ),
      ),
    );
  }
}

Widget _focusDropdown({
  required BuildContext context,
  required String hint,
  required List<Map<String, dynamic>> items,
  required String? value,
  required bool isLoading,
  required ValueChanged<String?> onChanged,
}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.outline),
      borderRadius: BorderRadius.circular(8),
      color: AppColors.surfaceContainerHigh,
    ),
    child: isLoading
        ? Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        : DropdownButton<String>(
            hint: Text(
              hint,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map<DropdownMenuItem<String>>((item) {
              return DropdownMenuItem<String>(
                value: item['iMasterId'].toString(),
                child: Text(
                  item['sName'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
  );
}
