// Packages
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Models
import '../../model/service_item.dart';
import '../../model/user.dart';

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
  // ignore: library_private_types_in_public_api
  _WorkItemPageState createState() => _WorkItemPageState();
}

class _WorkItemPageState extends State<WorkItemPage> {
  List<ServiceOffer> serviceOffers = [];
  List<User> users = [];
  @override
  void initState() {
    super.initState();
    fetchServiceOffers(widget.bookingEntries).then((onValue) {
      setState(() {
        serviceOffers = onValue;
      });
    });
    loadUserData().then((onValue) {
      setState(() {
        users = onValue;
      });
    });
  }

  Future<List<User>> loadUserData() async {
    final url = BackendConfig.getUri('config/users');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users. Please try again later.');
    }
    final List userList = json.decode(response.body);
    List<User> users = [];
    for (final entry in userList) {
      users
          .add(User(id: entry['id'], name: entry['name'], role: entry['role']));
    }
    return users;
  }

  Future<List<ServiceOffer>> fetchServiceOffers(
      List<BookingEntry> bookingEntries) async {
    List<dynamic> serviceOfferIds = bookingEntries
        .map((entry) {
          return entry.serviceItemIds;
        })
        .expand((listEntry) => listEntry)
        .toList();
    final url = BackendConfig.getUri('config/service-offers');
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(serviceOfferIds));

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch servcie offers. Please try again later.');
    }
    final List serviceOffersData = json.decode(response.body);
    List<ServiceOffer> serviceOffers = [];

    for (BookingEntry bookingEntry in bookingEntries) {
      List<dynamic> serviceItemIds = bookingEntry.serviceItemIds;
      for (final entry in serviceOffersData) {
        if (serviceItemIds.contains(entry['id'].toString())) {
          serviceOffers.add(ServiceOffer(
              id: entry['id'],
              name: entry['serviceName'],
              bookingRef: bookingEntry.bookingRef));
        }
      }
    }
    return serviceOffers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Manage booking')),
        body: ResponsiveWorkItemUtils.isWideScreen(context)
            ? Padding(
                padding: ResponsiveWorkItemUtils.getSectionPadding(context),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Details Section (40% width)
                    SizedBox(
                      width: MediaQuery.of(context).size.width *
                          ResponsiveWorkItemUtils.getDetailsWidthRatio(context),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                              leading: IconButton(
                                  onPressed: () => {},
                                  icon: const Icon(Icons.phone))),
                          ListTile(
                            title: const Text('Rego'),
                            subtitle: Text(widget.rego),
                          ),
                          ListTile(
                            title: const Text('Drop off'),
                            subtitle: Text(
                                getBookingStartDateTime(widget.bookingEntries)),
                          ),
                          const ListTile(
                            title: Text('Pickup'),
                            subtitle: Text('Future date'),
                          ),
                        ],
                      ),
                    ),
                    // Service Item List Section (60% width)
                    Expanded(
                      child: ServiceItemList(
                        serviceOffers: serviceOffers,
                        slectableUsers: users,
                        workItemId: -1,
                      ),
                    ),
                  ],
                ),
              )
            : Column(children: [
                ListTile(
                    leading: IconButton(
                        onPressed: () => {}, icon: const Icon(Icons.phone))),
                ListTile(
                  title: const Text('Rego'),
                  subtitle: Text(widget.rego),
                ),
                ListTile(
                  title: const Text('Drop off'),
                  subtitle:
                      Text(getBookingStartDateTime(widget.bookingEntries)),
                ),
                const ListTile(
                  title: Text('Pickup'),
                  subtitle: Text('Future date'),
                ),
                Expanded(
                    child: ServiceItemList(
                  serviceOffers: serviceOffers,
                  slectableUsers: users,
                  workItemId: -1,
                ))
              ]));
  }

  String getBookingStartDateTime(List<BookingEntry> bookingEntries) {
    return bookingEntries[0].bookingTime;
  }
}
