import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../services/config.dart';
import '../../services/error_handling.dart';
import '../../utility/Utils.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_text_field.dart';
import '../../widgets/primitives/app_list_row.dart';
import '../../widgets/primitives/app_empty_state.dart';

class PainterPage extends StatefulWidget {
  const PainterPage({Key? key}) : super(key: key);

  @override
  _PainterPageState createState() => _PainterPageState();
}

class _PainterPageState extends State<PainterPage> {
  String? accesstoken;
  List<dynamic> myPainterList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollmyPainterListController = ScrollController();

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchLocalStorageData();
    _scrollmyPainterListController.addListener(() {
      if (_scrollmyPainterListController.position.pixels ==
              _scrollmyPainterListController.position.maxScrollExtent &&
          !isLoading &&
          hasMore) {
        getMyPainterList();
      }
    });
  }

  @override
  void dispose() {
    _scrollmyPainterListController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    await getMyPainterList(); // Load initial data
  }

  Future<void> getMyPainterList() async {
    if (isLoading || accesstoken == null) return;
    setState(() => isLoading = true);

    try {
      final apiUrl = "$BASE_URL$GET_MY_PAINTERS";
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken!,
        },
        body: json.encode({'page': currentPage, 'limit': 4}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data'] is List) {
          setState(() {
            myPainterList.addAll(responseData['data']);
            currentPage++;
            if (responseData.length < 4) hasMore = false;
          });
        }
      } else {
        error_handling.errorValidation(
            context, response.body, response.body, false);
      }
    } catch (error) {
      error_handling.errorValidation(
          context, error.toString(), error.toString(), false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      myPainterList.clear();
      currentPage = 1;
      hasMore = true;
    });
    await getMyPainterList();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query.trim().toLowerCase());
  }

  List<dynamic> get _filteredPainters {
    if (_searchQuery.isEmpty) return myPainterList;
    return myPainterList.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final mobile = (p['mobile'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || mobile.contains(_searchQuery);
    }).toList();
  }

  Future<bool> _onWillPop() async {
    Utils.clearToasts(context);
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      Navigator.of(context).pop();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final painters = _filteredPainters;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppTextField(
              label: '',
              hint: 'Search painters',
              controller: _searchController,
              prefix: const Icon(Icons.search, size: 18),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: painters.isEmpty && !isLoading
                ? const AppEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No painters yet',
                    message:
                        'Painters added under your dealership will appear here.',
                  )
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      controller: _scrollmyPainterListController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: painters.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= painters.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final p = painters[i];
                        final name = (p['name'] ?? '?') as String;
                        final initial = name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?';
                        final mobile = (p['mobile'] ?? '') as String;
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AppListRow(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.infoBg,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: AppColors.onInfo,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            title: name.isNotEmpty ? name : 'Unknown',
                            subtitle:
                                mobile.isNotEmpty ? mobile : null,
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.onSurfaceVariant,
                            ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/painterPopUpPage',
                              arguments: p,
                            ),
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
