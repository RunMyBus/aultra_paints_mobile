import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';
import '../../widgets/primitives/app_card.dart';
import '../../widgets/primitives/app_button.dart';
import '../../widgets/primitives/app_text_field.dart';
import '../../widgets/primitives/app_list_row.dart';
import '../../widgets/primitives/app_empty_state.dart';
import '../../utility/Utils.dart';
import '../config.dart';
import '../error_handling.dart';

class DealerSearchDialog extends StatefulWidget {
  final Function(String, String) onDealerSelected;
  final VoidCallback onDealerComplete;

  DealerSearchDialog({
    required this.onDealerSelected,
    required this.onDealerComplete,
  });

  @override
  _DealerSearchDialogState createState() => _DealerSearchDialogState();
}

class _DealerSearchDialogState extends State<DealerSearchDialog> {
  var accesstoken;
  var USER_MOBILE_NUMBER;

  TextEditingController searchController = TextEditingController();
  // TextEditingController otpController = TextEditingController();
  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

  List<dynamic> dealerList = [];
  Map<String, dynamic>? selectedDealer;
  bool isOtpSent = false;
  String? otpReferenceId;
  bool isLoading = false;
  String verifyOtpError = '';

  @override
  void initState() {
    fetchLocalStorageData();
    super.initState();
  }

  fetchLocalStorageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER');

