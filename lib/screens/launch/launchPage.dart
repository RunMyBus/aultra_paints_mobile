import 'dart:async';
import 'dart:io';

import 'package:aultra_paints_mobile/utility/size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utility/Utils.dart';
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var authtoken = prefs.getString('accessToken');

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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    return Scaffold(
        key: _scaffoldKey,
        body: Container(
            height: screenHeight, // 100% height
            width: screenWidth, // 100% width
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFF7AD),
                  Color(0xFFFFA9F9),
                ],
              ),
            ),
            child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: screenHeight,
                    child: Center(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.04,
                            ),
                            height: screenHeight * 0.83,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width: screenWidth * 0.9,
                                    child: Column(
                                      children: [
                                        SizedBox(
                                            height: screenHeight * 0.3,
                                            child: Image.asset(
                                                'assets/images/app_file_icon.png')),
                                        SizedBox(
                                            height: screenHeight * 0.14,
                                            child: Image.asset(
                                                'assets/images/app_name.png')),
                                      ],
                                    ),
                                  ),
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Let’s Get',
                                            style: TextStyle(
                                                color: const Color(0xFF7A0180),
                                                fontSize:
                                                    unitHeightValue * 0.04,
                                                fontWeight: FontWeight.w300)),
                                        Text('Started!',
                                            style: TextStyle(
                                              color: const Color(0xFF7A0180),
                                              fontSize: unitHeightValue * 0.04,
                                              fontWeight: FontWeight.bold,
                                            ))
                                      ]),
                                  GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                          context, '/loginPage'),
                                      child: Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0,
                                          vertical: screenHeight * 0.05,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFF000000),
                                              Color(0xFF3533CD),
                                            ],
                                          ),
                                        ),
                                        width: screenWidth * 0.6,
                                        height: screenHeight * 0.06,
                                        child: Center(
                                          child: Text(
                                            'SIGN IN',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    unitHeightValue * 0.02,
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ),
                                      )),
                                ])),
                        Container(
                            width: screenWidth,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.1,
                              vertical: screenHeight * 0.048,
                            ),
                            decoration: const BoxDecoration(
                                border: Border(
                                    top: BorderSide(
                              color: Colors.white,
                              width: 1.0,
                            ))),
                            child: Column(children: [
                              Text("DIDN'T HAVE ACCOUNT",
                                  style: TextStyle(
                                    color: const Color(0xFF7A0180),
                                    fontSize: unitHeightValue * 0.016,
                                    fontWeight: FontWeight.w400,
                                  )),
                              const SizedBox(height: 5),
                              GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                      context, '/signupPage'),
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(0xFF000000),
                                            Color(0xFF3533CD),
                                          ],
                                        ),
                                      ),
                                      width: screenWidth * 0.4,
                                      height: screenHeight * 0.04,
                                      child: Center(
                                        child: Text(
                                          'SIGN UP NOW',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: unitHeightValue * 0.02,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      )))
                            ]))
                      ],
                    )),
                  ),
                ))));
  }
}
