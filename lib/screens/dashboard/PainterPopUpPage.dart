import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../services/config.dart';
import '../../../services/error_handling.dart';
import '/utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: unused_import — kept for potential QR camera feature
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:http/http.dart' as http;
import '../../../services/secure_token_store.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_button.dart';
import '../../../widgets/primitives/app_card.dart';

class PainterPopUpPage extends StatefulWidget {
  const PainterPopUpPage({Key? key}) : super(key: key);

  @override
  State<PainterPopUpPage> createState() => _PainterPopUpPageState();
}

class _PainterPopUpPageState extends State<PainterPopUpPage> {
  int? selected;

  var accesstoken;
  var USER_ID;
  var Company_ID;

  var ewbNumber;

  var argumentData;
  bool allowScanner = true;

  var scannedValue;

  var userParentDealerName;
  var userParentDealerMobile;
  var USER_MOBILE_NUMBER;

  // Controller for the input fields
  TextEditingController dealerCodeController = TextEditingController();
  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

  bool isOtpVisible = false;
  bool isLoading = false;

  List<dynamic> dealerList = [];
  Map<String, dynamic>? selectedDealer;
  bool isOtpSent = false;

  @override
  void initState() {
    fetchLocalStorageDate();
    super.initState();
  }

  fetchLocalStorageDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = await SecureTokenStore.instance.readToken();
    USER_MOBILE_NUMBER = prefs.getString('USER_MOBILE_NUMBER');
    userParentDealerName = prefs.getString('userParentDealerName');
  }

  Future<void> searchDealer(String query) async {
    http.Response response;
    var apiUrl = BASE_URL + GET_DEALERS;
    if (query.isEmpty || accesstoken == null) {
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
        dealerList = responseData['data'];
      });
    } else {
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future fetchOtp(String dealerCode) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + GET_USER_PARENT_DEALER_CODE_DETAILS;
    var tempBody = json.encode({'dealerCode': dealerCode.trim()});
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
        isOtpVisible = true;
        isOtpSent = true;
        userParentDealerMobile = responseData["data"]['mobile'];
        userParentDealerName = responseData["data"]['name'];
      });
    } else {
      Navigator.pop(context);
      setState(() {
        isOtpVisible = false;
        isOtpSent = false;
      });
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
    }
  }

  Future saveDealerDetails(String dealerCode, String otp) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;
    var apiUrl = BASE_URL + VERIFY_OTP_UPDATE_USER;
    var tempBody = json.encode({
      'dealerCode': dealerCode,
      'otp': otp,
      'mobile': userParentDealerMobile,
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
      Navigator.pop(context);
      var tempResp = json.decode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('USER_PARENT_DEALER_CODE',
          tempResp['data']?['parentDealerCode'] ?? '');
      Navigator.pushNamed(context, '/dashboardPage');
      _showSnackBar("Details saved successfully.", context, true);
    } else {
      Navigator.pop(context);
      final tempResp = json.decode(response.body);
      error_handling.errorValidation(
          context, response.statusCode, tempResp['message'], false);
    }
  }

  onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surfaceContainerHigh,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_outlined),
            onPressed: onBackPressed,
          ),
          title: Text(
            'Enter Partner Details',
            style: tt.titleMedium!
                .copyWith(color: AppColors.surfaceContainerHigh),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppCard(
            emphasis: AppCardEmphasis.form,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEALER',
                  style: tt.labelMedium!.copyWith(
                      color: AppColors.onSurfaceVariant, letterSpacing: 0.6),
                ),
                const SizedBox(height: AppSpacing.xs),
                // ── Dealer autocomplete ──────────────────────────────────
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder:
                      (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      setState(() {
                        selectedDealer = null;
                      });
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    await searchDealer(textEditingValue.text);
                    return dealerList.cast<Map<String, dynamic>>();
                  },
                  displayStringForOption:
                      (Map<String, dynamic> option) => option['name'],
                  onSelected: (Map<String, dynamic> selection) {
                    setState(() {
                      selectedDealer = selection;
                    });
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: AppRadius.rCard,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: screenHeight * 0.3,
                          ),
                          child: Container(
                            width: screenWidth * 0.7,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: AppRadius.rCard,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2010278C),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  borderRadius: AppRadius.rListRow,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.lg,
                                        vertical: AppSpacing.sm),
                                    child: Text(
                                      '${option['name']} - ${option['mobile']}',
                                      style: tt.bodyMedium!.copyWith(
                                          color: AppColors.onSurface),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, textEditingController,
                      focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      enabled: !isOtpSent,
                      decoration: InputDecoration(
                        hintText: 'Enter Dealer Name & Mobile',
                        suffixIcon: const Icon(Icons.search_outlined,
                            color: AppColors.onSurfaceVariant),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.rCard,
                          borderSide: const BorderSide(
                              color: AppColors.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.rCard,
                          borderSide: const BorderSide(
                              color: AppColors.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.rCard,
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md),
                      ),
                    );
                  },
                ),
                // ── OTP section (visible after "Get OTP") ────────────────
                if (isOtpVisible) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'DEALER OTP',
                    style: tt.labelMedium!.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.6),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // 6-box OTP row
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
                          style: tt.titleMedium!
                              .copyWith(color: AppColors.primary),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: AppColors.infoBg,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.rCard,
                              borderSide: const BorderSide(
                                  color: AppColors.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppRadius.rCard,
                              borderSide: const BorderSide(
                                  color: AppColors.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppRadius.rCard,
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
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
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The 6-digit OTP was sent to $userParentDealerName. OTP expiry time is 10 minutes.',
                    style: tt.bodySmall!
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  StreamBuilder<int>(
                    stream: Stream.periodic(
                            const Duration(seconds: 1), (i) => 600 - i - 1)
                        .take(600),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final remainingSeconds = snapshot.data!;
                        final minutes = remainingSeconds ~/ 60;
                        final seconds = remainingSeconds % 60;
                        return Text(
                          'Time remaining: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: tt.bodySmall!.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                // ── Action buttons ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.text(
                      label: 'Cancel',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (!isOtpVisible)
                      AppButton.filled(
                        label: 'Get OTP',
                        loading: isLoading,
                        onPressed: () async {
                          if (selectedDealer != null) {
                            fetchOtp(
                                selectedDealer?['dealerCode'].trim());
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please select a dealer first.')),
                            );
                          }
                        },
                      ),
                    if (isOtpVisible)
                      AppButton.filled(
                        label: 'Confirm',
                        loading: isLoading,
                        onPressed: () async {
                          String otp =
                              otpControllers.map((e) => e.text).join();
                          if (otp.length == 6) {
                            saveDealerDetails(
                                selectedDealer?['dealerCode'].trim(), otp);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please enter a valid 6-digit OTP.')),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showApiResponsePopup(
      BuildContext context, Map<String, dynamic> response) {
    // ignore: unused_local_variable — kept for future use
    final message = response["message"] ?? "No message";
    final data = response["data"] ?? {};
    var couponCode = data["couponCode"] ?? '';
    var rewardPoints = data["rewardPoints"] ?? '';
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: _onWillPop,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rCard,
                ),
                elevation: 10,
                child: AppCard(
                  emphasis: AppCardEmphasis.featured,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        rewardPoints.toString(),
                        style: tt.displaySmall!
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'With Coupon: $couponCode',
                        style: tt.bodyMedium!
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
