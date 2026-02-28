import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/error_handling.dart';
import '../../utility/Utils.dart';
import '../../services/config.dart';
import '../../utility/size_config.dart';

class DashboardNewPage extends StatefulWidget {
  const DashboardNewPage({
    Key? key,
  }) : super(key: key);

  _DashboardNewPageState createState() => _DashboardNewPageState();
}

class _DashboardNewPageState extends State<DashboardNewPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var USER_ID;
  var USER_FULL_NAME;
  var USER_EMAIL;
  var USER_MOBILE_NUMBER;
  var USER_ACCOUNT_TYPE;
  var USER_PARENT_DEALER_CODE;
  var userParentDealerMobile;
  var userParentDealerName;

  var dashBoardList = [
    {"title": "Reward Points ", "count": '0'},
  ];

  List<dynamic> productOffers = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  ScrollController _scrollController = ScrollController();

  bool saveOtpButtonLoader = false;

  var rewardSchemes = [];

  var accountType = '';
  var parentDealerCode = '';

  final PageController _pageController = PageController();
  double? _currentPage;

  // Auto-scroll timer for product offers
  Timer? _productOffersTimer;
  final _productOffersController = PageController();
  double? _currentProductOffersPage = 0;

  final Color primaryColor = Color(0xFF6A1B9A); // Deep Purple
  final Color secondaryColor = Color(0xFFE91E63); // Pink
  final Color accentColor = Color(0xFFFFC107); // Amber

  // Font families
  static const String medium = 'Roboto';
  static const String bold = 'Roboto';

  @override
  void initState() {
    fetchLocalStorageData();
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page != null) {
        setState(() {
          _currentPage = _pageController.page;
        });
      }
    });

    // Add listener for product offers auto-scroll
    _productOffersController.addListener(() {
      if (_productOffersController.page != null) {
        setState(() {
          _currentProductOffersPage = _productOffersController.page;
        });
      }
    });

    _startProductOffersAutoScroll();
  }

  void _startProductOffersAutoScroll() {
    _productOffersTimer = Timer.periodic(Duration(seconds: 8), (timer) {
      if (productOffers.isNotEmpty && _productOffersController.hasClients) {
        final nextPage = (_currentProductOffersPage ?? 0) + 1;
        if (nextPage >= productOffers.length) {
          _productOffersController.animateToPage(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _productOffersController.animateToPage(
            nextPage.toInt(),
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _productOffersController.dispose();
    _productOffersTimer?.cancel();
    super.dispose();
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));

    // Find the Scaffold in the Widget tree and use it to show a SnackBar!
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Wait for auth to be initialized
    if (!authProvider.isInitialized) {
      await authProvider.initialize();
    }

    USER_ID = prefs.getString('USER_ID') ?? '';
    USER_FULL_NAME = prefs.getString('USER_FULL_NAME') ?? '';
    USER_EMAIL = prefs.getString('USER_EMAIL') ?? '';
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER') ?? '';
    USER_ACCOUNT_TYPE = prefs.getString('USER_ACCOUNT_TYPE') ?? '';

    if (USER_ID != null && USER_ID.isNotEmpty) {
      await Provider.of<CartProvider>(context, listen: false)
          .setUserId(USER_ID);
    }

    if (authProvider.isAuthenticated && USER_ID != null && USER_ID.isNotEmpty) {
      getDashboardDetails();
    }
  }

  Future<void> getDashboardDetails() async {
    if (USER_ID == null || USER_ID.isEmpty) {
      print('Missing user ID for dashboard details');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      print('User not authenticated');
      return;
    }

    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_DETAILS + USER_ID;

    try {
      response =
          await http.get(Uri.parse(apiUrl), headers: authProvider.authHeaders);

      if (response.statusCode == 200) {
        Navigator.pop(context);
        var tempResp = json.decode(response.body);
        var apiResp = tempResp['data'];
        dashBoardList = [
          {
            "title": "Reward Points ",
            "count": apiResp['rewardPoints'].toString()
          },
        ];

        accountType = USER_ACCOUNT_TYPE;
        parentDealerCode = apiResp['parentDealerCode'] ?? '';
        if (parentDealerCode.isEmpty && accountType == 'Painter') {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'userParentDealerName', userParentDealerName.toString());
          await prefs.setString(
              'parentDealerCode', parentDealerCode.toString());
          Navigator.pushNamed(context, '/painterPopUpPage', arguments: {})
              .then((result) {
            if (result == true) {
              getDashboardDetails();
              // getProductOffers('first');
              setState(() {});
            }
          });
          setState(() {
            dashBoardList;
            accountType;
            parentDealerCode;
          });
        } else {
          getProductOffers('first');
        }
        //  getRewardSchemes();
        _scrollController.addListener(() {
          if (_scrollController.position.pixels ==
                  _scrollController.position.maxScrollExtent &&
              !isLoading &&
              hasMore) {
            getProductOffers(''); // Load more data when scrolled to bottom
          }
        });
      } else if (response.statusCode == 401) {
        Navigator.pop(context);
        await authProvider.clearAuth();
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        Navigator.pop(context);
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
      Navigator.pop(context);
      error_handling.errorValidation(context, 500,
          'An error occurred while fetching dashboard details', false);
    }
  }

  Future getProductOffers(String hitType) async {
    if (hitType == 'first') {
      getRewardSchemes();
    }
    if (isLoading) return;
    setState(() => isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() => isLoading = false);
      return;
    }

    Utils.clearToasts(context);
    // Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_PRODUCT_OFFERS;

    try {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: authProvider.authHeaders,
        body: json.encode({'page': currentPage, 'limit': 100}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('productOffers responseData====>${responseData}');
        setState(() {
          // Ensure each offer has a valid ID
          var data = responseData['data'] as List;
          productOffers = data.map((offer) {
            offer['id'] = offer['_id'];
            return offer;
          }).toList();
        });
        setState(() => isLoading = false);
        return true;
      } else if (response.statusCode == 401) {
        // Handle unauthorized error
        setState(() => isLoading = false);
        // Clear auth and redirect to login
        await authProvider.clearAuth();
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() => isLoading = false);
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      error_handling.errorValidation(context, 500,
          'An error occurred while fetching product offers', false);
    }
  }

  Future getRewardSchemes() async {
    Utils.clearToasts(context);
    // Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_REWARDS_SCHEMES;

    try {
      response = await http.get(
        Uri.parse(apiUrl),
        headers: Provider.of<AuthProvider>(context, listen: false).authHeaders,
        // body: json.encode({'dealerCode': dealerCode}),
      );
      if (response.statusCode == 200) {
        // Navigator.pop(context);
        final responseData = json.decode(response.body);

        setState(() {
          rewardSchemes = responseData;
        });
      } else {
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
      error_handling.errorValidation(context, 500,
          'An error occurred while fetching reward schemes', false);
    }
  }

  Future<bool> _onWillPop() async {
    Utils.clearToasts(context);
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    }
    return false;
  }

  void _showDetailsBottomSheet(BuildContext context, Map<String, dynamic> data,
      {bool isOffer = true}) {
    final imageUrl =
        isOffer ? data['productOfferImageUrl'] : data['rewardSchemeImageUrl'];
    final description = isOffer
        ? data['productOfferDescription']
        : data['rewardSchemeDescription'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFFFF7AD),
                Color(0xFFFFA9F9),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: getScreenWidth(16),
                        vertical: getScreenHeight(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.grey[800],
                                size: getScreenWidth(28),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                            minHeight: MediaQuery.of(context).size.height * 0.3,
                          ),
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: getScreenHeight(16)),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(getScreenWidth(12)),
                            child: FadeInImage.assetNetwork(
                              placeholder: 'assets/images/app_file_icon.png',
                              image: imageUrl ?? '',
                              width: double.infinity,
                              height: MediaQuery.of(context).size.height * 0.4,
                              fit: BoxFit.contain,
                              imageErrorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height:
                                      MediaQuery.of(context).size.height * 0.4,
                                  color: Colors.grey[100],
                                  child: Image.asset(
                                    'assets/images/app_file_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (description != null)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(getScreenWidth(12)),
                            margin:
                                EdgeInsets.only(bottom: getScreenHeight(16)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(getScreenWidth(12)),
                            ),
                            child: Text(
                              description ?? '',
                              style: TextStyle(
                                fontSize: getScreenWidth(16),
                                color: Colors.black87,
                                height: getScreenHeight(1.5),
                                fontFamily: bold,
                              ),
                            ),
                          ),
                        if (isOffer && USER_ACCOUNT_TYPE == 'Dealer')
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: getScreenWidth(8),
                              vertical: getScreenHeight(4),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(getScreenWidth(8)),
                            ),
                            child: Text(
                              'Price: ₹${data['productPrice'] ?? '0'}',
                              style: TextStyle(
                                fontSize: getScreenWidth(14),
                                fontFamily: bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        if (isOffer && USER_ACCOUNT_TYPE == 'Dealer')
                          Consumer<CartProvider>(
                            builder: (ctx, cart, child) {
                              int quantity = cart.getQuantity(data['id'] ?? '');
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 0) {
                                        cart.decrementQuantity(
                                            data['id'] ?? '');
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: quantity > 0
                                          ? primaryColor.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  SizedBox(width: getScreenWidth(5)),
                                  Text(
                                    '$quantity',
                                    style: TextStyle(
                                      fontSize: getScreenWidth(18),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: getScreenWidth(5)),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      if (quantity < CartProvider.maxQuantity) {
                                        if (quantity == 0) {
                                          cart.addItem(
                                            data['id'] ?? '',
                                            data['productOfferDescription'] ??
                                                '',
                                            double.parse(data['productPrice']
                                                    ?.toString() ??
                                                '0'),
                                            data['productOfferImageUrl'] ?? '',
                                          );
                                        } else {
                                          cart.incrementQuantity(
                                              data['id'] ?? '');
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Maximum quantity reached'),
                                          ),
                                        );
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          quantity < CartProvider.maxQuantity
                                              ? primaryColor.withOpacity(0.1)
                                              : Colors.grey.withOpacity(0.1),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFFFFF7AD),
                Color(0xFFFFA9F9),
              ],
            ),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: getScreenWidth(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  returnNameRewards(),
                  returnProductsScroll(),
                  returnRewardsScroll(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  returnNameRewards() {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: getScreenHeight(10)),
      padding: EdgeInsets.symmetric(
        horizontal: getScreenWidth(16),
        vertical: getScreenHeight(8),
      ),
      decoration: BoxDecoration(
        color: const Color(0x33800180),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi ${USER_FULL_NAME ?? 'Guest'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: getScreenWidth(24),
                    fontFamily: bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Reward Points: ${dashBoardList[0]['count']}',
                  style: TextStyle(
                    fontSize: getScreenWidth(16),
                    fontFamily: medium,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Visibility(
            visible: USER_ACCOUNT_TYPE == 'Dealer',
            child: Consumer<CartProvider>(
              builder: (ctx, cart, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                    icon: Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: getScreenWidth(28),
                    ),
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getScreenWidth(12),
                            fontFamily: medium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  returnProductsScroll() {
    PageController _pageController = PageController(viewportFraction: 0.6);

    Timer.periodic(Duration(seconds: 6), (Timer timer) {
      if (_pageController.hasClients && productOffers.isNotEmpty) {
        int nextPage = (_pageController.page?.toInt() ?? 0) + 1;
        if (nextPage >= productOffers.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: Duration(seconds: 3),
          curve: Curves.easeInOut,
        );
      }
    });

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double unitHeightValue = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ongoing Offers',
          style: TextStyle(
            decorationThickness: 1.5,
            fontSize: unitHeightValue * 0.03,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3533CD),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(
          height: getScreenHeight(USER_ACCOUNT_TYPE == 'Dealer' ? 315 : 300),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              itemCount: productOffers.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < productOffers.length) {
                  final item = productOffers[index];
                  return GestureDetector(
                    onTap: () =>
                        _showDetailsBottomSheet(context, item, isOffer: true),
                    child: Container(
                      width: getScreenWidth(200),
                      margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.028,
                          vertical: screenHeight * 0.01),
                      padding: EdgeInsets.only(top: getScreenHeight(4)),
                      decoration: BoxDecoration(
                        // color: const Color(0x33800180),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(getScreenWidth(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: getScreenWidth(5),
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: getScreenHeight(210),
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(getScreenWidth(16))),
                              child: FadeInImage.assetNetwork(
                                placeholder: 'assets/images/app_file_icon.png',
                                image: item['productOfferImageUrl'] ?? '',
                                fit: BoxFit.cover,
                                imageErrorBuilder:
                                    (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/images/app_file_icon.png',
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: getScreenHeight(5),
                                  horizontal: getScreenWidth(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['productOfferDescription'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: getScreenWidth(12),
                                      fontFamily: medium,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(
                                    height: getScreenHeight(2),
                                  ),
                                  Visibility(
                                    visible: USER_ACCOUNT_TYPE == 'Dealer',
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: getScreenWidth(6),
                                            vertical: getScreenHeight(2),
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(
                                                getScreenWidth(6)),
                                          ),
                                          child: Text(
                                            'Price: ₹${item['productPrice'] ?? '0'}',
                                            style: TextStyle(
                                              fontSize: getScreenWidth(10),
                                              fontFamily: bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        Consumer<CartProvider>(
                                          builder: (ctx, cart, _) {
                                            final quantity = cart
                                                .getQuantity(item['id'] ?? '');
                                            return Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                SizedBox(
                                                  width: getScreenWidth(23),
                                                  height: getScreenWidth(28),
                                                  child: IconButton(
                                                    icon: Icon(Icons.remove,
                                                        size:
                                                            getScreenWidth(16)),
                                                    onPressed: quantity > 0
                                                        ? () {
                                                            cart.decrementQuantity(
                                                                item['id'] ??
                                                                    '');
                                                          }
                                                        : null,
                                                    style: IconButton.styleFrom(
                                                      backgroundColor:
                                                          quantity > 0
                                                              ? primaryColor
                                                                  .withOpacity(
                                                                      0.1)
                                                              : Colors.grey
                                                                  .withOpacity(
                                                                      0.1),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: getScreenWidth(20),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '$quantity',
                                                    style: TextStyle(
                                                      fontSize:
                                                          getScreenWidth(13),
                                                      fontFamily: medium,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: getScreenWidth(23),
                                                  height: getScreenWidth(28),
                                                  child: IconButton(
                                                    icon: Icon(Icons.add,
                                                        size:
                                                            getScreenWidth(16)),
                                                    onPressed: () {
                                                      if (quantity <
                                                          CartProvider
                                                              .maxQuantity) {
                                                        if (quantity == 0) {
                                                          cart.addItem(
                                                            item['id'] ?? '',
                                                            item['productOfferDescription'] ??
                                                                '',
                                                            double.parse(item[
                                                                        'productPrice']
                                                                    ?.toString() ??
                                                                '0'),
                                                            item['productOfferImageUrl'] ??
                                                                '',
                                                          );
                                                        } else {
                                                          cart.incrementQuantity(
                                                              item['id'] ?? '');
                                                        }
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                                'Maximum quantity reached'),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: quantity <
                                                              CartProvider
                                                                  .maxQuantity
                                                          ? primaryColor
                                                              .withOpacity(0.1)
                                                          : Colors.grey
                                                              .withOpacity(0.1),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  returnRewardsScroll() {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          // padding: EdgeInsets.symmetric(vertical: getScreenHeight(10)),
          child: Text(
            'Reward Schemes',
            style: TextStyle(
                decorationThickness: 1.5,
                fontSize: unitHeightValue * 0.03,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3533CD)),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: getScreenHeight(230),
          child: rewardSchemes.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: rewardSchemes.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final item = rewardSchemes[index];
                    double scale = 0.9;
                    if (_currentPage != null) {
                      scale = index == _currentPage!.round() ? 1.0 : 0.9;
                    }
                    final scheme = rewardSchemes[index];
                    return GestureDetector(
                      onTap: () => _showDetailsBottomSheet(context, scheme,
                          isOffer: false),
                      child: Transform.scale(
                        scale: scale,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(getScreenWidth(20)),
                              color: const Color(0x33800180),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 20,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: screenHeight * 0.28,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: FadeInImage.assetNetwork(
                                      placeholder:
                                          'assets/images/app_file_icon.png',
                                      image: item['rewardSchemeImageUrl'] ?? '',
                                      fit: BoxFit.cover,
                                      imageErrorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/app_file_icon.png',
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
