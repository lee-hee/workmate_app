// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:workmate_app/model/booking.dart';
import 'package:workmate_app/widgets/booking_list/booking_item.dart';
import 'package:workmate_app/widgets/booking_list/booking_calendar_container.dart';
import 'package:workmate_app/widgets/new_booking/new_booking.dart';

class BookingCalender extends StatefulWidget {
  const BookingCalender({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookingCalenderState createState() => _BookingCalenderState();
}

class _BookingCalenderState extends State<BookingCalender> {
  late final ValueNotifier<List<BookingSummary>> _selectedEvents;
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  final Set<DateTime> _selectedDays = LinkedHashSet<DateTime>(
    equals: isSameDay,
    hashCode: getHashCode,
  );

  var _isLoading = true;

  late PageController _pageController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _selectedDays.add(_focusedDay.value);
    _selectedEvents = ValueNotifier(events);
    fetchBookingsForFocusedMonth(_focusedDay.value).then((events) {
      setState(() {
        _selectedEvents.value = events;
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _focusedDay.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  bool get canClearSelection =>
      _selectedDays.isNotEmpty || _rangeStart != null || _rangeEnd != null;

  List<BookingSummary> _getEventsForDay(DateTime day) {
    DateTime dateToConsider = DateTime(day.year, day.month, day.day);
    var list = kEvents[dateToConsider] ?? [];
    return list;
  }

  List<BookingSummary> _getEventsForDays(Iterable<DateTime> days) {
    return [
      for (final d in days) ..._getEventsForDay(d),
    ];
  }

  List<BookingSummary> _getEventsForRange(DateTime start, DateTime end) {
    final days = daysInRange(start, end);
    return _getEventsForDays(days);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDays.clear();
      _selectedDays.add(selectedDay);
      _focusedDay.value = selectedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });

    _selectedEvents.value = _getEventsForDays(_selectedDays);
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDays.clear();
      _selectedDays.add(focusedDay);
      _focusedDay.value = focusedDay;
      _rangeStart = null;
      _rangeEnd = null;
      _rangeSelectionMode = RangeSelectionMode.toggledOff;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay.value = focusedDay;
    fetchBookingsForFocusedMonth(_focusedDay.value).then((events) {
      setState(() {
        _selectedEvents.value = events;
        _isLoading = false;
      });
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<Booking>(
      MaterialPageRoute(
        builder: (ctx) => const NewBooking(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('Searching for bookings .... '));
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = Column(
        children: [
          ValueListenableBuilder<DateTime>(
            valueListenable: _focusedDay,
            builder: (context, value, _) {
              return _CalendarHeader(
                focusedDay: value,
                clearButtonVisible: canClearSelection,
                onTodayButtonTap: () {
                  setState(() => _focusedDay.value = DateTime.now());
                },
                onClearButtonTap: () {
                  setState(() {
                    _rangeStart = null;
                    _rangeEnd = null;
                    _selectedDays.clear();
                    _selectedEvents.value = [];
                  });
                },
                onLeftArrowTap: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                onRightArrowTap: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
              );
            },
          ),
          TableCalendar<BookingSummary>(
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: _focusedDay.value,
              headerVisible: true,
              selectedDayPredicate: (day) => _selectedDays.contains(day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarFormat: _calendarFormat,
              rangeSelectionMode: _rangeSelectionMode,
              eventLoader: _getEventsForDay,
              // holidayPredicate: (day) {
              //   // Every 20th day of the month will be treated as a holiday
              //   return day.day == 20;
              // },
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              onCalendarCreated: (controller) => _pageController = controller,
              onPageChanged: (focusedDay) => _onPageChanged(focusedDay),
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              calendarStyle: const CalendarStyle(
                markersAlignment: Alignment.bottomRight,
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) => events.isNotEmpty
                    ? Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.lightBlue,
                        ),
                        child: Text(
                          '${events.length}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : null,
              )),
          const SizedBox(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<BookingSummary>>(
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
                      child: BookingListItem(
                        rego: value[index].rego,
                        bookingEntries: value[index].bookingEntries,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings calender'), actions: [
        IconButton(onPressed: _addItem, icon: const Icon(Icons.car_crash)),
      ]),
      body: content,
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final VoidCallback onLeftArrowTap;
  final VoidCallback onRightArrowTap;
  final VoidCallback onTodayButtonTap;
  final VoidCallback onClearButtonTap;
  final bool clearButtonVisible;

  const _CalendarHeader({
    required this.focusedDay,
    required this.onLeftArrowTap,
    required this.onRightArrowTap,
    required this.onTodayButtonTap,
    required this.onClearButtonTap,
    required this.clearButtonVisible,
  });

  @override
  Widget build(BuildContext context) {
    final headerText = DateFormat.yMMM().format(focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16.0),
          SizedBox(
            width: 120.0,
            child: Text(
              headerText,
              style: const TextStyle(fontSize: 26.0),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, size: 20.0),
            visualDensity: VisualDensity.compact,
            onPressed: onTodayButtonTap,
          ),
          if (clearButtonVisible)
            IconButton(
              icon: const Icon(Icons.clear, size: 20.0),
              visualDensity: VisualDensity.compact,
              onPressed: onClearButtonTap,
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onLeftArrowTap,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onRightArrowTap,
          ),
        ],
      ),
    );
  }
}
