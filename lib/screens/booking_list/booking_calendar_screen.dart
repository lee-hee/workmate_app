// Packages
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// Widgets
import '../../widgets/booking_list/booked_items.dart';
import '../../widgets/booking_list/booking_calendar_container.dart';

// Utils
import '../../utils/responsive_utils/booking_list/calender_list_util.dart';

class BookingCalenderScreen extends StatefulWidget {
  const BookingCalenderScreen({super.key});

  @override
  _BookingCalenderState createState() => _BookingCalenderState();
}

class _BookingCalenderState extends State<BookingCalenderScreen> {
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
    }).catchError((e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching bookings: $e');
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
    setState(() {
      _isLoading = true;
    });
    fetchBookingsForFocusedMonth(_focusedDay.value).then((events) {
      setState(() {
        _selectedEvents.value = events;
        _isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching bookings for month: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings Calendar'),
      ),
      body: ResponsiveBookingListUtils.isWideScreen(context)
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width *
                      ResponsiveBookingListUtils.getCalendarWidthRatioNew(
                          context),
                  child: Padding(
                    padding:
                        ResponsiveBookingListUtils.getSectionPadding(context),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ValueListenableBuilder<DateTime>(
                            valueListenable: _focusedDay,
                            builder: (context, value, _) {
                              return _CalendarHeader(
                                focusedDay: value,
                                clearButtonVisible: canClearSelection,
                                onTodayButtonTap: () {
                                  setState(
                                      () => _focusedDay.value = DateTime.now());
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
                            selectedDayPredicate: (day) =>
                                _selectedDays.contains(day),
                            rangeStartDay: _rangeStart,
                            rangeEndDay: _rangeEnd,
                            calendarFormat: _calendarFormat,
                            rangeSelectionMode: _rangeSelectionMode,
                            eventLoader: _getEventsForDay,
                            onDaySelected: _onDaySelected,
                            onRangeSelected: _onRangeSelected,
                            onCalendarCreated: (controller) =>
                                _pageController = controller,
                            onPageChanged: (focusedDay) =>
                                _onPageChanged(focusedDay),
                            onFormatChanged: (format) {
                              if (_calendarFormat != format) {
                                setState(() => _calendarFormat = format);
                              }
                            },
                            calendarStyle: const CalendarStyle(
                              markersAlignment: Alignment.bottomRight,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, day, events) =>
                                  events.isNotEmpty
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: const BoxDecoration(
                                            color: Colors.lightBlue,
                                          ),
                                          child: Text(
                                            '${events.length}',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        )
                                      : null,
                            ),
                          ),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        ResponsiveBookingListUtils.getSectionPadding(context),
                    child: ValueListenableBuilder<List<BookingSummary>>(
                      valueListenable: _selectedEvents,
                      builder: (context, value, _) {
                        if (value.isEmpty && !_isLoading) {
                          return const Center(
                            child: Text(
                              'No bookings available for selected date',
                              style: TextStyle(fontSize: 16.0),
                            ),
                          );
                        }
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
                ),
              ],
            )
          : Column(
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
                  onDaySelected: _onDaySelected,
                  onRangeSelected: _onRangeSelected,
                  onCalendarCreated: (controller) =>
                      _pageController = controller,
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
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: ValueListenableBuilder<List<BookingSummary>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      if (value.isEmpty && !_isLoading) {
                        return const Center(
                          child: Text(
                            'No bookings available for selected date',
                            style: TextStyle(fontSize: 16.0),
                          ),
                        );
                      }
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
            ),
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
      padding: ResponsiveBookingListUtils.getHeaderPadding(context),
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
