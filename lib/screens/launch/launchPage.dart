import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/secure_token_store.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_spacing.dart';
import '../../utility/Utils.dart';
import '../../widgets/primitives/app_button.dart';
import '../LayOut/LayOutPage.dart';
import '../authentication/login/LoginPage.dart';
import '../dashboard/DashboardNewPage.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({Key? key}) : super(key: key);

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // callTimer();
    // certificateCheck();
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  callTimer() {
    Timer(const Duration(seconds: 2), () => onNavigate());
  }

  onNavigate() async {
    var authtoken = await SecureTokenStore.instance.readToken();

    if (authtoken != null) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const LayoutPage(child: DashboardNewPage())));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const LaunchPage()));
    }
  }

  Future<HttpClient> createHttpClientWithCertificate() async {
    SecurityContext context = SecurityContext.defaultContext;
    try {
      // final certData =
      //     await rootBundle.load('assets/certificate/STAR_mlldev_com.crt'); //dev
      final certData = await rootBundle
          .load('assets/certificate/AultraPaints_b20bd50c61d9d911.crt'); //QA
      context.setTrustedCertificatesBytes(certData.buffer.asUint8List());
    } catch (e) {
      throw Exception("Failed to load certificate");
    }
    return HttpClient(context: context)
      ..badCertificateCallback = (cert, host, port) => false;
  }

  Future<void> certificateCheck() async {
    try {
      HttpClient client = await createHttpClientWithCertificate();

      final request =
          await client.getUrl(Uri.parse('https://api.aultrapaints.com'));

      final response = await request.close();

      if (response.statusCode == 200) {
        callTimer();
      } else {
        // Ensure the widget is still mounted
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const LoginPage()),
        // );

        // _showSnackBar('Certification verification failed', context, false);
      }
    } catch (e) {
      if (!mounted) return; // Ensure the widget is still mounted
      _showSnackBar('An error occurred: $e', context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppGradients.signatureCompact,
                  borderRadius: BorderRadius.circular(24),
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
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Aultra Paints', style: tt.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Experience colour like never before',
                style: tt.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              AppButton.filled(
                label: 'Sign in',
                onPressed: () => Navigator.pushNamed(context, '/loginPage'),
                fullWidth: true,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton.outlined(
                label: "Don't have an account? Sign up",
                onPressed: () => Navigator.pushNamed(context, '/signupPage'),
                fullWidth: true,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}
