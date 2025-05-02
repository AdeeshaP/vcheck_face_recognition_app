import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget androidSmall;
  final Widget androidMedium;
  final Widget androidLarge;
  final Widget tabletPortrait;
  final Widget tabletLandscape;

  const Responsive({
    Key? key,
    required this.androidSmall,
    required this.androidLarge,
    required this.androidMedium,
    required this.tabletPortrait,
    required this.tabletLandscape,
  }) : super(key: key);

  // 4.1" - 5.0"

  static bool isMobileSmall(BuildContext context) =>
      MediaQuery.of(context).size.width <= 360 &&
      MediaQuery.of(context).size.height <= 600;

  // 5.1" - 6.0"
  static bool isMobileMedium(BuildContext context) =>
      MediaQuery.of(context).size.width <= 400 &&
      MediaQuery.of(context).size.height <= 760;

  // 6.1" - 7.0"
  static bool isMobileLarge(BuildContext context) =>
      MediaQuery.of(context).size.width <= 500 &&
      MediaQuery.of(context).size.height <= 900;

  static bool isTabletPortrait(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1000 &&
      MediaQuery.of(context).size.height <= 1400;

  static bool isTabletLandscape(BuildContext context) =>
      MediaQuery.of(context).size.width <= 2000 &&
      MediaQuery.of(context).size.height <= 1000;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    if (size.width <= 1080 && size.height <= 1920) {
      return androidSmall;
    } else if (size.width <= 1440 && size.height <= 2540) {
      return androidMedium;
    } else if (size.width <= 1440 && size.height <= 3120) {
      return androidLarge;
    } else if (size.width <= 1000 && size.height <= 1400) {
      return tabletPortrait;
    }
    return tabletLandscape;
  }
}
