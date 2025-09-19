// // Copyright 2019 Aleksander Woźniak
// // SPDX-License-Identifier: Apache-2.0

// import 'dart:collection';

// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// //Config
// import '../../config/backend_config.dart';

// /// Example event class.
// class Event {
//   final String rego;
//   final String phone;
//   final String bookingRef;
//   final String bookingTime;
//   final List<dynamic> serviceItemIds;
//   final String serviceName;
//   final String servicDuration;

//   const Event(this.rego, this.phone, this.bookingRef, this.serviceItemIds,
//       this.serviceName, this.servicDuration, this.bookingTime);

//   @override
//   String toString() => rego + phone + bookingRef;
// }

// class BookingSummary {
//   final String rego;
//   final List<BookingEntry> bookingEntries;
//   const BookingSummary(this.rego, this.bookingEntries);

//   @override
//   String toString() => rego + bookingEntries.toString();
// }

// class BookingEntry {
//   final String phone;
//   final String bookingRef;
//   final String bookingTime;
//   final List<dynamic> serviceItemIds;
//   final String serviceName;
//   final String servicDuration;

//   const BookingEntry(this.phone, this.bookingRef, this.serviceItemIds,
//       this.serviceName, this.servicDuration, this.bookingTime);
// }

// final DateFormat serverFormater = DateFormat('yyyy-MM-dd');

// /// Example events.
// ///
// /// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
// Map<DateTime, List<BookingSummary>> kEvents =
//     <DateTime, List<BookingSummary>>{};
// List<BookingSummary> events = [];

// Future fetchBookingsForFocusedMonth(DateTime focusedDay) async {
//   var rangeStartDay = DateTime(focusedDay.year, focusedDay.month, 1);
//   var rangeEndDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
//   final String formattedStartDay = serverFormater.format(rangeStartDay);
//   final String formattedEndtDay = serverFormater.format(rangeEndDay);
//   final url = BackendConfig.getUri(
//       'v1/bookings-within/$formattedStartDay/$formattedEndtDay');
//   kEvents.clear();
//   events.clear();
//   final response = await http.get(url);

//   if (response.statusCode != 200) {
//     throw Exception('Failed to fetch bookings. Please try again later.');
//   }
//   final Map bookingsGroupedByDate = json.decode(response.body);
//   bookingsGroupedByDate.forEach((key, value) {
//     List<BookingSummary> bookingEvents = [];
//     for (final bookingSummaryEntry in value) {
//       List<dynamic> bookingsForBookingSummary = bookingSummaryEntry['bookings'];
//       List<BookingEntry> bookingEntryList = [];
//       for (var booking in bookingsForBookingSummary) {
//         var bookingEntry = BookingEntry(
//             booking['customerPhone'],
//             booking['bookingReferenceNumber'],
//             booking['serviceItemIds'],
//             booking['serviceName'],
//             booking['serviceDuration'],
//             booking['bookingDateTime']);
//         bookingEntryList.add(bookingEntry);
//       }

//       var bookingSummary =
//           BookingSummary(bookingSummaryEntry['rego'], bookingEntryList);
//       bookingEvents.add(bookingSummary);
//       events.add(bookingSummary);
//     }
//     DateTime bookingDate = DateTime.parse(key);
//     DateTime dateToConsider =
//         DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
//     kEvents[dateToConsider] = bookingEvents;
//   });

//   return events;
// }

// int getHashCode(DateTime key) {
//   return key.day * 1000000 + key.month * 10000 + key.year;
// }

// /// Returns a list of [DateTime] objects from [first] to [last], inclusive.
// List<DateTime> daysInRange(DateTime first, DateTime last) {
//   final dayCount = last.difference(first).inDays + 1;
//   return List.generate(
//     dayCount,
//     (index) => DateTime.utc(first.year, first.month, first.day + index),
//   );
// }

// final kToday = DateTime.now();
// final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
// final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//Config
import '../../config/backend_config.dart';

/// Example event class.
class Event {
  final String rego;
  final String phone;
  final String bookingRef;
  final String bookingTime;
  final String serviceName;
  final String servicDuration;

  const Event(this.rego, this.phone, this.bookingRef, this.serviceName,
      this.servicDuration, this.bookingTime);

  @override
  String toString() => rego + phone + bookingRef;
}

class BookingSummary {
  final String rego;
  final List<BookingEntry> bookingEntries;
  const BookingSummary(this.rego, this.bookingEntries);

  @override
  String toString() => rego + bookingEntries.toString();
}

class BookingEntry {
  final String phone;
  final String bookingRef;
  final String bookingTime;
  final String serviceName;
  final String servicDuration;

  const BookingEntry(this.phone, this.bookingRef, this.serviceName,
      this.servicDuration, this.bookingTime);
}

final DateFormat serverFormater = DateFormat('yyyy-MM-dd');

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
Map<DateTime, List<BookingSummary>> kEvents =
    <DateTime, List<BookingSummary>>{};
List<BookingSummary> events = [];

// Updated this method and removed serviceItemIds from BookingEntry
Future<List<BookingSummary>> fetchBookingsForFocusedMonth(
    DateTime focusedDay) async {
  var rangeStartDay = DateTime(focusedDay.year, focusedDay.month, 1);
  var rangeEndDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
  final String formattedStartDay = serverFormater.format(rangeStartDay);
  final String formattedEndDay = serverFormater.format(rangeEndDay);
  final url = BackendConfig.getUri(
      'v1/bookings-within/$formattedStartDay/$formattedEndDay');
  kEvents.clear();
  events.clear();
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch bookings. Please try again later.');
  }

  final Map bookingsGroupedByDate = json.decode(response.body);
  bookingsGroupedByDate.forEach((key, value) async {
    List<BookingSummary> bookingEvents = [];
    for (final bookingSummaryEntry in value) {
      // bookings is a list of ServiceItem objects
      List<dynamic> bookingsForBookingSummary =
          bookingSummaryEntry['bookings'] ?? [];
      List<BookingEntry> bookingEntryList = [];

      // Fetch Booking details to get customerPhone and bookingRef
      final String rego = bookingSummaryEntry['rego'] ?? '';
      final bookingResponse =
          await http.get(BackendConfig.getUri('v1/booking-by-rego/$rego'));
      Map<String, dynamic>? bookingData;
      if (bookingResponse.statusCode == 200) {
        bookingData = json.decode(bookingResponse.body);
      }

      for (var serviceItem in bookingsForBookingSummary) {
        var bookingEntry = BookingEntry(
          bookingData?['customerPhone'] ?? '', // From Booking
          bookingData?['bookingReferenceNumber'] ?? '', // From Booking
          serviceItem['serviceName'] ?? '',
          serviceItem['serviceDurationMinutes']?.toString() ?? '',
          bookingData?['bookingDateTime'] ?? '',
        );
        bookingEntryList.add(bookingEntry);
      }

      var bookingSummary = BookingSummary(
        bookingSummaryEntry['rego'] ?? '',
        bookingEntryList,
      );
      bookingEvents.add(bookingSummary);
      events.add(bookingSummary);
    }
    DateTime bookingDate = DateTime.parse(key);
    DateTime dateToConsider =
        DateTime(bookingDate.year, bookingDate.month, bookingDate.day);
    kEvents[dateToConsider] = bookingEvents;
  });

  return events;
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);
