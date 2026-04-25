import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Utils.dart';
import 'size_config.dart';

class SingleParamHeader extends StatelessWidget {
  final String headerText;
  final String subHeaderText;
  final BuildContext context;
  final bool showQueryButton;
  final Function onBack;

  SingleParamHeader(this.headerText, this.subHeaderText, this.context,
      this.showQueryButton, this.onBack);

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  clearStorage() async {
    Utils.clearToasts(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    Navigator.of(context).pushNamed('/splashPage');
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double unitHeightValue = MediaQuery.of(context).size.height;
    SizeConfig().init(context);
    return Container(
      // color: Colors.white,
      margin: EdgeInsets.only(
          left: getScreenWidth(20),
          right: getScreenWidth(20),
          top: getScreenHeight(70)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              Utils.clearToasts(context);
              onBack();
            },
            child: Container(
                padding: EdgeInsets.all(getScreenWidth(10)),
                decoration: BoxDecoration(
                  // color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(getScreenWidth(50)),
                ),
                child: Icon(
                  Icons.keyboard_double_arrow_left_sharp,
                  size: unitHeightValue * 0.04,
                  // color: backButtonCircleIconColor,
                  color: const Color(0xFF7A0180),
                )),
          ),
          SizedBox(width: getScreenWidth(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headerText,
                  style: TextStyle(
                    fontSize: getScreenWidth(20),
                    height: 1.2,
                    // color: buttonBorderColor,
                    color: const Color(0xFF7A0180),
                  ),
                ),
                subHeaderText != ""
                    ? Text(
                        subHeaderText,
                        style: TextStyle(
                          fontSize: getScreenWidth(12),
                          // color: buttonBorderColor,
                          color: const Color(0xFF7A0180),
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
          ),
          // headerText == 'Create Indent' ||
          //         headerText == 'Enter\nInvoice Details' ||
          //         headerText == 'Invoice Details'
          !showQueryButton
              ? SizedBox.shrink()
              : InkWell(
                  onTap: () {
                    clearStorage();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: getScreenWidth(5),
                        vertical: getScreenHeight(8)),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(204, 0, 28, 1),
                      borderRadius: BorderRadius.circular(getScreenWidth(8)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: getScreenWidth(12),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
