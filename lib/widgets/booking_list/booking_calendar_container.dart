// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Example event class.
class Event {
  final String rego;
  final String phone;
  final String bookingRef;
  final String bookingTime;
  final List<String> serviceItemIds;
  final String serviceName;
  final String servicDuration;

  const Event(this.rego, this.phone, this.bookingRef, this.serviceItemIds,
      this.serviceName, this.servicDuration, this.bookingTime);

  @override
  String toString() => rego + phone + bookingRef;
}

final DateFormat serverFormater = DateFormat('yyyy-MM-dd');

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
Map<DateTime, List<Event>> kEvents = <DateTime, List<Event>>{};
List<Event> events = [];

Future fetchBookingsForFocusedMonth(DateTime focusedDay) async {
  var rangeStartDay = DateTime(focusedDay.year, focusedDay.month, 1);
  var rangeEndDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
  final String formattedStartDay = serverFormater.format(rangeStartDay);
  final String formattedEndtDay = serverFormater.format(rangeEndDay);
  final url = Uri.http('localhost:8080',
      'v1/bookings-within/$formattedStartDay/$formattedEndtDay');
  kEvents.clear();
  events.clear();
  final response = await http.get(url);

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch bookings. Please try again later.');
  }
  final Map bookingsGroupedByDate = json.decode(response.body);
  bookingsGroupedByDate.forEach((key, value) {
    List<Event> bookingEvents = [];
    for (final booking in value) {
      var event = Event(
        booking['rego'],
        booking['customerPhone'],
        booking['bookingReferenceNumber'],
        booking['serviceItemIds'],
        booking['serviceName'],
        booking['serviceDuration'],
        booking['bookingDateTime'],
      );
      bookingEvents.add(event);
      events.add(event);
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
