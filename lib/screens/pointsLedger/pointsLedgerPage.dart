import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../services/config.dart';
import '../../services/error_handling.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_empty_state.dart';
import '../../widgets/primitives/app_list_row.dart';
import '../../widgets/primitives/app_text_field.dart';

class PointsLedgerPage extends StatefulWidget {
  const PointsLedgerPage({Key? key}) : super(key: key);

  @override
  _PointsLedgerPageState createState() => _PointsLedgerPageState();
}

class _PointsLedgerPageState extends State<PointsLedgerPage> {
  final _dateFormat = DateFormat('yyyy-MM-dd');
  Timer? _debounce;

  String? accesstoken;
  List<dynamic> myPointLedgerList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollmyPainterListController = ScrollController();

  TextEditingController searchController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchLocalStorageData();
    _scrollmyPainterListController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollmyPainterListController.position.pixels >=
            _scrollmyPainterListController.position.maxScrollExtent - 200 &&
        !isLoading &&
        hasMore) {
      getPointsLedgerList();
    }
  }

  @override
  void dispose() {
    _scrollmyPainterListController.dispose();
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    await getPointsLedgerList();
  }

  Future<void> getPointsLedgerList() async {
    if (isLoading || accesstoken == null || !hasMore) return;

    setState(() => isLoading = true);
    try {
      final apiUrl = "$BASE_URL$GET_TRANSACTION_LEDGER";
      var query = {
        'page': currentPage,
        'limit': 10,
        "couponCode": searchController.text.isNotEmpty
            ? int.tryParse(searchController.text)
            : null,
        "date": selectedDate != null ? _dateFormat.format(selectedDate!) : null,
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
        if (responseData['transactions'] is List) {
          List<dynamic> newData = responseData['transactions'];
          if (mounted) {
            setState(() {
              myPointLedgerList.addAll(newData);
              currentPage++;
              hasMore = newData.length >= 10;
            });
          }
        }
      } else {
        error_handling.errorValidation(
          context,
          'Error fetching data',
          response.body,
          false,
        );
      }
    } catch (error) {
      error_handling.errorValidation(
        context,
        'Failed to fetch data',
        error.toString(),
        false,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        currentPage = 1;
        myPointLedgerList.clear();
        hasMore = true;
      });
      getPointsLedgerList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        myPointLedgerList.clear();
        currentPage = 1;
        hasMore = true;
      });
      getPointsLedgerList();
    }
  }

  void _resetFilters() {
    setState(() {
      searchController.clear();
      selectedDate = null;
      currentPage = 1;
      myPointLedgerList.clear();
      hasMore = true;
    });
    getPointsLedgerList();
  }

  @override
  Widget build(BuildContext context) {
    // Derive the current balance from the most-recent transaction's running
    // balance field, if available.
    final dynamic currentBalance = myPointLedgerList.isNotEmpty
        ? (myPointLedgerList.first['balance'] ?? 0)
        : 0;
    final num currentBalanceNum = currentBalance is num
        ? currentBalance
        : (num.tryParse(currentBalance.toString()) ?? 0);

    return Column(
      children: [
        // ── Gradient balance hero ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: AppGradients.signature,
              borderRadius: AppRadius.rCard,
              boxShadow: AppShadows.featured,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT BALANCE',
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currentBalanceNum pts',
                  style: Theme.of(context)
                      .textTheme
                      .displaySmall!
                      .copyWith(color: Colors.white),
                ),
                Text(
                  '≈ ₹ $currentBalanceNum redeemable',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ),

        // ── Filters row ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: '',
                  hint: 'Coupon code',
                  prefix: const Icon(Icons.search, size: 18),
                  controller: searchController,
                  keyboardType: TextInputType.number,
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Date picker button
              Material(
                color: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rInput,
                  side: const BorderSide(color: AppColors.outline),
                ),
                child: InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: AppRadius.rInput,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Reset button
              Material(
                color: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rInput,
                  side: const BorderSide(color: AppColors.outline),
                ),
                child: InkWell(
                  onTap: _resetFilters,
                  borderRadius: AppRadius.rInput,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.restart_alt_outlined,
                      size: 18,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Ledger list ───────────────────────────────────────────────────
        Expanded(
          child: myPointLedgerList.isEmpty && !isLoading
              ? const AppEmptyState(
                  icon: Icons.stacked_line_chart_outlined,
                  title: 'No transactions yet',
                  message:
                      'Earned and transferred points will show here.',
                )
              : ListView.builder(
                  controller: _scrollmyPainterListController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount:
                      myPointLedgerList.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= myPointLedgerList.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    final entry = myPointLedgerList[i];
                    final dynamic amount = entry['amount'] ?? 0;
                    final num amountNum = amount is num
                        ? amount
                        : (num.tryParse(amount.toString()) ?? 0);
                    final bool isPositive = amountNum >= 0;

                    // Format date safely
                    String formattedDate = '';
                    try {
                      formattedDate = _dateFormat.format(
                          DateTime.parse(entry['createdAt'] ?? ''));
                    } catch (_) {
                      formattedDate = entry['createdAt'] ?? '';
                    }

                    final dynamic uniqueCode = entry['uniqueCode'];
                    final String subtitleText = uniqueCode != null
                        ? '$formattedDate · $uniqueCode'
                        : formattedDate;

                    final dynamic runningBalance = entry['balance'];

                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppListRow(
                        title: (entry['narration'] ?? '—').toString(),
                        subtitle: subtitleText,
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              (isPositive ? '+' : '−') +
                                  amountNum.abs().toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: isPositive
                                        ? AppColors.onSuccess
                                        : AppColors.onError,
                                  ),
                            ),
                            if (runningBalance != null)
                              Text(
                                runningBalance.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
