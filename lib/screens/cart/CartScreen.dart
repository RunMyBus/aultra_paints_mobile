import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/config.dart';
import '../../services/error_handling.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utility/Utils.dart';
import '../../widgets/primitives/app_app_bar.dart';
import '../../widgets/primitives/app_button.dart';
import '../../widgets/primitives/app_card.dart';
import '../../widgets/primitives/app_empty_state.dart';
import '../../widgets/primitives/app_list_row.dart';
import 'package:http/http.dart' as http;

class CartScreen extends StatefulWidget {
  final Map<dynamic, dynamic> dealer;
  final String? dealerId;

  CartScreen(this.dealer, {Key? key, this.dealerId}) : super(key: key);

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  var accesstoken;

  var USER_ID;
  var USER_FULL_NAME;
  var USER_EMAIL;
  var USER_MOBILE_NUMBER;
  var USER_ACCOUNT_TYPE;
  var USER_PARENT_DEALER_CODE;
  var userParentDealerMobile;
  var userParentDealerName;

  bool isLoading = false;
  List<Map<String, dynamic>> focusEntities = [];
  String? selectedFocusEntity;
  bool isFocusEntitiesLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchLocalStorageData();
    });
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fetchFocusEntities(context);
      });
    }
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> fetchFocusEntities(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return;
    }

    setState(() {
      isFocusEntitiesLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(BASE_URL + GET_FOCUS_ENTITIES),
        headers: authProvider.authHeaders,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            focusEntities = List<Map<String, dynamic>>.from(responseData['data']);
          });
        }
      }
    } catch (e) {
    } finally {
      setState(() {
        isFocusEntitiesLoading = false;
      });
    }
  }

  Future<void> createCheckout(
      BuildContext context, List<CartItem> cartItems, dealerId, focusEntity) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      return;
    }

    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);

    http.Response response;
    var apiUrl = BASE_URL + CREATE_CHECKOUT;

    List<Map<String, dynamic>> itemsJson = cartItems.map((item) {
      var volume;
      var actualId;
      if (item.id.contains('_')) {
        actualId = item.id.split('_')[0];
        volume = item.id.split('_')[1];
      } else {
        actualId = item.id;
        volume = "0";
      }
      return {
        "_id": actualId,
        "productOfferDescription": item.name,
        "quantity": item.quantity,
        "productPrice": item.price,
        "productOfferImageUrl": item.imageUrl,
        "volume": volume,
      };
    }).toList();

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      response = await http.post(
        Uri.parse(apiUrl),
        headers: authProvider.authHeaders,
        body: json.encode({'items': itemsJson, 'totalPrice': cartProvider.totalAmount, "dealerId": dealerId, "entityId": focusEntity}),
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          Provider.of<CartProvider>(context, listen: false).clear();

          _showSuccessDialog(context);
        }
      } else {
        error_handling.errorValidation(
            context, response.statusCode, response.body, false);
      }
    } catch (e) {
      Navigator.of(context).pop();
      error_handling.errorValidation(
          context, 500, 'An error occurred while creating checkout', false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(Duration(seconds: 4), () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacementNamed('/dashboardPage');
        });
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: AnimationController(
              vsync: Navigator.of(ctx),
              duration: Duration(milliseconds: 500),
            )..forward(),
            curve: Curves.elasticOut,
          ),
          child: AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            content: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 10.0,
                          ),
                        ],
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ])),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Order Placed',
                    style: TextStyle(
                        fontSize: 20,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your order has been placed successfully.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Extracts the volume portion from a composite product ID (format: `id_volume`).
  /// Returns an empty string if no volume suffix is present.
  String _volumeFromId(String id) {
    if (id.contains('_')) {
      return id.split('_').sublist(1).join('_');
    }
    return '';
  }

  void _onCheckoutPressed(
      BuildContext context, CartProvider cart, List<CartItem> cartItems) {
    if (USER_ACCOUNT_TYPE == 'SalesExecutive') {
      if (cart.items.isEmpty || widget.dealer['_id'] == null || selectedFocusEntity == null) {
        if (cart.items.isEmpty) {
          _showSnackBar('Cart is empty', context, false);
        }
        if (widget.dealer['_id'] == null) {
          _showSnackBar('Select dealer', context, false);
        }
        if (selectedFocusEntity == null) {
          _showSnackBar('Select Focus Entity', context, false);
        }
      } else {
        createCheckout(context, cartItems, widget.dealer['_id'], selectedFocusEntity);
      }
    } else {
      if (cart.items.isEmpty) {
        _showSnackBar('Cart is empty', context, false);
      } else {
        createCheckout(context, cartItems, widget.dealer['_id'], selectedFocusEntity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items.values.toList();
    final t = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppAppBar(
        title: 'Cart',
        leading: AppAppBarAction(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: cart.items.isEmpty
          ? AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message: 'Add products from the catalog.',
              ctaLabel: 'Browse catalog',
              onCta: () => Navigator.pushReplacementNamed(
                  context, '/ProductsCatalogScreen'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final item = cartItems[i];
                      final volume = _volumeFromId(item.id);
                      final subtitle =
                          '${volume.isNotEmpty ? '$volume · ' : ''}Qty ${item.quantity} · ₹ ${item.price.toStringAsFixed(2)}';

                      return AppListRow(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: AppColors.infoBg,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 20,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        title: item.name,
                        subtitle: subtitle,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: item.quantity > 1
                                  ? () => cart.decrementQuantity(item.id)
                                  : null,
                            ),
                            Text(
                              '${item.quantity}',
                              style: t.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              visualDensity: VisualDensity.compact,
                              onPressed: item.quantity < CartProvider.maxQuantity
                                  ? () => cart.incrementQuantity(item.id)
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Maximum quantity reached'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 18,
                                  color: colorScheme.error),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                cart.removeItem(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Item removed from cart'),
                                    duration: const Duration(seconds: 1),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () {
                                        cart.addItem(
                                          item.id,
                                          item.name,
                                          item.price,
                                          item.imageUrl,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Totals card + checkout button
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // SE dealer + focus entity section
                        if (USER_ACCOUNT_TYPE == 'SalesExecutive') ...[
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dealer: ${widget.dealer['name'] ?? ''}',
                                  style: t.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: AppColors.outline),
                                    borderRadius: BorderRadius.circular(8),
                                    color: AppColors.surfaceContainerHigh,
                                  ),
                                  child: isFocusEntitiesLoading
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: AppSpacing.md),
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                        AppColors.primary),
                                              ),
                                            ),
                                          ),
                                        )
                                      : DropdownButton<String>(
                                          hint: Text(
                                            'Select Focus Entity',
                                            style: t.bodyMedium?.copyWith(
                                                color:
                                                    AppColors.onSurfaceVariant),
                                          ),
                                          value: selectedFocusEntity,
                                          isExpanded: true,
                                          underline: const SizedBox(),
                                          items: focusEntities
                                              .map<DropdownMenuItem<String>>(
                                                  (entity) {
                                            final displayText =
                                                entity['sName'] ?? 'Unknown';
                                            final value =
                                                entity['iMasterId'].toString();
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(displayText,
                                                  style: t.bodyMedium),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedFocusEntity = newValue;
                                            });
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        // Totals card
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              _TotalsRow(
                                label: 'Items',
                                value: '${cart.itemCount}',
                                style: t.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _TotalsRow(
                                label: 'Subtotal',
                                value:
                                    '₹ ${cart.totalAmount.toStringAsFixed(2)}',
                                style: t.bodyMedium,
                              ),
                              const Divider(height: AppSpacing.lg),
                              _TotalsRow(
                                label: 'Total',
                                value:
                                    '₹ ${cart.totalAmount.toStringAsFixed(2)}',
                                style: t.titleMedium?.copyWith(
                                    color: colorScheme.primary),
                                valueStyle: t.titleMedium?.copyWith(
                                    color: colorScheme.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton.filled(
                          label: 'Checkout',
                          fullWidth: true,
                          loading: isLoading,
                          onPressed: () =>
                              _onCheckoutPressed(context, cart, cartItems),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Private helper widget for a label/value row inside the totals card.
class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.label,
    required this.value,
    this.style,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? style;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: valueStyle ?? style),
      ],
    );
  }
}
