import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//Config
import '../../config/backend_config.dart';

class Event {
  final String rego;
  final String phone;
  final String customerName;
  final String bookingRef;
  final String bookingTime;
  final List<dynamic> serviceItemIds;

  const Event(this.rego, this.phone, this.customerName, this.bookingRef,
      this.serviceItemIds, this.bookingTime);

  @override
  String toString() => rego + phone + customerName + bookingRef;
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
  final String customerName;
  final String bookingRef;
  final String bookingTime;
  final List<dynamic> serviceItemIds;

  const BookingEntry(this.phone, this.customerName, this.bookingRef,
      this.serviceItemIds, this.bookingTime);
}

final DateFormat serverFormater = DateFormat('yyyy-MM-dd');

Map<DateTime, List<BookingSummary>> kEvents =
    <DateTime, List<BookingSummary>>{};
List<BookingSummary> events = [];

Future fetchBookingsForFocusedMonth(DateTime focusedDay) async {
  var rangeStartDay = DateTime(focusedDay.year, focusedDay.month, 1);
  var rangeEndDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
  final String formattedStartDay = serverFormater.format(rangeStartDay);
  final String formattedEndtDay = serverFormater.format(rangeEndDay);
  final url = BackendConfig.getUri(
      'v1/bookings-within/$formattedStartDay/$formattedEndtDay');
  kEvents.clear();
  events.clear();
  final response = await http.get(url);

  if (response.statusCode != 200) {
    print(
        'Failed to fetch bookings. Status code: ${response.statusCode}, Body: ${response.body}');
    throw Exception('Failed to fetch bookings. Please try again later.');
  }
  final Map bookingsGroupedByDate = json.decode(response.body);
  print('Bookings response: $bookingsGroupedByDate');
  bookingsGroupedByDate.forEach((key, value) {
    List<BookingSummary> bookingEvents = [];
    for (final bookingSummaryEntry in value) {
      List<dynamic> bookingsForBookingSummary = bookingSummaryEntry['bookings'];
      List<BookingEntry> bookingEntryList = [];
      for (var booking in bookingsForBookingSummary) {
        print('Processing booking: $booking');
        var bookingEntry = BookingEntry(
            booking['customerPhone'] ?? '',
            booking['customerName'] ?? 'Unknown',
            booking['bookingReferenceNumber'] ?? '',
            booking['serviceItemIds'] ?? [],
            booking['bookingDateTime'] ?? '');
        bookingEntryList.add(bookingEntry);
      }

      var bookingSummary =
          BookingSummary(bookingSummaryEntry['rego'] ?? '', bookingEntryList);
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
