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
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_badge.dart';
import '../../widgets/primitives/app_button.dart';
import '../../widgets/primitives/app_card.dart';

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

  String closingBalance = '0';
  String creditLimit = '0';

  List<dynamic> productOffers = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  ScrollController _scrollController = ScrollController();

  bool saveOtpButtonLoader = false;

  var rewardSchemes = [];

  var accountType = '';
  var parentDealerCode = '';

  // Reward schemes PageController (focused-card scale effect)
  final PageController _pageController = PageController();
  double? _currentPage;

  // Auto-scroll timer for product offers
  Timer? _productOffersTimer;
  final _productOffersController = PageController();
  double? _currentProductOffersPage = 0;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
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
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
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
        closingBalance = (apiResp['closingBalance'] ?? '0').toString();
        creditLimit = (apiResp['creditLimit'] ?? '0').toString();

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
        _scrollController.addListener(() {
          if (_scrollController.position.pixels ==
                  _scrollController.position.maxScrollExtent &&
              !isLoading &&
              hasMore) {
            getProductOffers('');
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
        setState(() {
          var data = responseData['data'] as List;
          productOffers = data.map((offer) {
            offer['id'] = offer['_id'];
            return offer;
          }).toList();
        });
        setState(() => isLoading = false);
        return true;
      } else if (response.statusCode == 401) {
        setState(() => isLoading = false);
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
    http.Response response;
    var apiUrl = BASE_URL + GET_REWARDS_SCHEMES;

    try {
      response = await http.get(
        Uri.parse(apiUrl),
        headers: Provider.of<AuthProvider>(context, listen: false).authHeaders,
      );
      if (response.statusCode == 200) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.modal)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.modal)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Close row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined,
                                  color: AppColors.onSurfaceVariant),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        // Image
                        Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.6,
                            minHeight:
                                MediaQuery.of(context).size.height * 0.3,
                          ),
                          width: double.infinity,
                          margin:
                              const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: ClipRRect(
                            borderRadius: AppRadius.rCard,
                            child: FadeInImage.assetNetwork(
                              placeholder:
                                  'assets/images/app_file_icon.png',
                              image: imageUrl ?? '',
                              width: double.infinity,
                              height:
                                  MediaQuery.of(context).size.height * 0.4,
                              fit: BoxFit.contain,
                              imageErrorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: MediaQuery.of(context).size.height *
                                      0.4,
                                  decoration: const BoxDecoration(
                                    gradient: AppGradients.signature,
                                  ),
                                  child: Image.asset(
                                    'assets/images/app_file_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Description
                        if (description != null)
                          AppCard(
                            emphasis: AppCardEmphasis.normal,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Text(
                              description ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      color: AppColors.onSurface, height: 1.5),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.md),
                        // Price (Dealer only)
                        if (isOffer && USER_ACCOUNT_TYPE == 'Dealer')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: AppRadius.rChip,
                            ),
                            child: Text(
                              'Price: ₹${data['productPrice'] ?? '0'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(color: AppColors.onSuccess),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        // Cart controls (Dealer only)
                        if (isOffer && USER_ACCOUNT_TYPE == 'Dealer')
                          Consumer<CartProvider>(
                            builder: (ctx, cart, child) {
                              int quantity =
                                  cart.getQuantity(data['id'] ?? '');
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      if (quantity > 0) {
                                        cart.decrementQuantity(
                                            data['id'] ?? '');
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: quantity > 0
                                          ? AppColors.primary.withOpacity(0.1)
                                          : AppColors.outline,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  GestureDetector(
                                    onTap: () => _showQtyDialog(
                                      context,
                                      cart,
                                      data['id'] ?? '',
                                      itemName: data['productOfferDescription'] ?? '',
                                      itemPrice: double.tryParse(
                                              data['productPrice']?.toString() ??
                                                  '0') ??
                                          0.0,
                                      itemImageUrl:
                                          data['productOfferThumbnailUrl'] ??
                                              data['productOfferImageUrl'] ??
                                              '',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: AppColors.primary,
                                              width: 1),
                                        ),
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (quantity <
                                          CartProvider.maxQuantity) {
                                        if (quantity == 0) {
                                          cart.addItem(
                                            data['id'] ?? '',
                                            data['productOfferDescription'] ??
                                                '',
                                            double.parse(
                                                data['productPrice']
                                                        ?.toString() ??
                                                    '0'),
                                            data['productOfferThumbnailUrl'] ??
                                                data['productOfferImageUrl'] ??
                                                '',
                                          );
                                        } else {
                                          cart.incrementQuantity(
                                              data['id'] ?? '');
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Maximum quantity reached'),
                                          ),
                                        );
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: quantity <
                                              CartProvider.maxQuantity
                                          ? AppColors.primary.withOpacity(0.1)
                                          : AppColors.outline,
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        // Close button
                        AppButton.text(
                          label: 'Close',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
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
        backgroundColor: AppColors.surface,
        body: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: AppSpacing.lg),
                _buildOffersCarousel(),
                const SizedBox(height: AppSpacing.lg),
                _buildRewardSchemesCarousel(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Welcome + points compact card ────────────────────────────────────────

  Widget _buildWelcomeCard() {
    final tt = Theme.of(context).textTheme;
    final rewardPoints = dashBoardList[0]['count'] ?? '0';

    return AppCard(
      emphasis: AppCardEmphasis.featured,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left: Welcome / user / role ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK',
                      style: tt.labelSmall!.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      USER_FULL_NAME ?? 'Guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall!
                          .copyWith(color: AppColors.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (USER_ACCOUNT_TYPE != null &&
                        (USER_ACCOUNT_TYPE as String).isNotEmpty)
                      AppBadge(
                        label: USER_ACCOUNT_TYPE as String,
                        tone: AppBadgeTone.info,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Balance: ₹$closingBalance',
                      style: tt.bodySmall!
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    Text(
                      'Credit Limit: ₹$creditLimit',
                      style: tt.bodySmall!
                          .copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            // Thin vertical divider
            Container(
              width: 1,
              color: AppColors.outline,
              margin:
                  const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            ),
            // ── Right: Points + cart ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'POINTS',
                      style: tt.labelSmall!.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.8),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      rewardPoints,
                      style: tt.displaySmall!
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Cart icon (Dealer / SalesExecutive only)
                    Visibility(
                      visible: USER_ACCOUNT_TYPE == 'Dealer' ||
                          USER_ACCOUNT_TYPE == 'SalesExecutive',
                      child: Consumer<CartProvider>(
                        builder: (ctx, cart, _) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/cart');
                              },
                              icon: const Icon(
                                Icons.shopping_cart_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            if (cart.itemCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${cart.itemCount}',
                                    style: tt.labelSmall!.copyWith(
                                        color:
                                            AppColors.surfaceContainerHigh),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  // ─── Ongoing Offers carousel ───────────────────────────────────────────────

  Widget _buildOffersCarousel() {
    final tt = Theme.of(context).textTheme;
    final int offerCount = productOffers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ongoing Offers',
          style: tt.titleMedium!
              .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: USER_ACCOUNT_TYPE == 'Dealer' ? 320 : 300,
          child: PageView.builder(
            controller: _productOffersController,
            scrollDirection: Axis.horizontal,
            itemCount: offerCount,
            itemBuilder: (context, index) {
              final item = productOffers[index];
              return GestureDetector(
                onTap: () =>
                    _showDetailsBottomSheet(context, item, isOffer: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                  child: AppCard(
                    emphasis: AppCardEmphasis.featured,
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image area
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.card)),
                            child: FadeInImage.assetNetwork(
                              placeholder:
                                  'assets/images/app_file_icon.png',
                              image: item['productOfferThumbnailUrl'] ?? item['productOfferImageUrl'] ?? '',
                              fit: BoxFit.contain,
                              imageErrorBuilder:
                                  (context, error, stackTrace) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    gradient: AppGradients.signature,
                                  ),
                                  child: Image.asset(
                                    'assets/images/app_file_icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Content below image
                        Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item['productOfferDescription'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.titleSmall!.copyWith(
                                      color: AppColors.onSurface),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                // Price + cart (Dealer only)
                                Visibility(
                                  visible: USER_ACCOUNT_TYPE == 'Dealer',
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.sm,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.successBg,
                                          borderRadius: AppRadius.rChip,
                                        ),
                                        child: Text(
                                          '₹${item['productPrice'] ?? '0'}',
                                          style: tt.labelSmall!.copyWith(
                                              color: AppColors.onSuccess),
                                        ),
                                      ),
                                      Consumer<CartProvider>(
                                        builder: (ctx, cart, _) {
                                          final quantity = cart.getQuantity(
                                              item['id'] ?? '');
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _cartIconBtn(
                                                icon: Icons.remove,
                                                enabled: quantity > 0,
                                                onPressed: () => cart
                                                    .decrementQuantity(
                                                        item['id'] ?? ''),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              GestureDetector(
                                                onTap: () => _showQtyDialog(
                                                  context,
                                                  cart,
                                                  item['id'] ?? '',
                                                  itemName:
                                                      item['productOfferDescription'] ??
                                                          '',
                                                  itemPrice: double.tryParse(
                                                          item['productPrice']
                                                                  ?.toString() ??
                                                              '0') ??
                                                      0.0,
                                                  itemImageUrl:
                                                      item['productOfferThumbnailUrl'] ??
                                                          item['productOfferImageUrl'] ??
                                                          '',
                                                ),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                          color:
                                                              AppColors.primary,
                                                          width: 1),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '$quantity',
                                                    textAlign: TextAlign.center,
                                                    style: tt.labelMedium!
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: AppSpacing.sm),
                                              _cartIconBtn(
                                                icon: Icons.add,
                                                enabled: quantity <
                                                    CartProvider.maxQuantity,
                                                onPressed: () {
                                                  if (quantity == 0) {
                                                    cart.addItem(
                                                      item['id'] ?? '',
                                                      item['productOfferDescription'] ??
                                                          '',
                                                      double.parse(item[
                                                                      'productPrice']
                                                                  ?.toString() ??
                                                              '0'),
                                                      item['productOfferThumbnailUrl'] ??
                                                          item['productOfferImageUrl'] ??
                                                          '',
                                                    );
                                                  } else {
                                                    cart.incrementQuantity(
                                                        item['id'] ?? '');
                                                  }
                                                },
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
                        ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Dots indicator
        if (offerCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(offerCount, (i) {
                final active =
                    (_currentProductOffersPage ?? 0).round() == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs / 2),
                  width: active ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    borderRadius: AppRadius.rPill,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  /// Small square icon button for cart increment/decrement.
  void _showQtyDialog(
    BuildContext context,
    CartProvider cart,
    String cartKey, {
    String itemName = '',
    double itemPrice = 0.0,
    String itemImageUrl = '',
  }) {
    final current = cart.getQuantity(cartKey);
    final controller =
        TextEditingController(text: current > 0 ? '$current' : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit quantity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Quantity',
          ),
          onSubmitted: (_) => _applyQtyDialog(ctx, cart, cartKey, controller,
              itemName: itemName,
              itemPrice: itemPrice,
              itemImageUrl: itemImageUrl),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _applyQtyDialog(ctx, cart, cartKey, controller,
                itemName: itemName,
                itemPrice: itemPrice,
                itemImageUrl: itemImageUrl),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _applyQtyDialog(
    BuildContext ctx,
    CartProvider cart,
    String cartKey,
    TextEditingController controller, {
    String itemName = '',
    double itemPrice = 0.0,
    String itemImageUrl = '',
  }) {
    final val = int.tryParse(controller.text.trim());
    Navigator.pop(ctx);
    if (val == null || val < 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a valid quantity'),
          duration: Duration(seconds: 1)));
      return;
    }
    final clamped = val > CartProvider.maxQuantity ? CartProvider.maxQuantity : val;
    if (val > CartProvider.maxQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Maximum quantity is ${CartProvider.maxQuantity}'),
          duration: const Duration(seconds: 1)));
    }
    if (!cart.items.containsKey(cartKey) &&
        itemName.isNotEmpty &&
        itemImageUrl.isNotEmpty) {
      cart.addItem(cartKey, itemName, itemPrice, itemImageUrl);
    }
    cart.setQuantity(cartKey, clamped);
  }

  Widget _cartIconBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 26,
      height: 26,
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 14),
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: enabled
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.outline,
        ),
      ),
    );
  }

  // ─── Reward Schemes horizontal carousel (focused-card scale) ──────────────

  Widget _buildRewardSchemesCarousel() {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reward Schemes',
          style: tt.titleMedium!
              .copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 230,
          child: rewardSchemes.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _pageController.hasClients ? null : null,
                  itemCount: rewardSchemes.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final item = rewardSchemes[index];
                    // Focused-card scale: center card 1.0, peeks 0.9
                    double scale = 0.9;
                    if (_currentPage != null) {
                      scale =
                          index == _currentPage!.round() ? 1.0 : 0.9;
                    }
                    final isFocused = _currentPage != null &&
                        index == _currentPage!.round();
                    return GestureDetector(
                      onTap: () => _showDetailsBottomSheet(
                          context, item as Map<String, dynamic>,
                          isOffer: false),
                      child: Transform.scale(
                        scale: scale,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: AppRadius.rCard,
                              boxShadow: isFocused
                                  ? AppShadows.featured
                                  : AppShadows.card,
                            ),
                            child: ClipRRect(
                              borderRadius: AppRadius.rCard,
                              child: FadeInImage.assetNetwork(
                                placeholder:
                                    'assets/images/app_file_icon.png',
                                image: item['rewardSchemeImageUrl'] ?? '',
                                fit: BoxFit.cover,
                                width: 160,
                                height: 230,
                                imageErrorBuilder:
                                    (context, error, stackTrace) {
                                  return Container(
                                    width: 160,
                                    height: 230,
                                    decoration: const BoxDecoration(
                                      gradient: AppGradients.signature,
                                    ),
                                    child: Image.asset(
                                      'assets/images/app_file_icon.png',
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
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
