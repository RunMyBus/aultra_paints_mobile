import 'package:aultra_paints_mobile/utility/Colors.dart';
import 'package:aultra_paints_mobile/utility/Fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../providers/cart_provider.dart';
import '../../services/error_handling.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../providers/auth_provider.dart';
import '../../services/error_handling.dart';
import '../../utility/Utils.dart';
import '../../services/config.dart';
import '../../utility/size_config.dart';

import '../ProductDetailsScreen.dart';
import '../cart/CartScreen.dart';

class ProductsCatalogScreen extends StatefulWidget {
  @override
  _ProductsCatalogScreenState createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  var accesstoken;
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  double? _currentPage;
  final Color primaryColor = Color(0xFF6A1B9A); // Deep Purple
  final Color secondaryColor = Color(0xFFE91E63); // Pink
  final Color accentColor = Color(0xFFFFC107); // Amber

  // Font families
  static const String medium = 'Roboto';
  static const String bold = 'Roboto';

  bool isLoading = false;
  int currentPage = 1;
  List<dynamic> catalogOffers = [];
  bool catalogHasMore = true;

  var USER_ID;
  var USER_FULL_NAME;
  var USER_EMAIL;
  var USER_MOBILE_NUMBER;
  var USER_ACCOUNT_TYPE;
  var USER_PARENT_DEALER_CODE;
  var userParentDealerMobile;
  var userParentDealerName;

