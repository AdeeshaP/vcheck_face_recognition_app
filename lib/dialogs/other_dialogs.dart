import 'package:flutter/material.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';

// import 'package:google_ml_kit/google_ml_kit.dart';

String removeLastCharacter(String str) {
  String result = "";
  if ((str.isNotEmpty)) {
    result = str.substring(0, str.length - 1);
  }
  return result;
}

showProgressDialog(BuildContext context) {
  AlertDialog alert = AlertDialog(
    content: Row(
      children: [
        CircularProgressIndicator(
          color: screenHeadingColor,
        ),
        SizedBox(
          width: Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 1
              : 10,
        ),
        Container(
          margin: EdgeInsets.only(left: 5),
          child: Text(
            "Loading",
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 15
                  : Responsive.isTabletPortrait(context)
                      ? 24
                      : 20,
            ),
          ),
        ),
      ],
    ),
  );
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

closeDialog(context) {
  Navigator.of(context, rootNavigator: true).pop('dialog');
}
