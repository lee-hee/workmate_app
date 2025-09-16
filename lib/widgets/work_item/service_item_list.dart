// Modified =>  Instead compare whole AssignableServiceItem objects, only use userId

// Packages
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Models
import '../../model/assignable_service_item.dart';
import '../../model/service_item.dart';
import '../../model/user.dart';
import '../../model/work_item.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/work_item/work_item_util.dart';

class ServiceItemList extends StatefulWidget {
  const ServiceItemList(
      {super.key,
      required this.serviceOffers,
      required this.selectableUsers,
      required this.workItemId,
      required this.rego, // Rego filtering
      this.onWorkItemStarted});
  final List<ServiceOffer> serviceOffers;
  final List<User> selectableUsers;
  final int workItemId;
  final String rego;
  final Function(int, List<WorkItem>)? onWorkItemStarted;
  @override
  // ignore: library_private_types_in_public_api
  _ServiceItemListState createState() => _ServiceItemListState();
}

class _ServiceItemListState extends State<ServiceItemList> {
  List<WorkItem> workItems = []; // Store work items
  DateTime currentStartTime = DateTime.now(); // For sequential start times

  @override
  void initState() {
    super.initState();
    // Fetch existing work items on init
    _fetchWorkItems();
  }

  // Fetch work items from backend
  Future<void> _fetchWorkItems() async {
    // Endpoint /v1/workitems for all; filter by booking refs if needed
    final url = BackendConfig.getUri('v1/workitems');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        workItems = data
            .map<WorkItem>((json) => WorkItem(
                  id: json['id'] ?? -1,
                  assignedUserName: json['userDto']?['name'] ?? 'Unassigned',
                  serviceName: json['serviceItemDto']?['serviceName'] ?? '',
                  duration:
                      json['serviceItemDto']?['serviceDurationMinutes'] ?? 0,
                  rego: json['serviceVehicleDto']?['rego'] ?? '',
                  cost: (json['serviceItemDto']?['servicePrice'] ?? 0.0)
                      .toDouble(),
                  workItemStatus: json['workItemStatus'] ?? 'ASSIGNED',
                  startedDateTime: json['startTime']?.toString() ?? '',
                ))
            .where((wi) => wi.rego == widget.rego || widget.rego.isEmpty)
            .toList();
        print(
            'Fetched workItems in ServiceItemList: ${workItems.map((wi) => "${wi.serviceName}: \$${wi.cost}, Rego: ${wi.rego}").toList()}');
      });
      // Notify parent after fetch
      widget.onWorkItemStarted?.call(widget.workItemId, workItems);
    } else {
      throw Exception('Failed to fetch work items. Please try again later.');
    }
  }

  // Create a new work item
  Future<void> createWorkItem(
      AssignableServiceItem assignableServiceItem) async {
    final url = BackendConfig.getUri(
        'v1/workitem/${assignableServiceItem.bookingRef}/${assignableServiceItem.userId}');
    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      // Refresh work items
      await _fetchWorkItems();

      // Notify parent widget
      widget.onWorkItemStarted
          ?.call(assignableServiceItem.workItemId, workItems);
      setState(() {
        currentStartTime = DateTime.now(); // Reset
      });
    } else {
      throw Exception('Failed to create work item. Please try again later.');
    }
  }

  // Start a work item
  Future<void> startWorkItem(int workItemId) async {
    final url = BackendConfig.getUri('v1/workitem/start/$workItemId');
    final response = await http.post(url);
    if (response.statusCode == 200) {
      await _fetchWorkItems();
      // Notify parent widget
      widget.onWorkItemStarted?.call(workItemId, workItems);
      setState(() {});
    } else {
      throw Exception('Failed to start work item. Please try again later.');
    }
  }

  // Calculate start time based on previous items
  DateTime calculateStartTime(int index) {
    DateTime start = currentStartTime;
    final workItemsByRego =
        workItems.where((wi) => wi.rego == widget.rego).toList();
    for (int i = 0; i < index && i < workItemsByRego.length; i++) {
      final duration = Duration(minutes: workItemsByRego[i].duration);
      start = start.add(duration);
    }
    return start;
  }

  // Calculate approx pickup time
  DateTime? calculatePickupTime() {
    final workItemsByRego =
        workItems.where((wi) => wi.rego == widget.rego).toList();
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
            border: Border.all(color: const Color.fromARGB(255, 48, 144, 97))),
        child: ListView.builder(
          itemCount: widget.serviceOffers.length,
          // itemBuilder: (ctx, index) => ListTile(
          //       title: Text(widget.serviceOffers[index].name),
          //       trailing: getAssignableServiceItems(
          //           widget.serviceOffers[index], widget.workItemId),
          //     )),

          // Zebra striping and detailed info
          itemBuilder: (ctx, index) {
            final serviceOffer = widget.serviceOffers[index];
            final workItem = workItems.firstWhere(
              (wi) =>
                  wi.serviceName == serviceOffer.name && wi.rego == widget.rego,
              orElse: () => WorkItem(
                id: -1,
                assignedUserName: '',
                serviceName: serviceOffer.name,
                duration: 0,
                rego: widget.rego,
                cost: 0.0,
                workItemStatus: 'ASSIGNED',
                startedDateTime: '',
              ),
            );
            final startTime = workItem.startedDateTime.isNotEmpty
                ? DateTime.parse(workItem.startedDateTime)
                : calculateStartTime(index);
            final endTime = startTime.add(Duration(minutes: workItem.duration));
            final zebraColor =
                index % 2 == 0 ? Colors.blue.shade100 : Colors.transparent;

            return Container(
              color: zebraColor,
              child: ListTile(
                // title: Text(serviceOffer.name),
                leading:
                    workItem.id != -1 ? workItem.getIconBasedOnStatus() : null,
                title: Text(
                  '${workItem.serviceName} - \$${workItem.cost.toStringAsFixed(2)} - Approx: ${DateFormat('HH:mm').format(startTime)} (${workItem.duration}m)',
                  style: TextStyle(color: workItem.getIconColorBasedOnStatus()),
                ),
                subtitle: Text(
                    'Pickup Approx: ${DateFormat('HH:mm').format(endTime)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (workItem.id != -1 && workItem.startedDateTime.isEmpty)
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => startWorkItem(workItem.id),
                      ),
                    // DropdownButton<AssignableServiceItem>(
                    //   // value: workItem.assignedUserName.isNotEmpty

                    //   // Assign only if not already assigned and user exists
                    //   value: workItem.assignedUserName.isNotEmpty &&
                    //           widget.selectableUsers.any(
                    //               (u) => u.name == workItem.assignedUserName)
                    //       ? AssignableServiceItem(
                    //           bookingRef: serviceOffer.bookingRef,
                    //           serviceItemId: serviceOffer.id,
                    //           userId: widget.selectableUsers
                    //               .firstWhere((u) =>
                    //                   u.name == workItem.assignedUserName)
                    //               .id,
                    //           workItemId: workItem.id,
                    //         )
                    //       : null,
                    //   // onChanged: (value) => createWorkItem(value!),
                    //   // Disable if assigned
                    //   onChanged: workItem.id == -1
                    //       ? (value) => createWorkItem(value!)
                    //       : null,
                    //   // Map users to DropdownMenuItems
                    //   items: widget.selectableUsers.map((user) {
                    //     return DropdownMenuItem<AssignableServiceItem>(
                    //       value: AssignableServiceItem(
                    //         bookingRef: serviceOffer.bookingRef,
                    //         serviceItemId: serviceOffer.id,
                    //         userId: user.id,
                    //         workItemId: workItem.id,
                    //       ),
                    //       child: Text(user.name),
                    //     );
                    //   }).toList(),
                    // ),

                    // Instead compare whole AssignableServiceItem objects, only use userId
                    DropdownButton<int>(
                      value: workItem.id != -1 &&
                              widget.selectableUsers.any(
                                  (u) => u.name == workItem.assignedUserName)
                          ? widget.selectableUsers
                              .firstWhere(
                                  (u) => u.name == workItem.assignedUserName)
                              .id
                          : null,
                      onChanged: (userId) {
                        if (userId != null) {
                          createWorkItem(AssignableServiceItem(
                            bookingRef: serviceOffer.bookingRef,
                            serviceItemId: serviceOffer.id,
                            userId: userId,
                            workItemId: workItem.id,
                          ));
                        }
                      },
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

  // void setSlectedUser(String? value) {
  //   // This is called when the user selects an item.
  //   setState(() {
  //     //dropdownValue = value!;
  //   });
  // }

  Widget getAssignableServiceItems(ServiceOffer serviceOffer, int workItemId) {
    // Moved logic to itemBuilder for zebra and details
    return const SizedBox.shrink(); // Handled in ListTile
  }
}
