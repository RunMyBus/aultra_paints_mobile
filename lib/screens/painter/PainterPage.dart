import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../services/config.dart';
import '../../services/error_handling.dart';
import '../../utility/Colors.dart';
import '../../utility/Utils.dart';

class PainterPage extends StatefulWidget {
  const PainterPage({Key? key}) : super(key: key);

  @override
  _PainterPageState createState() => _PainterPageState();
}

class _PainterPageState extends State<PainterPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String? accesstoken;
  List<dynamic> myPainterList = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollmyPainterListController = ScrollController();

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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          key: _scaffoldKey,
          body: SingleChildScrollView(
            child: Container(
                height: screenHeight,
                width: screenWidth,
                decoration: const BoxDecoration(
                  // borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFFFFF7AD),
                      Color(0xFFFFA9F9),
                    ],
                  ),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'My Partners',
                              style: TextStyle(
                                fontSize: unitHeightValue * 0.02,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3533CD),
                              ),
                            ),
                          ],
                        ),
                      ),
                      myPainterList.isEmpty
                          ? Center(
                              child: Text(
                                hasMore && isLoading
                                    ? "Loading..."
                                    : "No data available",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            )
                          : SingleChildScrollView(
                              controller: _scrollmyPainterListController,
                              child: Container(
                                // margin: const EdgeInsets.all(16.0), // Add margin around the table
                                margin: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                  vertical: screenHeight * 0.01,
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.018,
                                  vertical: screenHeight * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x33800180),
                                  borderRadius: BorderRadius.circular(
                                      12.0), // Add radius to table
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Table(
                                  columnWidths: {
                                    0: FixedColumnWidth(screenWidth * 0.3),
                                    1: FixedColumnWidth(screenWidth * 0.3),
                                    2: FixedColumnWidth(screenWidth * 0.3),
                                  },
                                  children: [
                                    // Header Row
                                    const TableRow(
                                      // decoration: BoxDecoration(
                                      //   color: Colors.blueAccent,
                                      // ),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: const Color(0xFF3533CD),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Mobile',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: const Color(0xFF3533CD),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(
                                            'Reward Points',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: const Color(0xFF3533CD),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Dynamic Rows
                                    ...myPainterList.map((painter) {
                                      return TableRow(
                                        // decoration: const BoxDecoration(
                                        //   color: Color(0x33800180),
                                        // ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              painter['name'] ?? 'NA',
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child:
                                                Text(painter['mobile'] ?? 'NA'),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                                painter['rewardPoints'] > 0
                                                    ? painter['rewardPoints']
                                                        .toString()
                                                    : '0'),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                    // Loading Indicator Row (optional)
                                    if (hasMore && isLoading)
                                      const TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator()),
                                          ),
                                          SizedBox.shrink(),
                                          SizedBox.shrink(),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    ])),
          )),
    );
  }
}
