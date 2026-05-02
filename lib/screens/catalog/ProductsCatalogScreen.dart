import 'package:flutter/material.dart';

import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/error_handling.dart';
import '../../services/config.dart';
import '../../utility/Utils.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_card.dart';
import '../../widgets/primitives/app_badge.dart';

import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../services/secure_token_store.dart';

import '../cart/CartScreen.dart';

class ProductsCatalogScreen extends StatefulWidget {
  @override
  _ProductsCatalogScreenState createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  var accesstoken;
  final ScrollController _scrollController = ScrollController();

  bool isLoading = false;
  List<dynamic> catalogOffers = [];

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

  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _dealerSearchController =
      TextEditingController();
  String _productSearchQuery = '';
  String _dealerSearchQuery = '';

  List<dynamic> get _filteredOffers {
    if (_productSearchQuery.isEmpty) return catalogOffers;
    final q = _productSearchQuery.toLowerCase();
    return catalogOffers.where((p) {
      final desc =
          (p['productOfferDescription'] ?? '').toString().toLowerCase();
      return desc.contains(q);
    }).toList();
  }

  List<dynamic> get _filteredDealers {
    if (_dealerSearchQuery.isEmpty) return dealers;
    final q = _dealerSearchQuery.toLowerCase();
    return dealers.where((d) {
      final name = (d['name'] ?? d['dealerName'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    fetchLocalStorageData();
  }

  @override
  void dispose() {
    _productSearchController.dispose();
    _dealerSearchController.dispose();
    super.dispose();
  }

  Future<void> fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = await SecureTokenStore.instance.readToken();
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
    http.Response response;
    var apiUrl = BASE_URL + GET_CATALOG_SEARCH;

    try {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: authProvider.authHeaders,
        body: json.encode({'page': 1, 'limit': 500, 'dealerId': selectedDealerId}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          var data = responseData['data'] as List;
          catalogOffers = data.map((offer) {
            offer['id'] = offer['_id'];
            return offer;
          }).toList();
        });
        setState(() => isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Products Catalog',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (USER_ACCOUNT_TYPE == 'Dealer' ||
                    USER_ACCOUNT_TYPE == 'SalesExecutive')
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shopping_cart,
                              color: colorScheme.primary,
                            ),
                            onPressed: () {
                              var dealer = <dynamic, dynamic>{};
                              if (selectedDealerId != null) {
                                dealer = dealers.firstWhere(
                                  (dea) =>
                                      (dea['_id'] ?? dea['id']) ==
                                      selectedDealerId,
                                  orElse: () => <dynamic, dynamic>{},
                                );
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CartScreen(dealer)),
                              );
                            },
                          ),
                          if (cart.itemCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${cart.itemCount}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                        color: AppColors.onError,
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

          // ── Product search bar ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              controller: _productSearchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _productSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _productSearchController.clear();
                          setState(() => _productSearchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _productSearchQuery = v.trim()),
            ),
          ),

