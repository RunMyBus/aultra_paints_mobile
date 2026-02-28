import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../services/WidgetScreens/TransferPointsDialog.dart';
import '../../services/config.dart';
import '../../utility/Colors.dart';
import '../../utility/Fonts.dart';
import '../../utility/size_config.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';

class LayoutPage extends StatefulWidget {
  final Widget child;

  const LayoutPage({Key? key, required this.child}) : super(key: key);

  @override
  _LayoutPageState createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late String USER_ID = '';
  late String USER_FULL_NAME = '';
  late String USER_MOBILE_NUMBER = '';
  late String USER_ACCOUNT_TYPE = '';
  late String accesstoken = '';

  @override
  void initState() {
    super.initState();
    fetchLocalStorageData();
  }

  Future<void> fetchLocalStorageData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Wait for auth to be initialized if needed
    if (!authProvider.isInitialized) {
      await authProvider.initialize();
    }

    setState(() {
      USER_ID = authProvider.userId ?? '';
      USER_FULL_NAME = authProvider.userFullName ?? '';
      USER_MOBILE_NUMBER = authProvider.userMobileNumber ?? '';
      USER_ACCOUNT_TYPE = authProvider.userAccountType ?? '';
      accesstoken = authProvider.accessToken ?? '';
    });

    // Initialize cart with user ID
    await cartProvider.setUserId(USER_ID);

    // Only call getDashboardCounts if we have a valid user
    if (USER_ID.isNotEmpty) {
      getDashboardCounts();
    }
  }

  Future<void> getDashboardCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_DETAILS + USER_ID;

    response = await http.get(
      Uri.parse(apiUrl),
      headers: authProvider.authHeaders,
    );

    if (response.statusCode == 200) {
      // Handle successful response
      // TODO: Implement dashboard data handling
    } else if (response.statusCode == 401) {
      // Handle unauthorized
      await authProvider.clearAuth();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/launchPage',
        // '/loginPage',
        (route) => false,
      );
    }
  }

  Future<void> logOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    // Save current cart state before clearing auth
    await cartProvider.saveCart();

    // Clear auth which will trigger cart to be saved with user ID
    await authProvider.clearAuth();

    // Set cart user ID to null to handle cart state properly
    await cartProvider.setUserId(null);

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/launchPage',
      // '/loginPage',
      (route) => false,
    );
  }

  Future<void> showAccountDeletionDialog(BuildContext context) async {
    // Account deletion dialog implementation
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double appBarHeight = screenHeight * 0.09;

    SizeConfig().init(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: white,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFFFF7AD),
                Color(0xFFFFA9F9),
              ],
            ),
          ),
          padding: EdgeInsets.only(
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              top: screenHeight * 0.02),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: Container(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.bars,
                        size: screenHeight * 0.028,
                        color: appThemeColor,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/app_file_icon.png',
                      height: getScreenWidth(50),
                    ),
                    Image.asset(
                      'assets/images/app_name.png',
                      height: getScreenWidth(30),
                    ),
                  ],
                ),
              ),
              // Stack(
              //   children: [
              //     if (USER_ACCOUNT_TYPE == 'Dealer')
              //       IconButton(
              //         icon: Icon(
              //           Icons.shopping_cart,
              //           color: appThemeColor,
              //           size: screenHeight * 0.028,
              //         ),
              //         onPressed: () {
              //           Navigator.pushNamed(context, '/cart');
              //         },
              //       ),
              //     if (USER_ACCOUNT_TYPE == 'Dealer')
              //       Consumer<CartProvider>(
              //         builder: (context, cart, child) {
              //           return Positioned(
              //             right: 0,
              //             child: cart.items.isEmpty
              //                 ? Container(
              //                     width: 20,
              //                     height: 20,
              //                   )
              //                 : Container(
              //                     padding: EdgeInsets.all(2),
              //                     decoration: BoxDecoration(
              //                       color: Colors.red,
              //                       borderRadius: BorderRadius.circular(10),
              //                     ),
              //                     constraints: BoxConstraints(
              //                       minWidth: 20,
              //                       minHeight: 20,
              //                     ),
              //                     child: Text(
              //                       '${cart.items.length}',
              //                       style: TextStyle(
              //                         color: Colors.white,
              //                         fontSize: 12,
              //                       ),
              //                       textAlign: TextAlign.center,
              //                     ),
              //                   ),
              //           );
              //         },
              //       ),
              //   ],
              // ),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/qrScanner').then((result) {
                    if (result == true) {
                      getDashboardCounts();
                      setState(() {});
                    }
                  });
                },
                child: Container(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Center(
                      child: Icon(
                        FontAwesomeIcons.qrcode,
                        size: screenHeight * 0.028,
                        color: appThemeColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.child,
      drawer: MyDrawer(
        onLogout: () => logOut(context),
        onAccountDelete: () => showAccountDeletionDialog(context),
      ),
    );
  }
}

class MyDrawer extends StatelessWidget {
  final Function onLogout;
  final Function onAccountDelete;