    // searchDealer('');
  }

  Future<void> searchDealer(String query) async {
    // Utils.clearToasts(context);
    // Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_DEALERS;
    if (query.isEmpty) {
      selectedDealer = null;
      setState(() {
        dealerList = [];
      });
      return;
    }

    setState(() => isLoading = true);

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
        dealerList = responseData['data'];
        isLoading = false;
      });
      // setState(() => isLoading = false);
      // return true;
    } else {
      setState(() => isLoading = false);
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }

    // if (response.statusCode == 200) {
    //   setState(() {
    //     dealerList = json.decode(response.body)['data'];
    //   });
    // }
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> sendOtp() async {
    if (selectedDealer == null) return;
    setState(() => isLoading = true);
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_PARENT_DEALER_CODE_DETAILS;
    var tempBody =
        json.encode({'dealerCode': selectedDealer?['dealerCode'].trim()});
    response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": accesstoken
      },
      body: tempBody,
    );
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      Navigator.pop(context);
      setState(() {
        isOtpSent = true;
        isLoading = false;
        otpReferenceId = responseData['otpRefId'];
      });
    } else {
      Navigator.pop(context);
      setState(() {
        isOtpSent = false;
        isLoading = false;
      });
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
    }
  }

  // Future saveDealerDetails(String dealerCode, String otp) async {
  //   Utils.clearToasts(context);
  //   Utils.returnScreenLoader(context);
  //   http.Response response;
  //   var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;
  //   var tempBody = json.encode({
  //     'dealerCode': dealerCode,
  //     'otp': otp,
  //     'mobile': userParentDealerMobile,
  //     'painterMobile': USER_MOBILE_NUMBER
  //   });
  //   response = await http.post(
  //     Uri.parse(apiUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       "Authorization": accesstoken
  //     },
  //     body: tempBody,
  //   );
  //   if (response.statusCode == 200) {
  //     Navigator.pop(context);
  //     var tempResp = json.decode(response.body);
  //     SharedPreferences prefs = await SharedPreferences.getInstance();
  //     await prefs.setString('USER_PARENT_DEALER_CODE',
  //         tempResp['data']?['parentDealerCode'] ?? '');
  //     Navigator.pop(context, true);
  //     _showSnackBar("Details saved successfully.", context, true);
  //   } else {
  //     Navigator.pop(context);
  //     final tempResp = json.decode(response.body);
  //     error_handling.errorValidation(
  //         context, response.statusCode, tempResp['message'], false);
  //   }
  // }

  Future<void> verifyOtp(String otp) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;
    var tempBody = json.encode({
      'dealerCode': selectedDealer?['dealerCode'],
      'otp': otp,
      'mobile': selectedDealer?['mobile'],
      'painterMobile': USER_MOBILE_NUMBER
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
      verifyOtpError = '';
      Navigator.pop(context);
      var tempResp = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('USER_PARENT_DEALER_CODE',
          tempResp['data']?['parentDealerCode'] ?? '');
      await prefs.setString('USER_PARENT_DEALER_NAME',
          tempResp['data']?['parentDealerName'] ?? '');
      Navigator.pop(context, true);
      Navigator.pop(context, selectedDealer);
      widget.onDealerComplete();
      _showSnackBar("Details saved successfully.", context, true);
    } else {
      Navigator.pop(context);
      final tempResp = json.decode(response.body);
      verifyOtpError = tempResp['error'];
      error_handling.errorValidation(
          context, response.statusCode, tempResp['error'], false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      backgroundColor: Colors.transparent,
      child: AppCard(
        emphasis: AppCardEmphasis.form,
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Dealer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.onSurfaceVariant,
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.outline),

            // ── Search field (shown only before OTP step) ────────────
            if (!isOtpSent) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)
                    .copyWith(top: AppSpacing.lg, bottom: AppSpacing.sm),
                child: AppTextField(
                  label: '',
                  hint: 'Enter dealer name or mobile',
                  controller: searchController,
                  prefix: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onChanged: (value) {
                    searchDealer(value);
                  },
                ),
              ),

              // ── Results area ────────────────────────────────────────
              SizedBox(
                height: 300,
                child: _buildResultsArea(),
              ),

              // ── Footer: Cancel ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AppButton.text(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],

            // ── OTP step ────────────────────────────────────────────
            if (isOtpSent) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildOtpStep(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Results list / loading / empty ───────────────────────────────────────

  Widget _buildResultsArea() {
    // If user hasn't typed yet
    if (searchController.text.isEmpty) {
      return const AppEmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'Search for a dealer',
        message: 'Type a dealer name or mobile number to begin.',
      );
    }

    // Loading with no results yet
    if (isLoading && dealerList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // No results after search
    if (!isLoading && dealerList.isEmpty) {
      return const AppEmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'No dealers found',
        message: 'Try a different name or code.',
      );
    }

    // Results list
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      itemCount: dealerList.length,
      itemBuilder: (context, index) {
        final dealer = dealerList[index] as Map<String, dynamic>;
        final name = dealer['name'] ?? '';
        final code = dealer['dealerCode'] ?? '';
        final mobile = dealer['mobile'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppListRow(
            title: name,
            subtitle: '$code · $mobile',
            trailing: const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () {
              setState(() {
                selectedDealer = dealer;
              });
              sendOtp();
            },
          ),
        );
      },
    );
  }

  // ── OTP step UI ──────────────────────────────────────────────────────────

  Widget _buildOtpStep(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected dealer summary card
        if (selectedDealer != null)
          Container(
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: AppRadius.rCard,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedDealer!['name'] ?? '',
                  style: t.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Phone: ${selectedDealer!['mobile'] ?? ''}',
                  style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  'Address: ${selectedDealer!['address'] ?? ''}',
                  style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  'Code: ${selectedDealer!['dealerCode'] ?? ''}',
                  style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          'Dealer OTP',
          style: t.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // 6-digit OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 44,
              child: TextFormField(
                controller: otpControllers[index],
                maxLength: 1,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: t.titleMedium?.copyWith(color: AppColors.onSurface),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.rInput,
                    borderSide: const BorderSide(color: AppColors.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.rInput,
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerHigh,
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            );
          }),
        ),

        if (verifyOtpError.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            verifyOtpError,
            style: t.bodySmall?.copyWith(color: AppColors.onError),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // OTP expiry message
        Text(
          'The 6-digit OTP was sent to ${selectedDealer?['name'] ?? ''}. OTP expiry time is 10 minutes.',
          style: t.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Countdown timer / resend
        StreamBuilder<int>(
          stream: Stream.periodic(
              const Duration(seconds: 1), (i) => 600 - i - 1).take(600),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final remainingSeconds = snapshot.data!;
            final minutes = remainingSeconds ~/ 60;
            final seconds = remainingSeconds % 60;
            if (remainingSeconds == 0) {
              for (var controller in otpControllers) {
                controller.clear();
              }
              return TextButton(
                onPressed: sendOtp,
                child: Text(
                  'Resend OTP',
                  style: t.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }
            return Text(
              'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: t.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        // Action row: Cancel + Confirm
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.text(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.filled(
              label: 'OK',
              loading: isLoading,
              onPressed: () async {
                final otp =
                    otpControllers.map((e) => e.text).join();
                if (otp.length == 6) {
                  verifyOtp(otp);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please enter a valid 6-digit OTP.'),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}
