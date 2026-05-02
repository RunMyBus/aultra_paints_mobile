import '/utility/size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


Widget FooterButton(String ButtonTitle, String buttonFrom, BuildContext context,
    Function navigationRoute) {
  final double screenHeight = MediaQuery.of(context).size.height;
  final double screenWidth = MediaQuery.of(context).size.width;
  return Container(
    child: InkWell(
      onTap: () {
        navigationRoute();
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            vertical: screenHeight * 0.01,
            horizontal: screenWidth *
                (buttonFrom == 'download'
                    ? 0.03
                    : buttonFrom == 'fullWidth'
                        ? 0
                        : 0.08)),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(getScreenWidth(10))),
            side: const BorderSide(width: 1, color: Color.fromRGBO(44, 62, 80, 1)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(44, 62, 80, 1),
              borderRadius:
                  BorderRadius.all(Radius.circular(getScreenWidth(10))),
            ),
            alignment: Alignment.center,
            height: getScreenHeight(60),
            child: Text(
              ButtonTitle,
              style: TextStyle(
                fontSize: getScreenWidth(16),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
