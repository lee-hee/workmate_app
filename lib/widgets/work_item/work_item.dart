// // TO DO: Check the url_launcher plugin is initialized in android/app/src/main/kotlin/MainActivity.java
// // Ex:
// // import io.flutter.embedding.android.FlutterActivity
// // import io.flutter.embedding.engine.FlutterEngine
// // import io.flutter.plugins.GeneratedPluginRegistrant

// // class MainActivity: FlutterActivity() {
// //     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
// //         GeneratedPluginRegistrant.registerWith(flutterEngine)
// //     }
// // }

// // Packages
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:url_launcher/url_launcher.dart';

// // Models
// import '../../model/service_item.dart';
// import '../../model/user.dart';
// import '../../model/work_item.dart';

// // Widgets
// import '../../widgets/booking_list/booking_calendar_container.dart';
// import '../../widgets/work_item/service_item_list.dart';

// // Config
// import '../../config/backend_config.dart';

// // Utils
// import '../../utils/responsive_utils/work_item/work_item_util.dart';

// class WorkItemPage extends StatefulWidget {
//   const WorkItemPage({
//     super.key,
//     required this.rego,
//     required this.bookingEntries,
//   });
//   final List<BookingEntry> bookingEntries;
//   final String rego;

//   @override
//   // ignore: library_private_types_in_public_api
//   _WorkItemPageState createState() => _WorkItemPageState();
// }

// class _WorkItemPageState extends State<WorkItemPage> {
//   List<ServiceOffer> serviceOffers = [];
//   List<User> users = [];
//   double totalCost = 0.0; // Total cost
//   DateTime? pickupTime; // For editable pickup

//   @override
//   void initState() {
//     super.initState();
//     fetchServiceOffers(widget.bookingEntries).then((onValue) {
//       setState(() {
//         serviceOffers = onValue;
//       });
//     });
//     loadUserData().then((onValue) {
//       setState(() {
//         users = onValue;
//       });
//     });
//     // _fetchWorkItems(); // Initial fetch
//   }

//   // Fetch work items from backend
//   // Future<void> _fetchWorkItems() async {
//   //   final url = BackendConfig.getUri('v1/workitems');
//   //   final response = await http.get(url);
//   //   if (response.statusCode == 200) {
//   //     final List data = json.decode(response.body);
//   //     final workItems = data
//   //         .map<WorkItem>((json) => WorkItem(
//   //               id: json['id'] ?? -1,
//   //               assignedUserName: json['userDto']?['name'] ?? 'Unassigned',
//   //               serviceName: json['serviceItemDto']?['serviceName'] ?? '',
//   //               duration:
//   //                   json['serviceItemDto']?['serviceDurationMinutes'] ?? 0,
//   //               rego: json['serviceVehicleDto']?['rego'] ?? '',
//   //               cost:
//   //                   (json['serviceItemDto']?['servicePrice'] ?? 0.0).toDouble(),
//   //               workItemStatus: json['workItemStatus'] ?? 'ASSIGNED',
//   //               startedDateTime: json['startTime']?.toString() ?? '',
//   //             ))
//   //         .where((wi) => wi.rego == widget.rego || widget.rego.isEmpty)
//   //         .toList();
//   //     _updateCostAndPickupTime(workItems);
//   //   } else {
//   //     throw Exception('Failed to fetch work items. Please try again later.');
//   //   }
//   // }

//   Future<List<User>> loadUserData() async {
//     final url = BackendConfig.getUri('config/users');
//     final response = await http.get(url);
//     if (response.statusCode != 200) {
//       throw Exception('Failed to fetch users. Please try again later.');
//     }
//     final List userList = json.decode(response.body);
//     List<User> users = [];
//     for (final entry in userList) {
//       users
//           .add(User(id: entry['id'], name: entry['name'], role: entry['role']));
//     }
//     return users;
//   }

//   Future<List<ServiceOffer>> fetchServiceOffers(
//       List<BookingEntry> bookingEntries) async {
//     List<dynamic> serviceOfferIds = bookingEntries
//         .map((entry) {
//           return entry.serviceItemIds;
//         })
//         .expand((listEntry) => listEntry)
//         .toList();
//     final url = BackendConfig.getUri('config/service-offers');
//     final response = await http.post(url,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(serviceOfferIds));

//     if (response.statusCode != 200) {
//       throw Exception(
//           'Failed to fetch servcie offers. Please try again later.');
//     }
//     final List serviceOffersData = json.decode(response.body);
//     List<ServiceOffer> serviceOffers = [];

