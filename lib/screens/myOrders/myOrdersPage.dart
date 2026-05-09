import 'dart:convert';

import 'package:aultra_paints_mobile/screens/myOrders/OrderDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/config.dart';
import '../../services/secure_token_store.dart';
import '../../services/error_handling.dart';
import '../../utility/Utils.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_badge.dart';
import '../../widgets/primitives/app_empty_state.dart';
import '../../widgets/primitives/app_list_row.dart';

const _kStatusOptions = ['PENDING', 'VERIFIED', 'REJECTED', 'DISPATCHED', 'IN-PARCEL'];
const _kPageSize = 20;

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

class _MyOrdersPageState extends State<MyOrdersPage> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String? accesstoken;
  String accountType = '';

  List<dynamic> myOrdersList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  String? statusFilter;
  String? dealerCodeFilter;
  List<Map<String, dynamic>> dealers = [];
  String? dealersError;

  int _fetchGeneration = 0;
  int _loadersOnStack = 0;

  final ScrollController _scrollController = ScrollController();

  bool get _showFilters =>
      accountType == 'SuperUser' || accountType == 'SalesExecutive';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    accesstoken = await SecureTokenStore.instance.readToken();
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    accountType = auth.userAccountType ?? '';
    if (_showFilters) {
      _loadDealers();
    }
    await _fetchPage();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      _fetchPage();
    }
  }

  @override
  void dispose() {
    _loadersOnStack = 0;
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetAndReload();
    }
  }

  Future<void> _loadDealers() async {
    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_ORDER_DEALERS),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['dealers'] as List?) ?? [];
        if (mounted) {
          setState(() {
            dealers = list.cast<Map<String, dynamic>>();
            dealersError = null;
          });
        }
      } else {
        if (mounted) setState(() => dealersError = 'Could not load dealers');
      }
    } catch (_) {
      if (mounted) setState(() => dealersError = 'Could not load dealers');
    }
  }

  Future<void> _resetAndReload() async {
    if (!mounted) return;
    // Pop any in-flight loader the stale fetch pushed; that fetch will discard
    // its response on the generation check and won't try to pop again.
    while (_loadersOnStack > 0 && mounted) {
      Navigator.pop(context);
      _loadersOnStack--;
    }
    setState(() {
      myOrdersList.clear();
      currentPage = 1;
      hasMore = true;
      isLoading = false; // abandon any in-flight fetch's local state guard
    });
    _fetchGeneration++;
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    if (isLoading || accesstoken == null || !hasMore) return;
    final myGen = _fetchGeneration;
    setState(() => isLoading = true);

    bool loaderShown = false;
    try {
      if (mounted && currentPage == 1) {
        Utils.returnScreenLoader(context);
        loaderShown = true;
        _loadersOnStack++;
      }

      final body = <String, dynamic>{
        'page': currentPage,
        'limit': _kPageSize,
      };
      if (statusFilter != null && statusFilter!.isNotEmpty) {
        body['status'] = statusFilter;
      }
      if (dealerCodeFilter != null && dealerCodeFilter!.isNotEmpty) {
        body['dealerCode'] = dealerCodeFilter;
      }

      final response = await http.post(
        Uri.parse(BASE_URL + GET_CART_ORDERS_LIST),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
        body: json.encode(body),
      );

      // Stale fetch — discard so we don't write into the post-reset state.
      if (myGen != _fetchGeneration) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['orders'] is List) {
          final List<dynamic> newData = responseData['orders'];
          if (mounted) {
            setState(() {
              myOrdersList.addAll(newData);
              currentPage++;
              hasMore = newData.length >= _kPageSize;
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
      if (myGen != _fetchGeneration) return;
      error_handling.errorValidation(
        context,
        'Failed to fetch orders',
        error.toString(),
        false,
      );
    } finally {
      if (mounted && myGen == _fetchGeneration) {
        setState(() => isLoading = false);
      }
      // Only pop the loader if THIS fetch still owns it.
      if (loaderShown && mounted && myGen == _fetchGeneration && _loadersOnStack > 0) {
        Navigator.pop(context);
        _loadersOnStack--;
      }
    }
  }

  void _onStatusChanged(String? value) {
    setState(() => statusFilter = (value == null || value.isEmpty) ? null : value);
    _resetAndReload();
  }

  void _onDealerChanged(String? code) {
    setState(() => dealerCodeFilter = (code == null || code.isEmpty) ? null : code);
    _resetAndReload();
  }

  void _clearFilters() {
    if (statusFilter == null && dealerCodeFilter == null) return;
    setState(() {
      statusFilter = null;
      dealerCodeFilter = null;
    });
    _resetAndReload();
  }

  String _labelForDealerCode(String code) {
    final match = dealers.firstWhere(
      (d) => d['dealerCode']?.toString() == code,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return code;
    return '${match['dealerCode']} — ${match['name'] ?? ''}';
  }

  Widget _buildDealerPicker() {
    // Searchable Autocomplete (pattern reused from PainterPopUpPage.dart).
    final selectedLabel = dealerCodeFilter == null
        ? ''
        : (() {
            final match = dealers.firstWhere(
              (d) => d['dealerCode']?.toString() == dealerCodeFilter,
              orElse: () => <String, dynamic>{},
            );
            if (match.isEmpty) return dealerCodeFilter!;
            return '${match['dealerCode']} — ${match['name'] ?? ''}';
          })();

    return Autocomplete<Map<String, dynamic>>(
      key: ValueKey('dealer-${dealerCodeFilter ?? "all"}'),
      initialValue: TextEditingValue(text: selectedLabel),
      displayStringForOption: (d) =>
          '${d['dealerCode']} — ${d['name'] ?? ''}',
      optionsBuilder: (TextEditingValue value) {
        final term = value.text.trim().toLowerCase();
        if (term.isEmpty) return dealers.take(20);
        return dealers.where((d) {
          final code = (d['dealerCode'] ?? '').toString().toLowerCase();
          final name = (d['name'] ?? '').toString().toLowerCase();
          return code.contains(term) || name.contains(term);
        }).take(20);
      },
      fieldViewBuilder: (ctx, controller, focus, onSubmit) {
        return TextField(
          controller: controller,
          focusNode: focus,
          decoration: InputDecoration(
            labelText: 'Dealer',
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: (controller.text.isEmpty)
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      _onDealerChanged(null);
                    },
                  ),
          ),
          onChanged: (value) {
            if (dealerCodeFilter == null) return;
            if (value == _labelForDealerCode(dealerCodeFilter!)) return;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              // Re-check after frame; user may have selected meanwhile.
              if (dealerCodeFilter != null &&
                  controller.text != _labelForDealerCode(dealerCodeFilter!)) {
                _onDealerChanged(null);
              }
            });
          },
        );
      },
      onSelected: (d) => _onDealerChanged(d['dealerCode']?.toString()),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: statusFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All')),
                    ..._kStatusOptions.map(
                      (s) => DropdownMenuItem<String?>(value: s, child: Text(s)),
                    ),
                  ],
                  onChanged: _onStatusChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildDealerPicker()),
            ],
          ),
          if (dealersError != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(dealersError!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          if (statusFilter != null || dealerCodeFilter != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear filters'),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          if (_showFilters) _buildFilterBar(),
          Expanded(
            child: myOrdersList.isEmpty && !isLoading
                ? AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No orders yet',
                    message: 'Your orders will appear here.',
                  )
                : RefreshIndicator(
                    onRefresh: () async => _resetAndReload(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(AppSpacing.md),
                      itemCount: myOrdersList.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= myOrdersList.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        final order = myOrdersList[i];
                        final orderId = order['orderId']?.toString() ?? '-';
                        final status = (order['status'] ?? 'PENDING').toString().toUpperCase();
                        final total = order['totalPrice']?.toString() ?? '-';
                        final createdAt = order['createdAt'] != null
                            ? Utils.formatDate(order['createdAt']).split(' ')[0]
                            : '-';
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppListRow(
                            title: 'Order #$orderId',
                            subtitle: '₹ $total · $createdAt',
                            trailing: AppBadge(label: status, tone: _toneForStatus(status)),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsScreen(order: order),
                                ),
                              );
                              if (result == true) _resetAndReload();
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
