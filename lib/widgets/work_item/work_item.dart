// Packages
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

// Models
import '../../model/service_item.dart';
import '../../model/user.dart';
import '../../model/work_item.dart';

// Widgets
import '../../widgets/booking_list/booking_calendar_container.dart';
import '../../widgets/work_item/service_item_list.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/work_item/work_item_util.dart';

class WorkItemPage extends StatefulWidget {
  const WorkItemPage({
    super.key,
    required this.rego,
    required this.bookingEntries,
  });
  final List<BookingEntry> bookingEntries;
  final String rego;

  @override
  _WorkItemPageState createState() => _WorkItemPageState();
}

class _WorkItemPageState extends State<WorkItemPage> {
  List<ServiceOffer> serviceOffers = [];
  List<User> users = [];
  List<WorkItem> workItems = [];
  double totalCost = 0.0;
  DateTime? pickupTime;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      print(
          'Input bookingEntries: ${widget.bookingEntries.map((e) => "Phone: ${e.phone}, BookingRef: ${e.bookingRef}, ServiceItemIds: ${e.serviceItemIds}, BookingTime: ${e.bookingTime}").toList()}');
      final serviceOffersResult =
          await fetchServiceOffers(widget.bookingEntries);
      final usersResult = await loadUserData();
      final workItemsResult = await _fetchWorkItems();
      setState(() {
        serviceOffers = serviceOffersResult;
        users = usersResult;
        workItems = workItemsResult;
        _updateCostAndPickupTime(workItems);
      });
    } catch (e) {
      print('Error fetching data in WorkItemPage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<List<WorkItem>> _fetchWorkItems() async {
    final url = BackendConfig.getUri('v1/workitems');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final workItems = data
          .map<WorkItem>((json) => WorkItem(
                id: json['id'] ?? -1,
                assignedUserName: json['userDto']?['name'] ?? 'Unassigned',
                serviceName: json['serviceItemDto']?['serviceName'] ?? '',
                duration:
                    json['serviceItemDto']?['serviceDurationMinutes'] ?? 0,
                rego: json['serviceVehicleDto']?['rego'] ?? '',
                cost:
                    (json['serviceItemDto']?['servicePrice'] ?? 0.0).toDouble(),
                workItemStatus: json['workItemStatus'] ?? 'PENDING',
                startedDateTime: json['startTime']?.toString() ?? '',
                uniqueBookingRefIdentifier:
                    json['uniqueBookingRefIdentifier'] ?? '',
              ))
          .where((wi) {
        final matchesRego = wi.rego == widget.rego;
        final matchesBookingRef = widget.bookingEntries.any((entry) =>
            entry.bookingRef.trim().toUpperCase() ==
            wi.uniqueBookingRefIdentifier.trim().toUpperCase());
        print(
            'WorkItem: ${wi.serviceName}, Rego: ${wi.rego}, Status: ${wi.workItemStatus}, BookingRef: ${wi.uniqueBookingRefIdentifier}, Matches: Rego=$matchesRego, BookingRef=$matchesBookingRef');
        return matchesRego && matchesBookingRef;
      }).toList();
      print(
          'Fetched workItems in WorkItemPage: ${workItems.map((wi) => "${wi.serviceName}: \$${wi.cost}, Rego: ${wi.rego}, BookingRef: ${wi.uniqueBookingRefIdentifier}, Status: ${wi.workItemStatus}").toList()}');
      return workItems;
    } else {
      throw Exception(
          'Failed to fetch work items. Status code: ${response.statusCode}');
    }
  }

  Future<List<User>> loadUserData() async {
    final url = BackendConfig.getUri('config/users');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List userList = json.decode(response.body);
      final users = userList
          .map((entry) =>
              User(id: entry['id'], name: entry['name'], role: entry['role']))
          .toList();
      print('Fetched users: ${users.map((u) => u.name).toList()}');
      return users;
    } else {
      throw Exception(
          'Failed to fetch users. Status code: ${response.statusCode}');
    }
  }

  Future<List<ServiceOffer>> fetchServiceOffers(
      List<BookingEntry> bookingEntries) async {
    List<dynamic> serviceOfferIds = bookingEntries
        .map((entry) => entry.serviceItemIds)
        .expand((listEntry) => listEntry)
        .toList();
    print('Fetching service offers for IDs: $serviceOfferIds');
    final url = BackendConfig.getUri('config/service-offers');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(serviceOfferIds),
    );

    if (response.statusCode == 200) {
      final List serviceOffersData = json.decode(response.body);
      final serviceOffers = <ServiceOffer>[];
      for (var bookingEntry in bookingEntries) {
        for (var entry in serviceOffersData) {
          if (bookingEntry.serviceItemIds.contains(entry['id'].toString())) {
            serviceOffers.add(ServiceOffer(
              id: entry['id'],
              name: entry['serviceName'],
              bookingRef: bookingEntry.bookingRef,
            ));
          }
        }
      }
      print(
          'Fetched service offers: ${serviceOffers.map((so) => "${so.name}, BookingRef: ${so.bookingRef}").toList()}');
      return serviceOffers;
    } else {
      print(
          'Failed to fetch service offers. Status code: ${response.statusCode}');
      return [];
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    print('Attempting to call: $phoneNumber');
    var status = await Permission.phone.request();
    if (status.isGranted) {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
        print('Call launched');
      } else {
        print('Cannot launch $launchUri');
        throw 'Could not launch $launchUri';
      }
    } else {
      print('Permission denied');
      throw 'Phone call permission denied';
    }
  }

  void _updateCostAndPickupTime(List<WorkItem> workItems) {
    setState(() {
      totalCost = workItems
          .where((wi) => wi.rego == widget.rego)
          .fold(0.0, (sum, wi) => sum + wi.cost);
      print('Filtered by rego ${widget.rego}, Total Cost: $totalCost');
      pickupTime = _calculatePickupFromWorkItems(workItems);
    });
  }

  DateTime? _calculatePickupFromWorkItems(List<WorkItem> workItems) {
    final workItemsByRego =
        workItems.where((wi) => wi.rego == widget.rego).toList();
    if (workItemsByRego.isEmpty) return null;
    final lastWorkItem = workItemsByRego.last;
    DateTime endTime = lastWorkItem.startedDateTime.isNotEmpty
        ? DateTime.parse(lastWorkItem.startedDateTime)
        : DateTime.now();
    final totalDuration =
        workItemsByRego.fold(0, (sum, wi) => sum + wi.duration);
    return endTime.add(Duration(minutes: totalDuration));
  }

  Future<void> _updatePickupTime(String bookingRef, DateTime pickupTime) async {
    final url = BackendConfig.getUri('v1/booking/$bookingRef/pickup');
    final formattedPickupTime =
        DateFormat('yyyy-MM-dd HH:mm').format(pickupTime);
    print(
        'Updating pickup time for BookingRef: $bookingRef to $formattedPickupTime');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'pickupTime': formattedPickupTime}),
      );
      if (response.statusCode == 200) {
        print('Pickup time updated successfully for BookingRef: $bookingRef');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pickup time updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        print(
            'Failed to update pickup time. Status code: ${response.statusCode}');
        throw Exception(
            'Failed to update pickup time. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating pickup time: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating pickup time: $e')),
        );
      }
    }
  }

  Future<void> _selectPickupDateTime(BuildContext context) async {
    final initialDate = pickupTime ?? DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (pickedTime != null) {
        setState(() {
          pickupTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
      // if (pickedTime != null && mounted) {
      //   final newPickupTime = DateTime(
      //     pickedDate.year,
      //     pickedDate.month,
      //     pickedDate.day,
      //     pickedTime.hour,
      //     pickedTime.minute,
      //   );
      //   setState(() {
      //     pickupTime = newPickupTime;
      //   });
      //   // Update pickup time for all booking entries
      //   for (var entry in widget.bookingEntries) {
      //     await _updatePickupTime(entry.bookingRef, newPickupTime);
      //   }
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dropOffTime = DateFormat('HH:mm')
        .format(DateTime.parse(widget.bookingEntries[0].bookingTime));
    final dropOffDate = DateTime.parse(widget.bookingEntries[0].bookingTime)
        .toString()
        .split(' ')[0];

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Booking')),
      body: ResponsiveWorkItemUtils.isWideScreen(context)
          ? Padding(
              padding: ResponsiveWorkItemUtils.getSectionPadding(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width *
                        ResponsiveWorkItemUtils.getDetailsWidthRatio(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: IconButton(
                            onPressed: () =>
                                _makePhoneCall(widget.bookingEntries[0].phone),
                            icon: const Icon(Icons.phone),
                          ),
                        ),
                        ListTile(
                          title: const Text('Rego'),
                          subtitle: Text(
                              '${widget.rego} - Total Cost: \$${totalCost.toStringAsFixed(2)}'),
                        ),
                        ListTile(
                          title: const Text('Drop off'),
                          subtitle: Text('$dropOffDate $dropOffTime'),
                        ),
                        ListTile(
                          title: const Text('Pickup'),
                          subtitle: Row(
                            children: [
                              Text(pickupTime != null
                                  ? DateFormat('yyyy-MM-dd HH:mm')
                                      .format(pickupTime!)
                                  : 'Not set'),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => _selectPickupDateTime(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ServiceItemList(
                      serviceOffers: serviceOffers,
                      selectableUsers: users,
                      workItems: workItems,
                      workItemId: -1,
                      rego: widget.rego,
                      bookingEntries: widget.bookingEntries,
                      onWorkItemStarted:
                          (int workItemId, List<WorkItem> updatedWorkItems) {
                        setState(() {
                          workItems = updatedWorkItems;
                          _updateCostAndPickupTime(updatedWorkItems);
                        });
                      },
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                ListTile(
                  leading: IconButton(
                    onPressed: () =>
                        _makePhoneCall(widget.bookingEntries[0].phone),
                    icon: const Icon(Icons.phone),
                  ),
                ),
                ListTile(
                  title: const Text('Rego'),
                  subtitle: Text(
                      '${widget.rego} - Total Cost: \$${totalCost.toStringAsFixed(2)}'),
                ),
                ListTile(
                  title: const Text('Drop off'),
                  subtitle: Text('$dropOffDate $dropOffTime'),
                ),
                ListTile(
                  title: const Text('Pickup'),
                  subtitle: Row(
                    children: [
                      Text(pickupTime != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(pickupTime!)
                          : 'Not set'),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _selectPickupDateTime(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ServiceItemList(
                    serviceOffers: serviceOffers,
                    selectableUsers: users,
                    workItems: workItems,
                    workItemId: -1,
                    rego: widget.rego,
                    bookingEntries: widget.bookingEntries,
                    onWorkItemStarted:
                        (int workItemId, List<WorkItem> updatedWorkItems) {
                      setState(() {
                        workItems = updatedWorkItems;
                        _updateCostAndPickupTime(updatedWorkItems);
                      });
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