          // ── SalesExecutive dealer selector (searchable) ──────────────
          if (USER_ACCOUNT_TYPE == 'SalesExecutive')
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: dealersLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _dealerSearchController,
                          decoration: InputDecoration(
                            hintText: selectedDealerId != null
                                ? _dealerSearchController.text
                                : 'Search dealer by name...',
                            prefixIcon:
                                const Icon(Icons.store_outlined, size: 18),
                            suffixIcon: selectedDealerId != null ||
                                    _dealerSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _dealerSearchController.clear();
                                      setState(() {
                                        _dealerSearchQuery = '';
                                        selectedDealerId = null;
                                        Provider.of<CartProvider>(context,
                                                listen: false)
                                            .clear();
                                        getCatalogOffers();
                                      });
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (v) =>
                              setState(() => _dealerSearchQuery = v.trim()),
                        ),
                        if (_dealerSearchQuery.isNotEmpty &&
                            selectedDealerId == null)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.outline),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _filteredDealers.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Text(
                                      'No dealers found',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall!
                                          .copyWith(
                                              color: AppColors.onSurfaceVariant),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _filteredDealers.length,
                                    itemBuilder: (context, index) {
                                      final dealer = _filteredDealers[index];
                                      final name = dealer['name'] ??
                                          dealer['dealerName'] ??
                                          'Unknown Dealer';
                                      return ListTile(
                                        dense: true,
                                        title: Text(name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                        onTap: () {
                                          setState(() {
                                            selectedDealerId =
                                                dealer['_id'] ?? dealer['id'];
                                            _dealerSearchController.text = name;
                                            _dealerSearchQuery = '';
                                            Provider.of<CartProvider>(context,
                                                    listen: false)
                                                .clear();
                                            getCatalogOffers();
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                      ],
                    ),
            ),

          // ── Product list ─────────────────────────────────────────────
          Expanded(
            child: isLoading && catalogOffers.isEmpty
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _filteredOffers.isEmpty && !isLoading
                    ? Center(
                        child: Text(
                          'No products match "$_productSearchQuery"',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      )
                    : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: _filteredOffers.length,
                    itemBuilder: (context, i) {
                      final p = _filteredOffers[i] as Map<String, dynamic>;
                      final displayPrice = _getFirstPriceValue(p);
                      final priceList = _getPriceList(p);
                      final volumesLabel = priceList.isNotEmpty
                          ? priceList
                              .map((e) => e['volume']?.toString() ?? '')
                              .where((v) => v.isNotEmpty)
                              .join(' · ')
                          : null;

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppCard(
                          onTap: () => _showDetailsBottomSheet(
                              context, p,
                              isOffer: true),
                          padding:
                              const EdgeInsets.all(AppSpacing.sm),
                          child: Row(
                            children: [
                              // ── Thumbnail ──────────────────────────
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: (p['productOfferThumbnailUrl'] ?? p['productOfferImageUrl']) != null
                                      ? Image.network(
                                          p['productOfferThumbnailUrl'] ?? p['productOfferImageUrl'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                  color: AppColors.infoBg),
                                        )
                                      : Container(color: AppColors.infoBg),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              // ── Info column ────────────────────────
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      p['productOfferDescription'] ??
                                          'No Description',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    if (volumesLabel != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        volumesLabel,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                                color: AppColors
                                                    .onSurfaceVariant),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          '₹ $displayPrice',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall!
                                              .copyWith(
                                                  color: AppColors.primary),
                                        ),
                                        const Spacer(),
                                        if (USER_ACCOUNT_TYPE == 'Dealer' ||
                                            USER_ACCOUNT_TYPE ==
                                                'SalesExecutive')
                                          AppBadge(
                                            label: 'Add to Cart',
                                            tone: AppBadgeTone.info,
                                          ),
                                      ],
                                    ),
                                  ],
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

  Map<String, dynamic>? _findSelectedPrice(
      Map<String, dynamic> data, String selectedProductPrice) {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.cancel,
                                    color: AppColors.onSurfaceVariant,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            // image
                            Container(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.6,
                                minHeight:
                                    MediaQuery.of(context).size.height * 0.3,
                              ),
                              width: double.infinity,
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.lg),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: imageUrl != null
                                    ? FadeInImage.assetNetwork(
                                        placeholder:
                                            'assets/images/app_file_icon.png',
                                        image: imageUrl,
                                        width: double.infinity,
                                        height: MediaQuery.of(context)
                                                .size
                                                .height *
                                            0.4,
                                        fit: BoxFit.contain,
                                        imageErrorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: double.infinity,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.4,
                                            color: AppColors.infoBg,
                                            child: Image.asset(
                                              'assets/images/app_file_icon.png',
                                              fit: BoxFit.contain,
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: AppColors.infoBg,
                                        child: Image.asset(
                                          'assets/images/app_file_icon.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                              ),
                            ),
                            // description
                            if (description != null)
                              AppCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Text(
                                  description,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(color: AppColors.onSurface),
                                ),
                              ),
                            if (description != null)
                              const SizedBox(height: AppSpacing.lg),
                            // volume selector + add-to-cart (Dealer / SE only)
                            if (USER_ACCOUNT_TYPE == 'Dealer' ||
                                USER_ACCOUNT_TYPE == 'SalesExecutive') ...[
                              SizedBox(
                                height: 36,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                      data['productPrices']?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final price =
                                        data['productPrices'][index];
                                    final isSelected = selectedProductPrice ==
                                        price['price'].toString();
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          selectedProductPrice =
                                              price['price'].toString();
                                        });
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.sm,
                                            vertical: AppSpacing.xs),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors
                                                  .surfaceContainerHigh,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.outline,
                                          ),
                                        ),
                                        child: Text(
                                          '${price['volume'] ?? '0'}',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                color: isSelected
                                                    ? Colors.white
                                                    : AppColors.onSurface,
                                              ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: AppSpacing.xs),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppColors.outline),
                                    ),
                                    child: Text(
                                      'Price: ₹$selectedProductPrice',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              color: AppColors.onSuccess),
                                    ),
                                  ),
                                  Consumer<CartProvider>(
                                    builder: (ctx, cart, child) {
                                      final price = _findSelectedPrice(
                                              data, selectedProductPrice) ??
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
                                            icon:
                                                const Icon(Icons.remove),
                                            onPressed: () {
                                              if (quantity > 0) {
                                                cart.decrementQuantity(
                                                    cartKey);
                                              }
                                            },
                                            style: IconButton.styleFrom(
                                              backgroundColor: quantity > 0
                                                  ? AppColors.primary
                                                      .withOpacity(0.1)
                                                  : AppColors.outline
                                                      .withOpacity(0.5),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.sm),
                                          GestureDetector(
                                            onTap: () => _showQtyDialog(
                                              context,
                                              cart,
                                              cartKey,
                                              itemName:
                                                  data['productOfferDescription'] ??
                                                      '',
                                              itemPrice: double.tryParse(
                                                      price['price']
                                                          ?.toString() ??
                                                          '0') ??
                                                  0.0,
                                              itemImageUrl:
                                                  data['productOfferThumbnailUrl'] ??
                                                      data['productOfferImageUrl'] ??
                                                      '',
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
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
                                                        fontWeight:
                                                            FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.sm),
                                          IconButton(
                                            icon: const Icon(Icons.add),
                                            onPressed: () {
                                              if (quantity <
                                                  CartProvider
                                                      .maxQuantity) {
                                                if (quantity == 0) {
                                                  cart.addItem(
                                                    cartKey,
                                                    data['productOfferDescription'] ??
                                                        '',
                                                    double.parse(price[
                                                            'price']
                                                        .toString()),
                                                    data['productOfferThumbnailUrl'] ??
                                                        data['productOfferImageUrl'] ??
                                                        '',
                                                  );
                                                } else {
                                                  cart.incrementQuantity(
                                                      cartKey);
                                                }
                                              } else {
                                                ScaffoldMessenger.of(
                                                        context)
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
                                                      CartProvider
                                                          .maxQuantity
                                                  ? AppColors.primary
                                                      .withOpacity(0.1)
                                                  : AppColors.outline
                                                      .withOpacity(0.5),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xxl),
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
      },
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
        setState(() {
          dealers = responseData['data'] ?? [];
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
      setState(() {
        dealers = responseData['data'];
      });
    } else {
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }
  }
}
