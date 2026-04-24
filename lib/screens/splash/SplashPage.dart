import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../utility/Utils.dart';
import '../LayOut/LayOutPage.dart';
import '../authentication/login/LoginPage.dart';
import '../dashboard/DashboardNewPage.dart';
import '../launch/launchPage.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _formKey = GlobalKey<FormState>();
  Uint8List? _cachedCert; // Cached certificate for reuse
  final String _certificatePath =
      // 'assets/certificate/AultraPaints_b20bd50c61d9d911.crt'; // Path to certificate
      'assets/certificate/AultraPaints_b20bd50c61d9d911.crt_1'; // Path to certificate

  @override
  void initState() {
    super.initState();
    certificateCheck(); // Start certificate validation
  }

  void _showSnackBar(String message, bool isSuccess) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      duration: Utils.returnStatusToastDuration(isSuccess),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> callTimer() async {
    Timer(const Duration(seconds: 2), () => onNavigate());
  }

  Future<void> onNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? authToken = prefs.getString('accessToken');

    if (authToken != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LayoutPage(child: DashboardNewPage()),
        ),
      );
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const QrScanner()),
      // );
    } else {
      Navigator.pushReplacement(
        context,
        // MaterialPageRoute(builder: (context) => const LoginPage()),
        MaterialPageRoute(builder: (context) => const LaunchPage()),
      );
    }
  }

  Future<HttpClient> createHttpClientWithCertificate() async {
    SecurityContext context = SecurityContext.defaultContext;

    try {
      // Load the certificate if not already cached
      if (_cachedCert == null) {
        final certData = await rootBundle.load(_certificatePath);
        _cachedCert = certData.buffer.asUint8List();
        debugPrint("Certificate loaded and cached successfully.");
      }

      // Apply the cached certificate to the SecurityContext
      context.setTrustedCertificatesBytes(_cachedCert!);
      debugPrint("Certificate applied to the SecurityContext.");
    } catch (e) {
      debugPrint("Error loading certificate: $e");
      throw Exception("Failed to load certificate");
    }

    return HttpClient(context: context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        debugPrint("Bad certificate callback triggered for $host:$port");
        debugPrint("Server certificate details: $cert");
        // Temporarily allow all certificates for debugging
        return true; // Set this to `false` in production after debugging
      };
  }

  Future<void> certificateCheck() async {
    try {
      HttpClient client = await createHttpClientWithCertificate();
      final request = await client
          .getUrl(Uri.parse('https://app.aultrapaints.com/')); //mobile
      // await client.getUrl(Uri.parse('https://erp.aultrapaints.com/')); //web
      // await client.getUrl(Uri.parse('https://dealerportal.mllqa.com/'));
      final response = await request.close();

      debugPrint('Response status code: ${response.statusCode}');

      // debugPrint('Response: ${response.statusCode}');
      // debugPrint('Headers: ${response.headers}');
      // response.transform(utf8.decoder).listen((data) {
      //   debugPrint('Response Body: $data');
      // });
      if (response.statusCode == 200) {
        callTimer();
      } else {
        _showSnackBar('Certification verification failed', false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      debugPrint('An error occurred during certificate check: $e');
      _showSnackBar('An error occurred: $e', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppGradients.signatureCompact,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3F10278C),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Aultra Paints', style: tt.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Experience colour like never before',
              style: tt.bodySmall!.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
