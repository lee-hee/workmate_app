import 'dart:collection';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

class Event {
  final String rego;
  final String ownerPhone;

  const Event({required this.rego, required this.ownerPhone});

  @override
  String toString() => 'Rego:$rego Phone:$ownerPhone';
}

// final kEvents = LinkedHashMap<DateTime, List<Event>>(
//   equals: isSameDay,
//   hashCode: getHashCode,
// )..addAll(_kEventSource);

// final _kEventSource = Map.fromIterable(List.generate(50, (index) => index),
//     key: (item) => DateTime.utc(kFirstDay.year, kFirstDay.month, item * 5),
//     value: (item) => List.generate(
//         item % 4 + 1, (index) => Event(rego: '2rtyg', ownerPhone: '5678')))
//   ..addAll({
//     kToday: [const Event(rego: '2rtyg', ownerPhone: '5678')],
//   });

void _getEventsForMonth(DateTime focusDay) async {
  final DateFormat serverFormater = DateFormat('yyyy-MM-dd');
  DateTime startDayOfMonth = new DateTime(focusDay.year, focusDay.month, 1);
  DateTime lastDayOfMonth = new DateTime(focusDay.year, focusDay.month + 1, 0);
  final String formattedStartDay = serverFormater.format(startDayOfMonth);
  final String formattedEndtDay = serverFormater.format(lastDayOfMonth);

  final url = Uri.http('192.168.0.141:8080',
      'v1/bookings-within/$formattedStartDay/$formattedEndtDay');

  final response = await http.get(url);
  print('>>>>>>>> $response');

  if (response.statusCode >= 400) {
    throw Exception('Failed to fetch bookings. Please try again later.');
  }

  final List<dynamic> listData = json.decode(response.body);

  // for (final item in listData) {
  //   eventsForDate.add(Event(
  //     ownerPhone: item['customerPhone'],
  //     rego: item['rego'],
  //   ));
  // }
  // setState(() {
  //   _bookings = loadedItems;
  //   _isLoading = false;
  // });

  //return kEvents[day] ?? [];
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
