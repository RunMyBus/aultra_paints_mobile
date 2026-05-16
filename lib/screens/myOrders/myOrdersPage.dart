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

  // Sales executive filter — mobile number; only used when accountType == 'SuperUser'
  String? salesExecutiveFilter;
  List<Map<String, dynamic>> salesExecutives = [];
  String? salesExecutivesError;

  // Inline filter panel state
  bool _filterPanelOpen = false;
  String? _draftStatus;
  String? _draftDealerCode;
  String? _draftSalesExecutive;
  bool _showDealerResults = false;
  bool _showSeResults = false;
  List<Map<String, dynamic>> _dealerResults = [];
  List<Map<String, dynamic>> _seResults = [];
  final _dealerController = TextEditingController();
  final _seController = TextEditingController();
  final _dealerFocusNode = FocusNode();
  final _seFocusNode = FocusNode();
  final _filterPanelScrollController = ScrollController();

  int _fetchGeneration = 0;
  int _loadersOnStack = 0;

  final ScrollController _scrollController = ScrollController();

  bool get _showFilters =>
      accountType == 'SuperUser' || accountType == 'SalesExecutive';

  // Shown for SuperUser (all SEs) or Senior SE (their juniors + self, loaded only when non-empty)
  bool get _showSalesExecutiveFilter =>
      accountType == 'SuperUser' || (accountType == 'SalesExecutive' && salesExecutives.isNotEmpty);

  int get _activeFilterCount =>
      (statusFilter != null ? 1 : 0) +
      (dealerCodeFilter != null ? 1 : 0) +
      (salesExecutiveFilter != null ? 1 : 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_scrollListener);
    _dealerFocusNode.addListener(_onDealerFocusChange);
    _seFocusNode.addListener(_onSeFocusChange);
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
    if (accountType == 'SuperUser') {
      _loadSalesExecutives();
    } else if (accountType == 'SalesExecutive') {
      _loadJuniorSalesExecutives(auth);
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
    _dealerController.dispose();
    _seController.dispose();
    _dealerFocusNode.dispose();
    _seFocusNode.dispose();
    _filterPanelScrollController.dispose();
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

  Future<void> _loadSalesExecutives() async {
    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_SALES_EXECUTIVES),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = (data['data'] as List?) ?? [];
        if (mounted) {
          setState(() {
            salesExecutives = list.cast<Map<String, dynamic>>();
            salesExecutivesError = null;
          });
        }
      } else {
        if (mounted) setState(() => salesExecutivesError = 'Could not load sales executives');
      }
    } catch (_) {
      if (mounted) setState(() => salesExecutivesError = 'Could not load sales executives');
    }
  }

  Future<void> _loadJuniorSalesExecutives(AuthProvider auth) async {
    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_JUNIOR_SALES_EXECUTIVES),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final juniors = ((data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
        if (juniors.isNotEmpty && mounted) {
          // Prepend self so the Senior SE can filter to only their own dealers
          final self = <String, dynamic>{
            'name': '${auth.userFullName ?? 'Me'} (Me)',
            'mobile': auth.userMobileNumber ?? '',
          };
          setState(() {
            salesExecutives = [self, ...juniors];
            salesExecutivesError = null;
          });
        }
      } else {
        if (mounted) setState(() => salesExecutivesError = 'Could not load junior sales executives');
      }
    } catch (_) {
      if (mounted) setState(() => salesExecutivesError = 'Could not load junior sales executives');
    }
  }

  Future<void> _resetAndReload() async {
    if (!mounted) return;
    while (_loadersOnStack > 0 && mounted) {
      Navigator.pop(context);
      _loadersOnStack--;
    }
    setState(() {
      myOrdersList.clear();
      currentPage = 1;
      hasMore = true;
      isLoading = false;
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
      if (salesExecutiveFilter != null && salesExecutiveFilter!.isNotEmpty) {
        body['salesExecutiveMobile'] = salesExecutiveFilter;
      }

      final response = await http.post(
        Uri.parse(BASE_URL + GET_CART_ORDERS_LIST),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
        body: json.encode(body),
      );

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
      if (loaderShown && mounted && myGen == _fetchGeneration && _loadersOnStack > 0) {
        Navigator.pop(context);
        _loadersOnStack--;
      }
    }
  }

  // Focus listeners — use addPostFrameCallback on blur so switching fields stays smooth.
  void _scrollPanelToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _filterPanelScrollController.hasClients) {
        _filterPanelScrollController.animateTo(
          _filterPanelScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onDealerFocusChange() {
    if (_dealerFocusNode.hasFocus) {
      setState(() {
        _dealerResults = _filterDealerList(_dealerController.text.trim().toLowerCase());
        _showDealerResults = true;
        _showSeResults = false;
      });
      _scrollPanelToBottom();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dealerFocusNode.hasFocus && !_seFocusNode.hasFocus) {
          setState(() => _showDealerResults = false);
        }
      });
    }
  }

  void _onSeFocusChange() {
    if (_seFocusNode.hasFocus) {
      setState(() {
        _seResults = _filterSeList(_seController.text.trim().toLowerCase());
        _showSeResults = true;
        _showDealerResults = false;
      });
      _scrollPanelToBottom();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_dealerFocusNode.hasFocus && !_seFocusNode.hasFocus) {
          setState(() => _showSeResults = false);
        }
      });
    }
  }

  List<Map<String, dynamic>> _filterDealerList(String term) {
    if (term.isEmpty) return dealers.take(20).toList();
    return dealers.where((d) {
      final code = (d['dealerCode'] ?? '').toString().toLowerCase();
      final name = (d['name'] ?? '').toString().toLowerCase();
      return code.contains(term) || name.contains(term);
    }).take(20).toList();
  }

  List<Map<String, dynamic>> _filterSeList(String term) {
    if (term.isEmpty) return salesExecutives.take(20).toList();
    return salesExecutives.where((se) {
      final name = (se['name'] ?? '').toString().toLowerCase();
      final mobile = (se['mobile'] ?? '').toString().toLowerCase();
      return name.contains(term) || mobile.contains(term);
    }).take(20).toList();
  }

  void _openFilterPanel() {
    _draftStatus = statusFilter;
    _draftDealerCode = dealerCodeFilter;
    _draftSalesExecutive = salesExecutiveFilter;
    _dealerController.text = _draftDealerCode == null ? '' : _labelForDealerCode(_draftDealerCode!);
    _seController.text = _draftSalesExecutive == null ? '' : _labelForSalesExecutiveMobile(_draftSalesExecutive!);
    _showDealerResults = false;
    _showSeResults = false;
    setState(() => _filterPanelOpen = true);
  }

  void _closeFilterPanel() {
    _dealerFocusNode.unfocus();
    _seFocusNode.unfocus();
    setState(() {
      _filterPanelOpen = false;
      _showDealerResults = false;
      _showSeResults = false;
    });
  }

  void _applyFilters() {
    statusFilter = _draftStatus;
    dealerCodeFilter = _draftDealerCode;
    salesExecutiveFilter = _draftSalesExecutive;
    _closeFilterPanel();
    _resetAndReload();
  }

  Widget _buildFilterPanel() {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;

    return TapRegion(
      onTapOutside: (_) => _closeFilterPanel(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 460),
        child: Card(
        margin: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.sm),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          controller: _filterPanelScrollController,
          // Extra bottom padding pushes Cancel/Apply above the keyboard.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md,
            AppSpacing.md + keyboardH,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(
                    onPressed: () => setState(() {
                      _draftStatus = null;
                      _draftDealerCode = null;
                      _draftSalesExecutive = null;
                      _dealerController.clear();
                      _seController.clear();
                      _showDealerResults = false;
                      _showSeResults = false;
                    }),
                    child: const Text('Clear all'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status
              DropdownButtonFormField<String?>(
                value: _draftStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All')),
                  ..._kStatusOptions.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                ],
                onChanged: (v) => setState(() => _draftStatus = v),
              ),
              const SizedBox(height: 12),

              // Dealer search
              TextField(
                controller: _dealerController,
                focusNode: _dealerFocusNode,
                decoration: InputDecoration(
                  labelText: 'Dealer',
                  hintText: 'Search by code or name',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: _dealerController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() {
                            _dealerController.clear();
                            _draftDealerCode = null;
                            _dealerResults = _filterDealerList('');
                            _showDealerResults = true;
                          }),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() {
                  _draftDealerCode = null;
                  _dealerResults = _filterDealerList(val.trim().toLowerCase());
                  _showDealerResults = true;
                }),
              ),

              // Dealer results
              if (_showDealerResults && _dealerResults.isNotEmpty)
                _buildResultsList(
                  items: _dealerResults,
                  labelFor: (d) => '${d['dealerCode']} — ${d['name'] ?? ''}',
                  onSelect: (d) {
                    _draftDealerCode = d['dealerCode']?.toString();
                    _dealerController.text = _labelForDealerCode(_draftDealerCode!);
                    _dealerFocusNode.unfocus();
                  },
                ),
              const SizedBox(height: 12),

              // Sales Executive search
              if (_showSalesExecutiveFilter) ...[
                TextField(
                  controller: _seController,
                  focusNode: _seFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Sales Executive',
                    hintText: 'Search by name or mobile',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _seController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _seController.clear();
                              _draftSalesExecutive = null;
                              _seResults = _filterSeList('');
                              _showSeResults = true;
                            }),
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() {
                    _draftSalesExecutive = null;
                    _seResults = _filterSeList(val.trim().toLowerCase());
                    _showSeResults = true;
                  }),
                ),

                // SE results
                if (_showSeResults && _seResults.isNotEmpty)
                  _buildResultsList(
                    items: _seResults,
                    labelFor: (se) => '${se['name'] ?? ''} — ${se['mobile'] ?? ''}',
                    onSelect: (se) {
                      _draftSalesExecutive = se['mobile']?.toString();
                      _seController.text = _labelForSalesExecutiveMobile(_draftSalesExecutive!);
                      _seFocusNode.unfocus();
                    },
                  ),
                const SizedBox(height: 12),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _closeFilterPanel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildResultsList({
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) labelFor,
    required void Function(Map<String, dynamic>) onSelect,
  }) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (_, i) => InkWell(
          onTap: () => setState(() => onSelect(items[i])),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Text(labelFor(items[i])),
          ),
        ),
      ),
    );
  }

  String _labelForDealerCode(String code) {
    final match = dealers.firstWhere(
      (d) => d['dealerCode']?.toString() == code,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return code;
    return '${match['dealerCode']} — ${match['name'] ?? ''}';
  }

  String _labelForSalesExecutiveMobile(String mobile) {
    final match = salesExecutives.firstWhere(
      (se) => se['mobile']?.toString() == mobile,
      orElse: () => <String, dynamic>{},
    );
    if (match.isEmpty) return mobile;
    return '${match['name'] ?? mobile} — $mobile';
  }

  Widget _buildFiltersButton() {
    final count = _activeFilterCount;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              OutlinedButton.icon(
                onPressed: _filterPanelOpen ? _closeFilterPanel : _openFilterPanel,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filters'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderListBody() {
    if (myOrdersList.isEmpty && !isLoading) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message: 'Your orders will appear here.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => _resetAndReload(),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: myOrdersList.length + (hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= myOrdersList.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          if (_showFilters) _buildFiltersButton(),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _buildOrderListBody()),
                if (_showFilters && _filterPanelOpen)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildFilterPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
