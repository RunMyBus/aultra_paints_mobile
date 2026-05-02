import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/WidgetScreens/TransferPointsDialog.dart';
import '../../services/config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_app_bar.dart';
import '../../widgets/primitives/app_badge.dart';
import '../../widgets/primitives/app_snack.dart';

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

    await cartProvider.setUserId(USER_ID);

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
      await authProvider.clearAuth();
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/launchPage',
        (route) => false,
      );
    }
  }

  Future<void> logOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    await cartProvider.saveCart();
    await authProvider.clearAuth();
    await cartProvider.setUserId(null);

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/launchPage',
      (route) => false,
    );
  }

  Future<void> showAccountDeletionDialog(BuildContext context) async {
    // Account deletion dialog implementation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      appBar: AppAppBar(
        title: 'Aultra Paints',
        leading: AppAppBarAction(
          icon: Icons.menu,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        trailing: AppAppBarAction(
          icon: Icons.qr_code_scanner_outlined,
          onPressed: () {
            Navigator.pushNamed(context, '/qrScanner').then((result) {
              if (result == true) {
                getDashboardCounts();
                setState(() {});
              }
            });
          },
        ),
      ),
      body: widget.child,
      drawer: _AppDrawer(
        onLogout: () => logOut(context),
        onAccountDelete: () => showAccountDeletionDialog(context),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onLogout, required this.onAccountDelete});

  final VoidCallback onLogout;
  final VoidCallback onAccountDelete;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final accountName = authProvider.userFullName ?? '';
    final accountMobile = authProvider.userMobileNumber ?? '';
    final accountType = authProvider.userAccountType ?? '';
    final tt = Theme.of(context).textTheme;

    return Drawer(
      backgroundColor: AppColors.surfaceContainerHigh,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient profile header
            Container(
              decoration: const BoxDecoration(gradient: AppGradients.signatureCompact),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 21,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      accountName.isNotEmpty ? accountName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    accountName.isEmpty ? '—' : accountName,
                    style: tt.titleSmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    accountMobile,
                    style: tt.bodySmall!.copyWith(color: Colors.white.withOpacity(0.85)),
                  ),
                  const SizedBox(height: 4),
                  AppBadge(
                    label: accountType.isEmpty ? 'User' : accountType,
                    tone: AppBadgeTone.info,
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionHeader(context, 'Quick Actions'),
                  _drawerItem(
                    context,
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/dashboardPage');
                    },
                  ),
                  if (accountType == 'Dealer' || accountType == 'SalesExecutive')
                    _drawerItem(
                      context,
                      icon: Icons.groups_outlined,
                      label: 'My Partners',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/painters');
                      },
                    ),
                  if (accountType == 'Painter' || accountType == 'Dealer')
                    _drawerItem(
                      context,
                      icon: Icons.swap_horiz_outlined,
                      label: 'Transfer Points',
                      onTap: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => TransferPointsDialog(
                            accountId: authProvider.userId ?? '',
                            accountName: accountName,
                            onTransferComplete: () async {
                              if (context.mounted) {
                                AppSnack.show(
                                  context,
                                  'Transfer successful',
                                  tone: AppSnackTone.success,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  _drawerItem(
                    context,
                    icon: Icons.stacked_line_chart_outlined,
                    label: 'Points Ledger',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/pointsLedgerPage');
                    },
                  ),
                  if (accountType == 'Dealer' || accountType == 'SalesExecutive')
                    _drawerItem(
                      context,
                      icon: Icons.receipt_long_outlined,
                      label: 'My Orders',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/myOrdersPage');
                      },
                    ),
                  const Divider(height: 16, indent: 16, endIndent: 16, color: AppColors.outline),
                  if (accountType == 'Dealer' || accountType == 'SalesExecutive') ...[
                    _sectionHeader(context, 'Browse'),
                    _drawerItem(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Products',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/ProductsCatalogScreen');
                      },
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.shopping_cart_outlined,
                      label: 'Cart',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/cart');
                      },
                    ),
                    const Divider(height: 16, indent: 16, endIndent: 16, color: AppColors.outline),
                  ],
                ],
              ),
            ),
            // Bottom actions
            _drawerItem(
              context,
              icon: Icons.delete_outline,
              label: 'Delete Account',
              destructive: false,
              muted: true,
              onTap: onAccountDelete,
            ),
            _drawerItem(
              context,
              icon: Icons.logout_outlined,
              label: 'Log out',
              destructive: true,
              onTap: onLogout,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
    bool muted = false,
  }) {
    final fg = destructive
        ? AppColors.onError
        : muted
            ? AppColors.onSurfaceVariant
            : AppColors.onSurface;
    final iconBg = destructive
        ? AppColors.errorBg
        : muted
            ? AppColors.outline
            : AppColors.infoBg;
    final iconFg = destructive
        ? AppColors.onError
        : muted
            ? AppColors.onSurfaceVariant
            : AppColors.primary;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18),
      leading: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, size: 14, color: iconFg),
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: fg,
              fontWeight: FontWeight.w500,
            ),
      ),
      onTap: onTap,
    );
  }
}
