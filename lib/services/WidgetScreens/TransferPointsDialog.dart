import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/Utils.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/primitives/app_button.dart';
import '../../widgets/primitives/app_card.dart';
import '../../widgets/primitives/app_text_field.dart';
import '../config.dart';
import '../error_handling.dart';

class TransferPointsDialog extends StatefulWidget {
  final String accountId;
  final String accountName;
  final VoidCallback onTransferComplete;

  const TransferPointsDialog({
    Key? key,
    required this.accountId,
    required this.accountName,
    required this.onTransferComplete,
  }) : super(key: key);

  @override
  _TransferPointsDialogState createState() => _TransferPointsDialogState();
}

class _TransferPointsDialogState extends State<TransferPointsDialog> {
  var accesstoken;
  TextEditingController pointsController = TextEditingController();
  bool pointEnterErr = false;
  TextEditingController otpController = TextEditingController();
  bool otpSent = false; // To track OTP state
  String rewardBalance = "0"; // Fetch from API if needed
  bool _isLoading = false;

  @override
  void initState() {
    fetchLocalStorageData();
    super.initState();
  }

  fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    await getDashboardDetails();
  }

  Future getDashboardDetails() async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_DETAILS + widget.accountId;

    response = await http.get(Uri.parse(apiUrl), headers: {
      "Content-Type": "application/json",
      "Authorization": accesstoken
    });

    if (response.statusCode == 200) {
      Navigator.pop(context);
      var tempResp = json.decode(response.body);
      var apiResp = tempResp['data'];

      setState(() {
        rewardBalance = apiResp['rewardPoints'].toString();
      });
    } else {
      Navigator.pop(context);
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }
  }

  Future<void> transferPoints() async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + TRANSFER_TO_DEALER;
    var tempBody = json.encode({
      "rewardPoints": int.parse(pointsController.text)
    });
    response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": accesstoken
      },
      body: tempBody,
    );
    if (response.statusCode == 200) {
      Navigator.pop(context);
      json.decode(response.body);
      Navigator.pop(context, true);
      widget.onTransferComplete();
    } else {
      Navigator.pop(context);
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
    }
  }

  void sendOTP() async {
    // Call Send OTP API
  }

  void _handleTransfer() async {
    if (pointsController.text.isEmpty) {
      setState(() => pointEnterErr = true);
      return;
    }
    final points = int.tryParse(pointsController.text);
    if (points == null || points <= 0) {
      setState(() => pointEnterErr = true);
      return;
    }
    final balance = int.tryParse(rewardBalance) ?? 0;
    if (points > balance) {
      setState(() => pointEnterErr = true);
      return;
    }
    setState(() {
      pointEnterErr = false;
      _isLoading = true;
    });
    try {
      await transferPoints();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      backgroundColor: Colors.transparent,
      child: AppCard(
        emphasis: AppCardEmphasis.form,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Title row ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transfer Points',
                      style: tt.titleMedium!
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Balance info card ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.rInput,
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reward Balance',
                      style: tt.bodySmall!.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      rewardBalance,
                      style: tt.titleMedium!.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Points input ───────────────────────────────────────────
              AppTextField(
                label: 'Points to transfer',
                hint: 'Enter amount',
                controller: pointsController,
                keyboardType: TextInputType.number,
                errorText: pointEnterErr
                    ? (pointsController.text.isEmpty
                        ? 'Please enter points to transfer'
                        : 'Invalid amount or exceeds balance of $rewardBalance')
                    : null,
                onChanged: (val) {
                  if (pointEnterErr) setState(() => pointEnterErr = false);
                  if (val.isNotEmpty) {
                    final pts = int.tryParse(val);
                    if (pts != null) {
                      if (pts <= 0) {
                        pointsController.clear();
                        setState(() => pointEnterErr = true);
                      } else if (pts > (int.tryParse(rewardBalance) ?? 0)) {
                        pointsController.clear();
                        setState(() => pointEnterErr = true);
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Actions ────────────────────────────────────────────────
              AppButton.filled(
                label: 'Transfer',
                fullWidth: true,
                loading: _isLoading,
                onPressed: _handleTransfer,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.text(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
