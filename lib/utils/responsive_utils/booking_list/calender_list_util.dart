import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveBookingListUtils {
  static bool isWideScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  static double getCalendarWidthRatio(BuildContext context) {
    return 0.4; // 40% width for calendar
  }

  static double getTaskListWidthRatio(BuildContext context) {
    return 0.5; // 50% width for task list
  }

  static EdgeInsets getSectionPadding(BuildContext context) {
    return const EdgeInsets.all(16);
  }

  // Calendar Header
  static EdgeInsets getHeaderPadding(BuildContext context) {
    return kIsWeb
        ? const EdgeInsets.symmetric(vertical: 4.0)
        : const EdgeInsets.symmetric(vertical: 8.0);
  }

  // Booking description
  static EdgeInsets getDescriptionPadding(BuildContext context) {
    return ResponsiveBookingListUtils.isWideScreen(context)
        ? const EdgeInsets.all(8.0) // web
        : const EdgeInsets.all(12.0); // mobile
  }

  static double getItemHeight(BuildContext context) {
    return ResponsiveBookingListUtils.isWideScreen(context)
        ? 120.0 // web
        : 100.0; // mobile
  }

  // Breakpoints for mobile/tablet/desktop/laptop screens
  static const double _mobileBreakpoint = 600; // Mobile width max
  static const double _tabletBreakpointMax = 1024; // Tablet width end
  static const double _smallBreakpoint = 1024; // Small desktop start
  static const double _mediumBreakpoint = 1200; // Medium
  static const double _largeBreakpoint = 1440; // Large
  static const double _xlBreakpoint = 1920; // Extra-large

  // Categorize screen size
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < _mobileBreakpoint) return ScreenSize.mobile;
    if (width < _tabletBreakpointMax) return ScreenSize.tablet;
    if (width < _smallBreakpoint) return ScreenSize.small;
    if (width < _mediumBreakpoint) return ScreenSize.medium;
    if (width < _largeBreakpoint) return ScreenSize.large;
    if (width < _xlBreakpoint) return ScreenSize.xl;
    return ScreenSize.xxl; // Ultra-wide >1920px
  }

  // If mobile width
  static bool isMobile(BuildContext context) {
    return getScreenSize(context) == ScreenSize.mobile;
  }

  // If tablet width
  static bool isTablet(BuildContext context) {
    return getScreenSize(context) == ScreenSize.tablet;
  }

  // If mobile/tablet
  static bool isMobileOrTablet(BuildContext context) {
    return isMobile(context) || isTablet(context);
  }

  // Dynamic calendar width based on screen size
  static double getCalendarWidthRatioNew(BuildContext context) {
    switch (getScreenSize(context)) {
      case ScreenSize.tablet:
        return 0.5; // 50% - tablets
      case ScreenSize.small:
        return 0.45; // 45% - narrow screens
      case ScreenSize.medium:
        return 0.4; // 40% - standard
      case ScreenSize.large:
        return 0.35; // 35% - larger screens
      case ScreenSize.xl:
      case ScreenSize.xxl:
        return 0.3; // 30% - ultra-wide
      default:
        return 0.5; // mobile
    }
  }

  // Complements calendar ratio
  static double getTaskListWidthRatioNew(BuildContext context) {
    final calendarRatio = getCalendarWidthRatioNew(context);
    return 1.0 - calendarRatio - 0.05;
  }

  // Tablet screen
  static double getItemHeightWidthAware(BuildContext context) {
    final baseHeight = getItemHeight(context);
    if (isTablet(context)) {
      return baseHeight + 10.0;
    }
    return baseHeight;
  }

  // Tablet-width padding
  static EdgeInsets getDescriptionPaddingWidthAware(BuildContext context) {
    if (isMobileOrTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0);
    }
    return getDescriptionPadding(context);
  }
}

// Enum for screen sizes
enum ScreenSize { mobile, tablet, small, medium, large, xl, xxl }
