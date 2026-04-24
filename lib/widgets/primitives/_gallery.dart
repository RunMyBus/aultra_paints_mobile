// lib/widgets/primitives/_gallery.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import 'app_app_bar.dart';
import 'app_badge.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_chip.dart';
import 'app_dialog.dart';
import 'app_empty_state.dart';
import 'app_list_row.dart';
import 'app_snack.dart';
import 'app_text_field.dart';

/// Debug-only gallery of every primitive. Route at `/_gallery`.
class PrimitivesGallery extends StatelessWidget {
  const PrimitivesGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: 'Primitives',
        leading: AppAppBarAction(icon: Icons.arrow_back, onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Buttons', [
            Row(children: [
              Expanded(child: AppButton.filled(label: 'Filled', onPressed: () {}, fullWidth: true)),
              const SizedBox(width: 8),
              Expanded(child: AppButton.outlined(label: 'Outlined', onPressed: () {}, fullWidth: true)),
            ]),
            const SizedBox(height: 8),
            AppButton.text(label: 'Text button', onPressed: () {}),
            const SizedBox(height: 8),
            AppButton.filled(label: 'Loading', onPressed: () {}, loading: true),
          ]),
          _section('Cards', [
            const AppCard(child: Text('Normal card')),
            const SizedBox(height: 8),
            const AppCard(emphasis: AppCardEmphasis.featured, child: Text('Featured card')),
            const SizedBox(height: 8),
            Container(
              decoration: const BoxDecoration(gradient: AppGradients.signature, borderRadius: BorderRadius.all(Radius.circular(14))),
              padding: const EdgeInsets.all(14),
              child: const Text('Signature gradient surface', style: TextStyle(color: Colors.white)),
            ),
          ]),
          _section('Chips', [
            Wrap(spacing: 6, children: [
              AppChip(label: 'All', selected: true, onTap: () {}),
              AppChip(label: 'Interior', selected: false, onTap: () {}),
              AppChip(label: 'Exterior', selected: false, onTap: () {}),
            ]),
          ]),
          _section('Badges', [
            Wrap(spacing: 6, children: const [
              AppBadge(label: 'Shipped', tone: AppBadgeTone.success),
              AppBadge(label: 'Pending', tone: AppBadgeTone.info),
              AppBadge(label: 'Failed', tone: AppBadgeTone.error),
              AppBadge(label: 'Draft', tone: AppBadgeTone.neutral),
            ]),
          ]),
          _section('Text field', const [
            AppTextField(label: 'Mobile', hint: '9xxxxxxxxx'),
          ]),
          _section('List row', const [
            AppListRow(
              title: 'Rajesh Kumar',
              subtitle: '+91 98765 43210',
              trailing: AppBadge(label: 'Dealer', tone: AppBadgeTone.info),
            ),
          ]),
          _section('Dialog / Snack', [
            Row(children: [
              Expanded(child: AppButton.outlined(
                label: 'Open dialog',
                onPressed: () => showAppDialog(
                  context: context,
                  title: 'Confirm',
                  body: const Text('Are you sure?'),
                  actions: [
                    AppDialogAction(label: 'Cancel', onPressed: () {}),
                    AppDialogAction(label: 'OK', onPressed: () {}, primary: true),
                  ],
                ),
                fullWidth: true,
              )),
              const SizedBox(width: 8),
              Expanded(child: AppButton.outlined(
                label: 'Show snack',
                onPressed: () => AppSnack.show(context, 'Saved', tone: AppSnackTone.success),
                fullWidth: true,
              )),
            ]),
          ]),
          _section('Empty state', [
            SizedBox(
              height: 260,
              child: AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No orders yet',
                message: 'Place your first order to see it here.',
                ctaLabel: 'Browse catalog',
                onCta: () {},
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String label, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
