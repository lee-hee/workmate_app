import 'package:flutter/material.dart';

class ResponsiveWorkItemUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static double getDetailsWidthRatio(BuildContext context) {
    return 0.4; // 40% width for booking details
  }

  static double getServiceListWidthRatio(BuildContext context) {
    return 0.6; // 60% width for service list
  }

  static EdgeInsets getSectionPadding(BuildContext context) {
    return const EdgeInsets.all(16.0);
  }

  // Service item box
  static EdgeInsets getServiceItemListMargin(BuildContext context) {
    return ResponsiveWorkItemUtils.isWideScreen(context)
        ? const EdgeInsets.all(8.0) // web
        : const EdgeInsets.all(15.0); // mobile
  }

  static EdgeInsets getServiceItemListPadding(BuildContext context) {
    return ResponsiveWorkItemUtils.isWideScreen(context)
        ? const EdgeInsets.all(2.0) // web
        : const EdgeInsets.all(3.0); // mobile
  }

  static double getServiceItemListWidth(BuildContext context) {
    return ResponsiveWorkItemUtils.isWideScreen(context)
        ? 400.0 // web
        : double.infinity; // mobile
  }

  static double getServiceItemListHeight(BuildContext context) {
    return ResponsiveWorkItemUtils.isWideScreen(context)
        ? 300.0 // web
        : double.infinity; // mobile
  }

  // ListTile drop down box
  static EdgeInsets getDropdownPadding(BuildContext context) {
    return ResponsiveWorkItemUtils.isWideScreen(context)
        ? const EdgeInsets.fromLTRB(12.0, 12.0, 0.0, 10.0) // web
        : const EdgeInsets.only(
            left: 8.0, top: 10.0, right: 0.0, bottom: 6.0); // mobile
  }
}
