// Packages
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

// Models
import '../../model/service_item.dart';
import '../../model/user.dart';
import '../../model/work_item.dart';
import '../booking_list/booking_calendar_container.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/work_item/work_item_util.dart';

class ServiceItemList extends StatefulWidget {
  const ServiceItemList({
    super.key,
    required this.serviceOffers,
    required this.selectableUsers,
    required this.workItems,
    required this.workItemId,
    required this.rego,
    required this.bookingEntries,
    this.onWorkItemStarted,
  });
  final List<ServiceOffer> serviceOffers;
  final List<User> selectableUsers;
  final List<WorkItem> workItems;
  final int workItemId;
  final String rego;
  final List<BookingEntry> bookingEntries;
  final Function(int, List<WorkItem>)? onWorkItemStarted;

  @override
  _ServiceItemListState createState() => _ServiceItemListState();
}

class _ServiceItemListState extends State<ServiceItemList> {
  List<WorkItem> filteredWorkItems = [];
  DateTime currentStartTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _filterWorkItems();
  }

  @override
  void didUpdateWidget(ServiceItemList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workItems != widget.workItems ||
        oldWidget.bookingEntries != widget.bookingEntries) {
      _filterWorkItems();
    }
  }

  void _filterWorkItems() {
    setState(() {
      filteredWorkItems = widget.workItems.where((wi) {
        final matchesRego = wi.rego == widget.rego;
        final isPending = wi.workItemStatus.toUpperCase() == 'PENDING';
        final matchesBookingRef = widget.bookingEntries.any((entry) {
          final match = entry.bookingRef.trim().toUpperCase() ==
              wi.uniqueBookingRefIdentifier.trim().toUpperCase();
          if (!match) {
            print(
                'BookingRef mismatch: "${entry.bookingRef}" != "${wi.uniqueBookingRefIdentifier}"');
          }
          return match;
        });
        print(
            'WorkItem: ${wi.serviceName}, Rego: ${wi.rego}, Status: ${wi.workItemStatus}, BookingRef: ${wi.uniqueBookingRefIdentifier}, Matches: Rego=$matchesRego, Pending=$isPending, BookingRef=$matchesBookingRef');
        return matchesRego && isPending;
      }).toList();
      print(
          'Filtered workItems in ServiceItemList: ${filteredWorkItems.map((wi) => "${wi.serviceName}: \$${wi.cost}, Rego: ${wi.rego}, BookingRef: ${wi.uniqueBookingRefIdentifier}, Status: ${wi.workItemStatus}").toList()}');
    });
  }

  Future<void> _assignUserToWorkItem(int workItemId, int userId) async {
    final url = BackendConfig.getUri('v1/workitem/$workItemId/assign/$userId');
    final response = await http.post(url);
    if (response.statusCode == 200) {
      final urlWorkItems = BackendConfig.getUri('v1/workitems');
      final responseWorkItems = await http.get(urlWorkItems);
      if (responseWorkItems.statusCode == 200) {
        final List data = json.decode(responseWorkItems.body);
        final updatedWorkItems = data
            .map<WorkItem>((json) => WorkItem(
                  id: json['id'] ?? -1,
                  assignedUserName: json['userDto']?['name'] ?? 'Unassigned',
                  serviceName: json['serviceItemDto']?['serviceName'] ?? '',
                  duration:
                      json['serviceItemDto']?['serviceDurationMinutes'] ?? 0,
                  rego: json['serviceVehicleDto']?['rego'] ?? '',
                  cost: (json['serviceItemDto']?['servicePrice'] ?? 0.0)
                      .toDouble(),
                  workItemStatus: json['workItemStatus'] ?? 'PENDING',
                  startedDateTime: json['startTime']?.toString() ?? '',
                  uniqueBookingRefIdentifier:
                      json['uniqueBookingRefIdentifier'] ?? '',
                ))
            .where((wi) {
          final matchesRego = wi.rego == widget.rego;
          final isPending = wi.workItemStatus.toUpperCase() == 'PENDING';
          final matchesBookingRef = widget.bookingEntries.any((entry) =>
              entry.bookingRef.trim().toUpperCase() ==
              wi.uniqueBookingRefIdentifier.trim().toUpperCase());
          return matchesRego && isPending;
        }).toList();
        setState(() {
          filteredWorkItems = updatedWorkItems;
        });
        widget.onWorkItemStarted?.call(workItemId, updatedWorkItems);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User assigned to work item ID: $workItemId'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(
            'Failed to fetch updated work items. Status code: ${responseWorkItems.statusCode}');
      }
    } else {
      throw Exception(
          'Failed to assign user. Status code: ${response.statusCode}');
    }
  }

  Future<void> startWorkItem(int workItemId) async {
    final url = BackendConfig.getUri('v1/workitem/start/$workItemId');
    final response = await http.post(url);
    if (response.statusCode == 200) {
      final urlWorkItems = BackendConfig.getUri('v1/workitems');
      final responseWorkItems = await http.get(urlWorkItems);
      if (responseWorkItems.statusCode == 200) {
        final List data = json.decode(responseWorkItems.body);
        final updatedWorkItems = data
            .map<WorkItem>((json) => WorkItem(
                  id: json['id'] ?? -1,
                  assignedUserName: json['userDto']?['name'] ?? 'Unassigned',
                  serviceName: json['serviceItemDto']?['serviceName'] ?? '',
                  duration:
                      json['serviceItemDto']?['serviceDurationMinutes'] ?? 0,
                  rego: json['serviceVehicleDto']?['rego'] ?? '',
                  cost: (json['serviceItemDto']?['servicePrice'] ?? 0.0)
                      .toDouble(),
                  workItemStatus: json['workItemStatus'] ?? 'PENDING',
                  startedDateTime: json['startTime']?.toString() ?? '',
                  uniqueBookingRefIdentifier:
                      json['uniqueBookingRefIdentifier'] ?? '',
                ))
            .where((wi) {
          final matchesRego = wi.rego == widget.rego;
          final isPending = wi.workItemStatus.toUpperCase() == 'PENDING';
          final matchesBookingRef = widget.bookingEntries.any((entry) =>
              entry.bookingRef.trim().toUpperCase() ==
              wi.uniqueBookingRefIdentifier.trim().toUpperCase());
          return matchesRego && isPending; // Relaxed for consistency
        }).toList();
        setState(() {
          filteredWorkItems = updatedWorkItems;
        });
        widget.onWorkItemStarted?.call(workItemId, updatedWorkItems);
      } else {
        throw Exception(
            'Failed to fetch updated work items. Status code: ${responseWorkItems.statusCode}');
      }
    } else {
      throw Exception(
          'Failed to start work item. Status code: ${response.statusCode}');
    }
  }

  DateTime calculateStartTime(int index) {
    DateTime start = currentStartTime;
    final workItemsByRego =
        filteredWorkItems.where((wi) => wi.rego == widget.rego).toList();
    for (int i = 0; i < index && i < workItemsByRego.length; i++) {
      final duration = Duration(minutes: workItemsByRego[i].duration);
      start = start.add(duration);
    }
    return start;
  }

  DateTime? calculatePickupTime() {
    final workItemsByRego =
        filteredWorkItems.where((wi) => wi.rego == widget.rego).toList();
    if (workItemsByRego.isEmpty) return null;
    final lastWorkItem = workItemsByRego.last;
    DateTime end = lastWorkItem.startedDateTime.isNotEmpty
        ? DateTime.parse(lastWorkItem.startedDateTime)
        : currentStartTime;
    final totalDuration =
        workItemsByRego.fold(0, (sum, wi) => sum + wi.duration);
    return end.add(Duration(minutes: totalDuration));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ResponsiveWorkItemUtils.getServiceItemListWidth(context),
      height: ResponsiveWorkItemUtils.getServiceItemListHeight(context),
      child: Container(
        margin: ResponsiveWorkItemUtils.getServiceItemListMargin(context),
        padding: ResponsiveWorkItemUtils.getServiceItemListPadding(context),
        decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 48, 144, 97)),
        ),
        child: filteredWorkItems.isEmpty
            ? const Center(child: Text('No pending work items available'))
            : ListView.builder(
                itemCount: filteredWorkItems.length,
                itemBuilder: (ctx, index) {
                  final workItem = filteredWorkItems[index];
                  final startTime = workItem.startedDateTime.isNotEmpty
                      ? DateTime.parse(workItem.startedDateTime)
                      : calculateStartTime(index);
                  final endTime =
                      startTime.add(Duration(minutes: workItem.duration));
                  final zebraColor = index % 2 == 0
                      ? Colors.blue.shade100
                      : Colors.transparent;

                  return Container(
                    color: zebraColor,
                    child: ListTile(
                      leading: workItem.id != -1
                          ? workItem.getIconBasedOnStatus()
                          : null,
                      title: Text(
                        '${workItem.serviceName} - \$${workItem.cost.toStringAsFixed(2)} - Approx: ${DateFormat('HH:mm').format(startTime)} (${workItem.duration}m)',
                        style: TextStyle(
                            color: workItem.getIconColorBasedOnStatus()),
                      ),
                      subtitle: Text(
                        'Pickup Approx: ${DateFormat('HH:mm').format(endTime)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (workItem.id != -1 &&
                              workItem.startedDateTime.isEmpty &&
                              workItem.workItemStatus.toUpperCase() ==
                                  'ASSIGNED')
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () => startWorkItem(workItem.id),
                            ),
                          DropdownButton<int>(
                            hint: const Text('Select User'),
                            value: workItem.assignedUserName.isNotEmpty &&
                                    widget.selectableUsers.any((u) =>
                                        u.name == workItem.assignedUserName)
                                ? widget.selectableUsers
                                    .firstWhere((u) =>
                                        u.name == workItem.assignedUserName)
                                    .id
                                : null,
                            onChanged: workItem.id != -1 &&
                                    workItem.workItemStatus.toUpperCase() ==
                                        'PENDING'
                                ? (userId) {
                                    if (userId != null) {
                                      _assignUserToWorkItem(
                                          workItem.id, userId);
                                    }
                                  }
                                : null,
                            items: widget.selectableUsers.map((user) {
                              return DropdownMenuItem<int>(
                                value: user.id,
                                child: Text(user.name),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