//     for (BookingEntry bookingEntry in bookingEntries) {
//       List<dynamic> serviceItemIds = bookingEntry.serviceItemIds;
//       for (final entry in serviceOffersData) {
//         if (serviceItemIds.contains(entry['id'].toString())) {
//           serviceOffers.add(ServiceOffer(
//             id: entry['id'],
//             name: entry['serviceName'],
//             bookingRef: bookingEntry.bookingRef,
//           ));
//         }
//       }
//     }
//     return serviceOffers;
//   }

//   //  Method to make a phone call
//   Future<void> _makePhoneCall(String phoneNumber) async {
//     // Request phone call permission
//     print('Attempting to call: $phoneNumber');
//     var status = await Permission.phone.request();
//     if (status.isGranted) {
//       final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
//       print('URI: $launchUri');
//       if (await canLaunchUrl(launchUri)) {
//         await launchUrl(launchUri);
//         print('Call launched');
//       } else {
//         print('Cannot launch $launchUri');
//         throw 'Could not launch $launchUri';
//       }
//     } else {
//       print('Permission denied');
//       throw 'Phone call permission denied';
//     }
//   }

//   // Update total cost and pickup time based on work items
//   void _updateCostAndPickupTime(List<WorkItem> workItems) {
//     setState(() {
//       // totalCost = workItems.fold(0.0, (sum, wi) => sum + wi.cost);
//       totalCost = workItems
//           .where((wi) => wi.rego == widget.rego)
//           .fold(0.0, (sum, wi) => sum + wi.cost);
//       print('Filtered by rego ${widget.rego}, Total Cost: $totalCost');
//       pickupTime = _calculatePickupFromWorkItems(workItems);
//     });
//   }

//   // Calculate pickup time
//   DateTime? _calculatePickupFromWorkItems(List<WorkItem> workItems) {
//     // Filter work items by Rego
//     final workItemsByRego =
//         workItems.where((wi) => wi.rego == widget.rego).toList();
//     if (workItemsByRego.isEmpty) return null;
//     final lastWorkItem = workItemsByRego.last;
//     // Parse start time; if empty, use current time
//     DateTime endTime = lastWorkItem.startedDateTime.isNotEmpty
//         ? DateTime.parse(lastWorkItem.startedDateTime)
//         : DateTime.now();
//     // Sum durations of all work items for specific Rego
//     final totalDuration =
//         workItemsByRego.fold(0, (sum, wi) => sum + wi.duration);
//     return endTime.add(Duration(minutes: totalDuration));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final dropOffTime = DateFormat('HH:mm').format(DateTime.parse(
//         widget.bookingEntries[0].bookingTime)); // Format to HH:MM
//     final dropOffDate = DateTime.parse(widget.bookingEntries[0].bookingTime)
//         .toString()
//         .split(' ')[0];

//     return Scaffold(
//         appBar: AppBar(title: const Text('Manage Booking')),
//         body: ResponsiveWorkItemUtils.isWideScreen(context)
//             ? Padding(
//                 padding: ResponsiveWorkItemUtils.getSectionPadding(context),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Booking Details Section (40% width)
//                     SizedBox(
//                       width: MediaQuery.of(context).size.width *
//                           ResponsiveWorkItemUtils.getDetailsWidthRatio(context),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ListTile(
//                               leading: IconButton(
//                                   onPressed: () => _makePhoneCall(widget
//                                       .bookingEntries[0]
//                                       .phone), // Click to call
//                                   icon: const Icon(Icons.phone))),
//                           ListTile(
//                             title: const Text('Rego'),
//                             // subtitle: Text(widget.rego),
//                             // Show total cost next to rego
//                             subtitle: Text(
//                                 '${widget.rego} - Total Cost: \$${totalCost.toStringAsFixed(2)}'),
//                           ),
//                           ListTile(
//                             title: const Text('Drop off'),
//                             // subtitle: Text(
//                             //     getBookingStartDateTime(widget.bookingEntries)),
//                             subtitle:
//                                 Text('$dropOffDate $dropOffTime'), // Formatted
//                           ),
//                           ListTile(
//                             title: const Text('Pickup'),
//                             // Editable pickup time
//                             // subtitle: Text('Future date'),