  const MyDrawer({
    Key? key,
    required this.onLogout,
    required this.onAccountDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final authProvider = Provider.of<AuthProvider>(context);

    // Get user data from auth provider
    final accountName = authProvider.userFullName ?? '';
    final accountMobile = authProvider.userMobileNumber ?? '';
    final accountType = authProvider.userAccountType ?? '';
    final parentDealerName = authProvider.userParentDealerName ?? '';

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF7AD),
              Color(0xFFFFA9F9),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              height: screenHeight * 0.25,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.05),
                  Text(
                    accountName,
                    style: TextStyle(
                      color: const Color(0xFF3533CD),
                      fontFamily: ffGMedium,
                      fontSize: screenHeight * 0.025,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    accountMobile,
                    style: TextStyle(
                      color: accountType == 'Painter'
                          ? const Color(0xFF3498db)
                          : accountType == 'Dealer'
                              ? const Color(0xFF2ecc71)
                              : accountType == 'Contractor'
                                  ? const Color(0xFFe67e22)
                                  : accountType == 'SuperUser'
                                      ? const Color(0xFFe74c3c)
                                      : const Color(0xFF3533CD),
                      fontFamily: ffGMedium,
                      fontSize: screenHeight * 0.020,
                    ),
                  ),
                  if (accountType == 'Painter' && parentDealerName.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.01),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('My Dealer ',
                              style: TextStyle(
                                color: const Color(0xFF3533CD),
                                fontFamily: ffGMedium,
                                fontSize: screenHeight * 0.016,
                              )),
                          Text(parentDealerName,
                              style: TextStyle(
                                color: const Color(0xFF3533CD),
                                fontFamily: ffGMedium,
                                fontSize: screenHeight * 0.016,
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Divider(thickness: 1),

            // **Scrollable Menu Section**
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      title: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.05),
                        child: Text(
                          'Home',
                          style: TextStyle(
                            color: const Color(0xFF3533CD),
                            fontFamily: ffGSemiBold,
                            fontSize: screenHeight * 0.022,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/dashboardPage');
                      },
                    ),
                    if (accountType == 'Dealer' ||
                        accountType == 'SalesExecutive')
                      ListTile(
                        title: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.05),
                          child: Text(
                            'My Partners',
                            style: TextStyle(
                              color: const Color(0xFF3533CD),
                              fontFamily: ffGSemiBold,
                              fontSize: screenHeight * 0.022,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/painters');
                        },
                      ),
                    if (accountType == 'Painter' || accountType == 'Dealer')
                      ListTile(
                        title: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.05),
                          child: Text(
                            'Transfer Points',
                            style: TextStyle(
                              color: const Color(0xFF3533CD),
                              fontFamily: ffGSemiBold,
                              fontSize: screenHeight * 0.022,
                            ),
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return TransferPointsDialog(
                                accountId: authProvider.userId ?? '',
                                accountName: accountName,
                                onTransferComplete: () async {
                                  showSuccessPopup(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ListTile(
                      title: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.05),
                        child: Text(
                          'Points Ledger',
                          style: TextStyle(
                            color: const Color(0xFF3533CD),
                            fontFamily: ffGSemiBold,
                            fontSize: screenHeight * 0.022,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/pointsLedgerPage');
                      },
                    ),
                    if (accountType == 'Dealer' ||  accountType == 'SalesExecutive')
                      ListTile(
                        title: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.05),
                          child: Text(
                            'Products',
                            style: TextStyle(
                              color: const Color(0xFF3533CD),
                              fontFamily: ffGSemiBold,
                              fontSize: screenHeight * 0.022,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                              context, '/ProductsCatalogScreen');
                        },
                      ),
                    if (accountType == 'Dealer' ||
                        accountType == 'SalesExecutive')
                      ListTile(
                        title: Padding(
                          padding: EdgeInsets.only(left: screenWidth * 0.05),
                          child: Text(
                            'My Orders',
                            style: TextStyle(
                              color: const Color(0xFF3533CD),
                              fontFamily: ffGSemiBold,
                              fontSize: screenHeight * 0.022,
                            ),
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/myOrdersPage');
                        },
                      ),
                  ],
                ),
              ),
            ),

            // **Fixed Bottom Buttons**
            Column(
              children: [
                Divider(thickness: 1),
                InkWell(
                  onTap: () {
                    onAccountDelete();
                  },
                  child: ListTile(
                    title: Center(
                      child: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: const Color(0xFF3533CD),
                          fontFamily: ffGMedium,
                          fontSize: screenHeight * 0.022,
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(thickness: 1),
                InkWell(
                  onTap: () {
                    onLogout();
                  },
                  child: ListTile(
                    title: Center(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: const Color(0xFF3533CD),
                          fontFamily: ffGMedium,
                          fontSize: screenHeight * 0.022,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: getScreenHeight(40)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showSuccessPopup(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/dashboardPage');
            return true;
          },
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Container(
              padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.05,
                  horizontal: screenWidth * 0.05),
              width: screenWidth * 0.6,
              height: screenHeight * 0.28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFF7AD),
                    Color(0xFFFFA9F9),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_outlined,
                    color: Colors.green,
                    size: screenHeight * 0.08,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  Text(
                    "Success",
                    style: TextStyle(
                      fontSize: screenHeight * 0.04,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF3533CD),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      Navigator.pushNamed(context, '/dashboardPage');
    });
  }
}
