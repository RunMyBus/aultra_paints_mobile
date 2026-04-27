import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/config.dart';
import '../../../services/error_handling.dart';
import '../../../services/secure_token_store.dart';
import '/utility/Utils.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_dialog.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({Key? key}) : super(key: key);

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> {
  int? selected;

  var accesstoken;
  var USER_ID;
  var Company_ID;

  var ewbNumber;

  var argumentData;
  bool allowScanner = true;

  var scannedValue;

  @override
  void initState() {
    fetchLocalStorageDate();
    super.initState();
  }

  fetchLocalStorageDate() async {
    accesstoken = await SecureTokenStore.instance.readToken();
  }

  Future sendScannedValue(scannedValue) async {
    Utils.clearToasts(context);
    Utils.returnScreenLoader(context);
    http.Response response;

    if (accesstoken == null) {
      accesstoken = await SecureTokenStore.instance.readToken();
    }

    // var QRCodeId = scannedValue.split('tx=')[1];
    Map<String, String> requestBody = {"qrCodeUrl": scannedValue};
    final body = json.encode(requestBody);

    var apiUrl = BASE_URL + POST_SCANNED_DATA;

    response = await http.post(Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken ?? ''
        },
        body: body);
    if (response.statusCode == 200) {
      Navigator.pop(context);
      var apiResp = json.decode(response.body);
      showApiResponsePopup(context, apiResp);
    } else {
      Navigator.pop(context);
      String message;
      try {
        final apiResp = json.decode(response.body);
        message = apiResp['message'] ?? response.body;
      } catch (_) {
        message = response.body;
      }
      error_handling.errorValidation(context, response.statusCode, message, false);
      setState(() {
        allowScanner = true;
      });
    }
  }

  onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pushNamed(context, '/dashboardPage', arguments: {});
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  Future<bool> _onPopUpBack() async {
    return false;
  }

  void _showManualEntryDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Enter code manually'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Paste or type the coupon code',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final code = controller.text.trim();
                if (code.isNotEmpty) {
                  Navigator.of(ctx).pop();
                  setState(() {
                    allowScanner = false;
                  });
                  sendScannedValue(code);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.scannerBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: const Text('Scan Coupon'),
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.white.withOpacity(0.15),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    Navigator.pushReplacementNamed(context, '/dashboardPage'),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.arrow_back, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              // 1) Camera view fills the body
              Positioned.fill(
                child: allowScanner
                    ? QrCamera(
                        qrCodeCallback: (code) {
                          HapticFeedback.vibrate();
                          if (code != null) {
                            setState(() {
                              allowScanner = false;
                            });
                            sendScannedValue(code);
                          }
                        },
                      )
                    : const SizedBox.expand(),
              ),

              // 2) Viewfinder corner brackets
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    children: [
                      Positioned(
                          top: 0,
                          left: 0,
                          child: _corner(top: true, left: true)),
                      Positioned(
                          top: 0,
                          right: 0,
                          child: _corner(top: true, left: false)),
                      Positioned(
                          bottom: 0,
                          left: 0,
                          child: _corner(top: false, left: true)),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: _corner(top: false, left: false)),
                    ],
                  ),
                ),
              ),

              // 3) Bottom panel — instructions + manual entry
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Align the coupon QR within the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hold steady — auto-captures on lock',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _showManualEntryDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.25)),
                            backgroundColor: Colors.white.withOpacity(0.08),
                            shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.rInput),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Enter code manually'),
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
    );
  }

  Widget _corner({required bool top, required bool left}) {
    const double size = 26;
    const double thickness = 3;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          top: top,
          left: left,
          color: AppColors.scannerAccent,
          thickness: thickness,
        ),
      ),
    );
  }

  void showApiResponsePopup(
      BuildContext context, Map<String, dynamic> response) {
    final data = response["data"] ?? {};
    final couponCode = data["couponCode"] ?? '';
    final num rewardPoints = data["rewardPoints"] is num
        ? data["rewardPoints"]
        : num.tryParse(data["rewardPoints"]?.toString() ?? '') ?? 0;
    final num cashReward = data["cashReward"] is num
        ? data["cashReward"]
        : num.tryParse(data["cashReward"]?.toString() ?? '') ?? 0;

    final parts = <String>[];
    if (rewardPoints > 0) parts.add('$rewardPoints pts');
    if (cashReward > 0) parts.add('₹$cashReward cash');
    final creditLine = parts.isNotEmpty ? parts.join(' + ') : '0 pts';

    showAppDialog(
      context: context,
      title: 'Coupon redeemed',
      barrierDismissible: false,
      body: WillPopScope(
        onWillPop: _onPopUpBack,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: AppColors.onSuccess),
            const SizedBox(height: 8),
            Text(
              '$creditLine credited',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall!
                  .copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Code: $couponCode',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        AppDialogAction(
          label: 'OK',
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/dashboardPage'),
          primary: true,
        ),
      ],
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter(
      {required this.top,
      required this.left,
      required this.color,
      required this.thickness});
  final bool top;
  final bool left;
  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final c = thickness / 2;
    final endX = size.width - c;
    final endY = size.height - c;
    if (top && left) {
      canvas.drawLine(Offset(c, endY), Offset(c, c), paint);
      canvas.drawLine(Offset(c, c), Offset(endX, c), paint);
    } else if (top && !left) {
      canvas.drawLine(Offset(0, c), Offset(endX, c), paint);
      canvas.drawLine(Offset(endX, c), Offset(endX, endY), paint);
    } else if (!top && left) {
      canvas.drawLine(Offset(c, 0), Offset(c, endY), paint);
      canvas.drawLine(Offset(c, endY), Offset(endX, endY), paint);
    } else {
      canvas.drawLine(Offset(0, endY), Offset(endX, endY), paint);
      canvas.drawLine(Offset(endX, endY), Offset(endX, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.left != left ||
      oldDelegate.color != color;
}
