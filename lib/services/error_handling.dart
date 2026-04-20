// error_handling

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/Utils.dart';

class error_handling {
  static _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static errorValidation(context, statusCode, message, messageType) async {
    // Utils.clearToasts(context);
    if (statusCode == 401 || statusCode == 502) {
      _showSnackBar(message, context, messageType);
      clearStorage(context);
    } else {
      _showSnackBar(message, context, messageType);
      // Navigator.pop(context);
    }
  }

  static clearStorage(context) async {
    // Utils.clearToasts(context);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    // Navigator.pushReplacement(
    //     context, MaterialPageRoute(builder: (context) => const SplashPage()));
    // Navigator.pushNamed(context, '/splashPage');
    Navigator.of(context).pushNamed('/splashPage');
  }
}