//                             // Pickup time
//                             subtitle: TextFormField(
//                               initialValue: pickupTime != null
//                                   ? DateFormat('yyyy-MM-dd HH:mm')
//                                       .format(pickupTime!)
//                                   : '',
//                               decoration: const InputDecoration(
//                                   hintText: 'Select pickup time'),
//                               onChanged: (value) {
//                                 try {
//                                   pickupTime = DateFormat('yyyy-MM-dd HH:mm')
//                                       .parse(value);
//                                   // TODO: POST to /v1/booking/{ref}/pickup/{pickupTime} if needed
//                                 } catch (e) {
//                                   pickupTime = null;
//                                 }
//                                 setState(() {});
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Service Item List Section (60% width)
//                     Expanded(
//                       child: ServiceItemList(
//                         serviceOffers: serviceOffers,
//                         selectableUsers: users,
//                         workItemId: -1,
//                         rego: widget.rego, // Pass rego for filtering
//                         // Callback to refresh total or pickup if needed
//                         onWorkItemStarted:
//                             (int workItemId, List<WorkItem> updatedWorkItems) {
//                           _updateCostAndPickupTime(updatedWorkItems);
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             : Column(children: [
//                 ListTile(
//                     leading: IconButton(
//                         onPressed: () => _makePhoneCall(
//                             widget.bookingEntries[0].phone), // Click to call
//                         icon: const Icon(Icons.phone))),
//                 ListTile(
//                   title: const Text('Rego'),
//                   // subtitle: Text(widget.rego),
//                   subtitle: Text(
//                       '${widget.rego} - Total Cost: \$${totalCost.toStringAsFixed(2)}'),
//                 ),
//                 ListTile(
//                   title: const Text('Drop off'),
//                   // subtitle:
//                   //     Text(getBookingStartDateTime(widget.bookingEntries)),
//                   subtitle:
//                       Text('$dropOffDate $dropOffTime'), // Formatted HH:MM
//                 ),
//                 ListTile(
//                   title: const Text('Pickup'),
//                   // subtitle: Text('Future date'),
//                   subtitle: TextFormField(
//                     initialValue: pickupTime != null
//                         ? DateFormat('yyyy-MM-dd HH:mm').format(pickupTime!)
//                         : '',
//                     decoration:
//                         const InputDecoration(hintText: 'Select pickup time'),
//                     onChanged: (value) {
//                       try {
//                         pickupTime =
//                             DateFormat('yyyy-MM-dd HH:mm').parse(value);
//                         // TODO: POST to /v1/booking/{ref}/pickup/{pickupTime} if needed
//                       } catch (e) {
//                         pickupTime = null;
//                       }
//                       setState(() {});
//                     },
//                   ),
//                 ),
//                 Expanded(
//                     child: ServiceItemList(
//                   serviceOffers: serviceOffers,
//                   selectableUsers: users,
//                   workItemId: -1,
//                   rego: widget.rego, // Pass rego for filtering
//                   onWorkItemStarted:
//                       (int workItemId, List<WorkItem> updatedWorkItems) {
//                     _updateCostAndPickupTime(updatedWorkItems);
//                   },
//                 ))
//               ]));
//   }

//   // String getBookingStartDateTime(List<BookingEntry> bookingEntries) {
//   //   return bookingEntries[0].bookingTime;
//   // }
// }

// Packages
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _fetchWorkItems(); // Fetch work items to calculate total cost and pickup time
  }

  // Fetch work items from backend
  Future<void> _fetchWorkItems() async {
    final url = BackendConfig.getUri('v1/workitems');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      final fetchedWorkItems = data
          .map<WorkItem>((json) => WorkItem(
                id: json['id'] ?? -1,
                assignedUserName: json['userDto']?['name'] ?? 'Unassigned',
                serviceName: json['serviceItemDto']?['serviceName'] ?? '',
                duration: json['serviceItemDto']?['serviceDurationMinutes']
                        ?.toInt() ??
                    0,
                rego: json['serviceVehicleDto']?['rego'] ?? '',
                cost:
                    (json['serviceItemDto']?['servicePrice'] ?? 0.0).toDouble(),
                workItemStatus: json['workItemStatus'] ?? 'ASSIGNED',
                startedDateTime: json['startTime']?.toString() ?? '',
              ))
          .where((wi) => wi.rego == widget.rego || widget.rego.isEmpty)
          .toList();
      setState(() {
        workItems = fetchedWorkItems;
        _updateCostAndPickupTime(fetchedWorkItems);
      });
    } else {
      throw Exception('Failed to fetch work items. Please try again later.');
    }
  }

  Future<List<User>> loadUserData() async {
    final url = BackendConfig.getUri('config/users');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users. Please try again later.');
    }
    final List userList = json.decode(response.body);
    return userList
        .map((entry) => User(
              id: entry['id'] ?? -1,
              name: entry['name'] ?? '',
              role: entry['role'] ?? '',
            ))
        .toList();
  }

  Future<List<ServiceOffer>> fetchServiceOffers(
      List<BookingEntry> bookingEntries) async {
    if (bookingEntries.isEmpty) return [];

    // Use bookingRef from the first BookingEntry to fetch ServiceItems
    final bookingRef = bookingEntries[0].bookingRef;
    final url =
        BackendConfig.getUri('v1/service-item-by-booking-ref/$bookingRef');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch service offers. Please try again later.');
    }

    final List serviceOffersData = json.decode(response.body);
    return serviceOffersData
        .map((entry) => ServiceOffer(
              id: entry['id'] is int
                  ? entry['id']
                  : int.tryParse(entry['id'].toString()) ?? 0,
              name: entry['serviceName'] ?? '',
              bookingRef: bookingRef,
            ))
        .toList();
  }

  // Make a phone call
  Future<void> _makePhoneCall(String phoneNumber) async {
    print('Attempting to call: $phoneNumber');
    var status = await Permission.phone.request();
    if (status.isGranted) {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      print('URI: $launchUri');
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

  // Update total cost and pickup time based on work items
  void _updateCostAndPickupTime(List<WorkItem> workItems) {
    setState(() {
      totalCost = workItems
          .where((wi) => wi.rego == widget.rego)
          .fold(0.0, (sum, wi) => sum + wi.cost);
      print('Filtered by rego ${widget.rego}, Total Cost: $totalCost');
      pickupTime = _calculatePickupFromWorkItems(workItems);
    });
  }

  // Calculate pickup time
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

  @override
  Widget build(BuildContext context) {
    final dropOffTime = widget.bookingEntries.isNotEmpty
        ? DateFormat('HH:mm')
            .format(DateTime.parse(widget.bookingEntries[0].bookingTime))
        : 'N/A';
    final dropOffDate = widget.bookingEntries.isNotEmpty
        ? DateTime.parse(widget.bookingEntries[0].bookingTime)
            .toString()
            .split(' ')[0]
        : 'N/A';

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
                            onPressed: widget.bookingEntries.isNotEmpty
                                ? () => _makePhoneCall(
                                    widget.bookingEntries[0].phone)
                                : null,
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
                          subtitle: TextFormField(
                            initialValue: pickupTime != null
                                ? DateFormat('yyyy-MM-dd HH:mm')
                                    .format(pickupTime!)
                                : '',
                            decoration: const InputDecoration(
                                hintText: 'Select pickup time'),
                            onChanged: (value) {
                              try {
                                pickupTime =
                                    DateFormat('yyyy-MM-dd HH:mm').parse(value);
                                if (widget.bookingEntries.isNotEmpty) {
                                  // TODO: POST to /v1/booking/{ref}/pickup/{pickupTime} if needed
                                  print(
                                      'Update pickup time for bookingRef: ${widget.bookingEntries[0].bookingRef}');
                                }
                              } catch (e) {
                                pickupTime = null;
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ServiceItemList(
                      serviceOffers: serviceOffers,
                      selectableUsers: users,
                      workItemId: -1,
                      rego: widget.rego,
                      onWorkItemStarted:
                          (int workItemId, List<WorkItem> updatedWorkItems) {
                        _updateCostAndPickupTime(updatedWorkItems);
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
                    onPressed: widget.bookingEntries.isNotEmpty
                        ? () => _makePhoneCall(widget.bookingEntries[0].phone)
                        : null,
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
                  subtitle: TextFormField(
                    initialValue: pickupTime != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(pickupTime!)
                        : '',
                    decoration:
                        const InputDecoration(hintText: 'Select pickup time'),
                    onChanged: (value) {
                      try {
                        pickupTime =
                            DateFormat('yyyy-MM-dd HH:mm').parse(value);
                        if (widget.bookingEntries.isNotEmpty) {
                          // TODO: POST to /v1/booking/{ref}/pickup/{pickupTime} if needed
                          print(
                              'Update pickup time for bookingRef: ${widget.bookingEntries[0].bookingRef}');
                        }
                      } catch (e) {
                        pickupTime = null;
                      }
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: ServiceItemList(
                    serviceOffers: serviceOffers,
                    selectableUsers: users,
                    workItemId: -1,
                    rego: widget.rego,
                    onWorkItemStarted:
                        (int workItemId, List<WorkItem> updatedWorkItems) {
                      _updateCostAndPickupTime(updatedWorkItems);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
