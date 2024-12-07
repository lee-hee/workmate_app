import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:workmate_app/model/booking.dart';

class BookingList extends StatefulWidget {
  const BookingList({super.key});

  @override
  State<BookingList> createState() => _BookingListState();
}

class _BookingListState extends State<BookingList> {
  List<Booking> _bookings = [];
  late Future<List<Booking>> _loadedItems;
  String? _error;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<Booking>> _loadItems() async {
    final now = DateTime.now();
    final DateFormat serverFormater = DateFormat('yyyy-MM-dd');
    final String formatted = serverFormater.format(now);

    final url = Uri.http('192.168.0.141:8080', 'v1/bookings/$formatted');

    final response = await http.get(url);
    print('>>>>>>>> $response');

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch bookings. Please try again later.');
    }

    if (response.body == 'null') {
      return [];
    }

    final List<dynamic> listData = json.decode(response.body);
    final List<Booking> loadedItems = [];
    for (final item in listData) {
      loadedItems.add(Booking(
          customerPhone: item['customerPhone'],
          bookingReferenceNumber: item['bookingReferenceNumber'],
          rego: item['rego'],
          serviceItemId: item['serviceItemId'],
          bookingTime: item['bookingDateTime']));
    }
    setState(() {
      _bookings = loadedItems;
      _isLoading = false;
    });
    return loadedItems;
  }

  void _removeItem(Booking item) {}
  Future<void> _pullRefresh() async {
    List<Booking> newBookings = await _loadItems();
    setState(() {
      _bookings = newBookings;
    });
    // why use freshNumbers var? https://stackoverflow.com/a/52992836/2301224
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(child: Text('No items added yet.'));

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        // actions: [
        //   IconButton(
        //     onPressed: _addItem,
        //     icon: const Icon(Icons.add),
        //   ),
        // ],
      ),
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: ListView.builder(
          itemCount: _bookings.length,
          itemBuilder: (ctx, index) => Dismissible(
            onDismissed: (direction) {
              _removeItem(_bookings[index]);
            },
            key: ValueKey(_bookings[index].bookingReferenceNumber),
            child: ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                    color: Color.fromARGB(255, 80, 73, 73), width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
              leading: const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 24.0,
                semanticLabel: 'Text to announce in accessibility modes',
              ),
              title: Text(_bookings[index].rego),
              subtitle: Text(
                  'Booking ref: ${_bookings[index].bookingReferenceNumber} Customer phone: ${_bookings[index].customerPhone}'
                  'Booked time: ${_bookings[index].bookingTime}'),
            ),
          ),
        ),
      ),
    );
  }
}