  List<dynamic> dealers = [];
  Map<String, dynamic>? selectedDealer;
  String? selectedDealerId;
  bool dealersLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLocalStorageData();
  }

  Future<void> fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER');
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
      // getDashboardDetails();
      await getCatalogOffers();
      await getDealers();
      if (USER_ACCOUNT_TYPE == 'SalesExecutive') {
        await searchDealer('');
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // getCatalogOffers();
  }

  Future<void> getCatalogOffers() async {
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
    var apiUrl = BASE_URL + GET_CATALOG_SEARCH;

    print('-----------------------------${selectedDealerId}');

    try {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: authProvider.authHeaders,
        body: json.encode({'page': currentPage, 'limit': 100, 'dealerId': selectedDealerId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('catalog responseData====>${responseData}  ');
        setState(() {
          // Ensure each offer has a valid ID
          var data = responseData['data'] as List;
          catalogOffers = data.map((offer) {
            offer['id'] = offer['_id'];
            return offer;
          }).toList();
          if (catalogOffers.isNotEmpty) {
            catalogHasMore = true;
          } else {
            catalogHasMore = false;
          }
        });
        setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return Scaffold(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: getScreenWidth(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products Catalog',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3533CD),
                    ),
                  ),
                  if (USER_ACCOUNT_TYPE == 'Dealer' ||
                      USER_ACCOUNT_TYPE == 'SalesExecutive')
                    Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.shopping_cart,
                                color: Color(0xFF3533CD),
                              ),
                              onPressed: () {
                                var dealer = <dynamic, dynamic>{};
                                if (selectedDealerId != null) {
                                  dealer = dealers.firstWhere(
                                    (dea) => (dea['_id'] ?? dea['id']) == selectedDealerId,
                                    orElse: () => <dynamic, dynamic>{},
                                  );
                                }
                                print('=================${dealer}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CartScreen(dealer)),
                                );
                              },
                            ),
                            if (cart.itemCount > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
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
            if (USER_ACCOUNT_TYPE == 'SalesExecutive') ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: getScreenWidth(10)),
                child: Row(
                  children: [
                    if (dealersLoading)
                      CircularProgressIndicator()
                    else
                      Expanded(
                        child: Flex(
                          direction: Axis.horizontal,
                          children: [
                            Expanded(
                              child: DropdownButton<String>(
                                hint: Text('Select Dealer'),
                                value: selectedDealerId,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedDealerId = newValue;
                                    Provider.of<CartProvider>(context, listen: false).clear();
                                    getCatalogOffers();
                                  });
                                },
                                isExpanded: true,
                                items: dealers.map<DropdownMenuItem<String>>((dynamic dealer) {
                                  return DropdownMenuItem<String>(
                                    value: dealer['_id'] ?? dealer['id'],
                                    child: Container(
                                      constraints: BoxConstraints(maxWidth: screenWidth * 0.6),
                                      child: Text(
                                        dealer['name'] ?? dealer['dealerName'] ?? 'Unknown Dealer',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedDealerId = null;
                                  Provider.of<CartProvider>(context, listen: false).clear();
                                  getCatalogOffers();
                                });
                              },
                              child: Text('Reset'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: returnCatalogScroll(),
            ),
          ],
        ),
      ),
    );
  }

  returnCatalogScroll() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: getScreenWidth(10)),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 0.75,
        // More compact card
        children: List.generate(catalogOffers.length, (index) {
          return GestureDetector(
            onTap: () =>
                _showDetailsBottomSheet(context, catalogOffers[index],
                    isOffer: true),
            child: _buildCatalogCard(catalogOffers[index]),
          );
        }),
      ),
    );
  }

  List<dynamic> _getPriceList(Map<String, dynamic> data) {
    final productPrices = data['productPrices'];
    if (productPrices is List && productPrices.isNotEmpty) {
      return productPrices;
    }

    final prices = data['price'];
    if (prices is List && prices.isNotEmpty) {
      return prices;
    }

    return const [];
  }

  String _getFirstPriceValue(Map<String, dynamic> data) {
    final prices = _getPriceList(data);
    if (prices.isNotEmpty) {
      final first = prices.first;
      if (first is Map && first['price'] != null) {
        return first['price'].toString();
      }
    }

    final v = data['productPrice'];
    return v?.toString() ?? '0';
  }

  Map<String, dynamic>? _findSelectedPrice(Map<String, dynamic> data,
      String selectedProductPrice) {
    final prices = _getPriceList(data);
    for (final p in prices) {
      if (p is Map && p['price']?.toString() == selectedProductPrice) {
        return Map<String, dynamic>.from(p);
      }
    }

    if (prices.isNotEmpty && prices.first is Map) {
      return Map<String, dynamic>.from(prices.first);
    }

    return null;
  }

  Widget _buildCatalogCard(Map<String, dynamic> item) {
    final displayPrice = _getFirstPriceValue(item);
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: getScreenWidth(2), vertical: getScreenHeight(2)),
      padding: EdgeInsets.symmetric(horizontal: getScreenWidth(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(getScreenWidth(10)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(getScreenWidth(12)),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/images/app_file_icon.png',
                image: item['productOfferImageUrl'] ?? '',
                width: double.infinity,
                fit: BoxFit.contain,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/app_file_icon.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          // SizedBox(height: getScreenHeight(8)),
          Text(
            item['productOfferDescription'] ?? 'No Description',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: getScreenHeight(4)),
          Text(
            // 'Price: ₹${item['productPrice'] ?? '0'}',
            'Price: ₹$displayPrice',
            style: TextStyle(
              fontSize: getScreenWidth(12),
              color: Colors.grey[700],
            ),
          ),
          // SizedBox(height: getScreenHeight(8)),
          if (USER_ACCOUNT_TYPE == 'Dealer')
            SizedBox(height: getScreenHeight(8)),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return ElevatedButton.icon(
                onPressed: () {
                  _showDetailsBottomSheet(context, item, isOffer: true);
                },
                icon: Icon(Icons.shopping_cart),
                label: Text('Add to Cart'),
              );
            },
          ),

          // Consumer<CartProvider>(
          //   builder: (context, cart, child) {
          //     int quantity = cart.getQuantity(item['id'] ?? '');
          //     return Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         IconButton(
          //           icon: Icon(Icons.remove),
          //           onPressed: quantity > 0
          //               ? () => cart.decrementQuantity(item['id'] ?? '')
          //               : null,
          //         ),
          //         Text(
          //           '$quantity',
          //           style: TextStyle(
          //               fontSize: getScreenWidth(16),
          //               fontWeight: FontWeight.bold),
          //         ),
          //         IconButton(
          //           icon: Icon(Icons.add),
          //           onPressed: () {
          //             if (quantity == 0) {
          //               cart.addItem(
          //                 item['id'] ?? '',
          //                 item['productOfferDescription'] ?? '',
          //                 double.parse(
          //                     item['productPrice']?.toString() ?? '0'),
          //                 item['productOfferImageUrl'] ?? '',
          //               );
          //             } else {
          //               cart.incrementQuantity(item['id'] ?? '');
          //             }
          //           },
          //         ),
          //       ],
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context, Map<String, dynamic> data,
      {bool isOffer = true}) {
    final imageUrl =
    isOffer ? data['productOfferImageUrl'] : data['rewardSchemeImageUrl'];
    final description = isOffer
        ? data['productOfferDescription']
        : data['rewardSchemeDescription'];

    String selectedProductPrice = _getFirstPriceValue(data);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom,
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
                                maxHeight:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.6,
                                minHeight:
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.3,
                              ),
                              width: double.infinity,
                              margin:
                              EdgeInsets.only(bottom: getScreenHeight(16)),
                              child: ClipRRect(
                                borderRadius:
                                BorderRadius.circular(getScreenWidth(12)),
                                child: FadeInImage.assetNetwork(
                                  placeholder:
                                  'assets/images/app_file_icon.png',
                                  image: imageUrl ?? '',
                                  width: double.infinity,
                                  height:
                                  MediaQuery
                                      .of(context)
                                      .size
                                      .height * 0.4,
                                  fit: BoxFit.contain,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height:
                                      MediaQuery
                                          .of(context)
                                          .size
                                          .height *
                                          0.4,
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
                                margin: EdgeInsets.only(
                                    bottom: getScreenHeight(16)),
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
                            if (USER_ACCOUNT_TYPE == 'Dealer' ||
                                USER_ACCOUNT_TYPE == 'SalesExecutive') ...[
                              Container(
                                width: double.infinity,
                                height: getScreenHeight(30),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: data['productPrices']?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final price = data['productPrices'][index];
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedProductPrice =
                                              price['price'].toString();
                                        });
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: getScreenWidth(4),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: getScreenWidth(8),
                                          vertical: getScreenHeight(4),
                                        ),
                                        decoration: BoxDecoration(
                                          color: selectedProductPrice ==
                                              price['price'].toString()
                                              ? const Color(0xFF7A0180)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            getScreenWidth(8),
                                          ),
                                        ),
                                        child: Text(
                                          '${price['volume'] ??
                                              '0'}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: getScreenWidth(14),
                                            color: selectedProductPrice ==
                                                price['price'].toString()
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(
                                  top: getScreenHeight(20),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: getScreenWidth(8),
                                        vertical: getScreenHeight(4),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                            getScreenWidth(8)),
                                      ),
                                      child: Text(
                                        'Price: ₹${selectedProductPrice}',
                                        style: TextStyle(
                                          fontSize: getScreenWidth(14),
                                          fontFamily: bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                    Consumer<CartProvider>(
                                      builder: (ctx, cart, child) {
                                        final price =
                                            _findSelectedPrice(data,
                                                selectedProductPrice) ??
                                                {
                                                  'volume': 'NA',
                                                  'price': selectedProductPrice,
                                                };
                                        final cartKey =
                                            '${data['id']}_${price['volume']}';
                                        int quantity =
                                        cart.getQuantity(cartKey);
                                        return Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.remove),
                                              onPressed: () {
                                                if (quantity > 0) {
                                                  cart.decrementQuantity(
                                                      cartKey);
                                                }
                                              },
                                              style: IconButton.styleFrom(
                                                backgroundColor: quantity > 0
                                                    ? primaryColor
                                                    .withOpacity(0.1)
                                                    : Colors.grey
                                                    .withOpacity(0.1),
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
                                                if (quantity <
                                                    CartProvider.maxQuantity) {
                                                  if (quantity == 0) {
                                                    cart.addItem(
                                                      cartKey,
                                                      data['productOfferDescription'] ??
                                                          '',
                                                      double.parse(
                                                          price['price']
                                                              .toString()),
                                                      data['productOfferImageUrl'] ??
                                                          '',
                                                    );
                                                  } else {
                                                    cart.incrementQuantity(
                                                        cartKey);
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
                                                backgroundColor: quantity <
                                                    CartProvider.maxQuantity
                                                    ? primaryColor
                                                    .withOpacity(0.1)
                                                    : Colors.grey
                                                    .withOpacity(0.1),
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              )
                            ],
                            SizedBox(height: getScreenHeight(40)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }, // end builder
        ); // end StatefulBuilder
      }, // end showModalBottomSheet builder
    );
  }

  Future<void> getDealers() async {
    if (dealersLoading) return;
    setState(() => dealersLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      setState(() => dealersLoading = false);
      return;
    }

    Utils.clearToasts(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_DEALERS;

    try {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: authProvider.authHeaders,
        body: json.encode({'searchQuery': ''}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('productOffers ------ responseData====>${responseData}');
        setState(() {
          dealers = responseData['data'] ?? [];
          if (kDebugMode) {
            print("====================${dealers}");
          }
        });
        setState(() => dealersLoading = false);
      } else if (response.statusCode == 401) {
        setState(() => dealersLoading = false);
        await authProvider.clearAuth();
        Navigator.of(context).pushReplacementNamed('/login');
      } else {
        setState(() => dealersLoading = false);
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
      setState(() => dealersLoading = false);
      error_handling.errorValidation(context, 500,
          'An error occurred while fetching dealers', false);
    }
  }

  Future<void> searchDealer(String query) async {
    // Utils.clearToasts(context);
    // Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_DEALERS;
    if (query.isEmpty) {
      selectedDealer = null;
      return;
    }

    response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": accesstoken
      },
      body: json.encode({'searchQuery': query}),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200) {
      // Navigator.pop(context);
      setState(() {
        dealers = responseData['data'];
      });
      // setState(() => isLoading = false);
      // return true;
    } else {
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }

    // if (response.statusCode == 200) {
    //   setState(() {
    //     dealerList = json.decode(response.body)['data'];
    //   });
    // }
  }
}
