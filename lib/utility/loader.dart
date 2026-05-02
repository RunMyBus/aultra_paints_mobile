import '/utility/size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Loader {
  static bool _isLoaderVisible = false;
  static String msg = "0";
  static showLoader(BuildContext context) {
    if (!_isLoaderVisible) {
      _isLoaderVisible = true;
      SizeConfig().init(context);
      showGeneralDialog(
        context: context,
        barrierColor: const Color(0xFFC8C7C7).withValues(alpha: 0.9),
        // barrierColor: Colors.black12.withOpacity(0.6), // Background color
        barrierDismissible: false,
        // barrierLabel: 'Dialog',
        // transitionDuration: Duration(milliseconds: 400),
        pageBuilder: (context, __, ___) {
          return Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(
                        left: getProportionateScreenHeight(80),
                        right: getProportionateScreenHeight(10)),
                    child: SizedBox(
                      // width: getProportionateScreenWidth(500),
                      // height: getProportionateScreenWidth(250),
                      height: getScreenWidth(60),
                      child: Image.asset(
                        'assets/images/app_file_icon.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  )
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        // margin: EdgeInsets.only(top: getProportionateScreenHeight(0), right: getProportionateScreenHeight(10)),
                        child: Text(
                          "Loading...",
                          style: TextStyle(
                              fontSize: getProportionateScreenWidth(20),
                              color: Colors.black),
                        ),
                      )
                    ],
                  )
                ],
              )
            ],
          );
        },
      );

      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (BuildContext context) {
      //     return Dialog(
      //       backgroundColor: Colors.transparent,
      //       child: Column(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           SizedBox(
      //             width: getProportionateScreenWidth(200),
      //             height: getProportionateScreenWidth(100),
      //             child: Image.asset(
      //               'assets/images/loader.gif',
      //               fit: BoxFit.fill,
      //             ),
      //           ),
      //           // SizedBox(height: getProportionateScreenWidth(20)),
      //           // Text(
      //           //   "Loading",
      //           //   style: TextStyle(
      //           //       fontSize: getProportionateScreenWidth(20),
      //           //       fontFamily: ffGBold,
      //           //       color: black),
      //           // )
      //         ],
      //       ),
      //     );
      //   },
      // );
    }
  }

  static void hideLoader(BuildContext context) {
    if (_isLoaderVisible) {
      _isLoaderVisible = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
