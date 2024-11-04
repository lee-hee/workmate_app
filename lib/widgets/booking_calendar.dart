import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:table_calendar/table_calendar.dart';
import 'package:workmate_app/widgets/booking_calendar_container.dart';
import 'package:http/http.dart' as http;

class BookingsCalendar extends StatefulWidget {
  const BookingsCalendar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookingsCalendarState createState() => _BookingsCalendarState();
}

class _BookingsCalendarState extends State<BookingsCalendar> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOff; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  final List<Event> eventsForDate = [];

  final kEvents = LinkedHashMap<DateTime, List<Event>>(
    equals: isSameDay,
    hashCode: getHashCode,
  )..addAll(<DateTime, List<Event>>{});

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _getEventsForMonth();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _getEventsForMonth() async {
    final DateFormat serverFormater = DateFormat('yyyy-MM-dd');
    DateTime startDayOfMonth =
        new DateTime(_focusedDay.year, _focusedDay.month, 1);
    DateTime lastDayOfMonth =
        new DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
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

    // return kEvents[day] ?? [];
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return kEvents[day] ?? [];
  }

  List<Event> _getEventsForRange(DateTime start, DateTime end) {
    // Implementation example
    final days = daysInRange(start, end);

    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    // `start` or `end` could be null
    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else if (end != null) {
      _selectedEvents.value = _getEventsForDay(end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              // Use `CalendarStyle` to customize the UI
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onRangeSelected: _onRangeSelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        onTap: () => print('${value[index]}'),
                        leading: const Icon(Icons.car_repair,
                            color: Colors.blueAccent, size: 24.0),
                        title: Text('Rego: ${value[index].rego}'),
                        trailing: const Icon(Icons.phone,
                            color: Colors.blueAccent, size: 24.0),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
