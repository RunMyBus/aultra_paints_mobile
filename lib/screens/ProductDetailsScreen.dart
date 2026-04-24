import 'package:flutter/material.dart';

import '../utility/Utils.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/primitives/app_card.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> productOffer;

  ProductDetailScreen({required this.productOffer});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  void onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pushNamed(context, '/dashboardPage', arguments: {});
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.productOffer;
    final imageUrl = offer['productOfferImageUrl'];
    final title = offer['productOfferTitle'] ?? '';
    final description = offer['productOfferDescription'];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ── Back button ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context, true),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        child: Icon(
                          Icons.keyboard_double_arrow_left_sharp,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  children: [
                    // 1. Image area
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.infoBg),
                              )
                            : Container(color: AppColors.infoBg),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Title card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Description card (if present)
                    if (description != null && description.isNotEmpty) ...[
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
