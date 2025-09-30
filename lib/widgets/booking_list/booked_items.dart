import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Config
import '../../config/backend_config.dart';

// Models
import '../../model/service_item.dart';
import '../../model/work_item.dart';

// Widgets
import '../../screens/work_item_manage/work_item_manage_screen.dart';
import '../booking_list/booking_calendar_container.dart';

// Utils
import '../../utils/responsive_utils/booking_list/calender_list_util.dart';

class BookingDescription extends StatefulWidget {
  const BookingDescription({
    super.key,
    required this.rego,
    required this.bookingEntries,
    this.showAll = false,
  });

  final String rego;
  final List<BookingEntry> bookingEntries;
  final bool showAll;

  @override
  _BookingDescriptionState createState() => _BookingDescriptionState();
}

class _BookingDescriptionState extends State<BookingDescription> {
  List<ServiceOffer> serviceOffers = [];

  @override
  void initState() {
    super.initState();
    _fetchServiceOffers();
  }

  Future<void> _fetchServiceOffers() async {
    List<dynamic> serviceOfferIds = widget.bookingEntries
        .map((entry) => entry.serviceItemIds)
        .expand((listEntry) => listEntry)
        .toList();
    if (serviceOfferIds.isEmpty) {
      print('Skipping service offers fetch: No serviceItemIds available');
      return;
    }
    print(
        'Fetching service offers in BookingDescription for IDs: $serviceOfferIds');
    final url = BackendConfig.getUri('config/service-offers');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(serviceOfferIds),
    );

    if (response.statusCode == 200) {
      final List serviceOffersData = json.decode(response.body);
      setState(() {
        serviceOffers = serviceOffersData
            .map((entry) => ServiceOffer(
                  id: entry['id'],
                  name: entry['serviceName'],
                  bookingRef: widget.bookingEntries
                      .firstWhere(
                          (e) =>
                              e.serviceItemIds.contains(entry['id'].toString()),
                          orElse: () => widget.bookingEntries.first)
                      .bookingRef,
                ))
            .toList();
      });
      print(
          'Fetched service offers in BookingDescription: ${serviceOffers.map((so) => "${so.name}, BookingRef: ${so.bookingRef}").toList()}');
    } else {
      print(
          'Failed to fetch service offers in BookingDescription. Status code: ${response.statusCode}');
      throw Exception('Failed to fetch service offers.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesToShow = widget.showAll
        ? widget.bookingEntries
        : widget.bookingEntries.take(1).toList();

    return Padding(
      padding: widget.showAll
          ? const EdgeInsets.all(8.0)
          : ResponsiveBookingListUtils.getDescriptionPaddingWidthAware(context),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (widget.showAll)
              Center(
                child: Text(
                  'Vehicle Rego: ${widget.rego}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            if (!widget.showAll)
              Center(
                child: Text(
                  'Vehicle Rego: ${widget.rego}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            SizedBox(height: widget.showAll ? 16.0 : 2.0),
            Text(
              'Work Items',
              style: TextStyle(
                fontSize: widget.showAll ? 15 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4.0),
            for (int i = 0; i < entriesToShow.length; i++)
              FutureBuilder<List<WorkItem>>(
                future: _fetchWorkItemsForBooking(entriesToShow[i].bookingRef),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.only(top: widget.showAll ? 4.0 : 2.0),
                      child: const Text('Loading...'),
                    );
                  }
                  if (snapshot.hasError) {
                    print(
                        'Error in _fetchWorkItemsForBooking: ${snapshot.error}');
                    return Padding(
                      padding: EdgeInsets.only(top: widget.showAll ? 4.0 : 2.0),
                      child: const Text('Error loading work items'),
                    );
                  }
                  final workItems = snapshot.data ?? [];
                  print(
                      'Work items for BookingRef: ${entriesToShow[i].bookingRef}: ${workItems.map((wi) => "${wi.serviceName}, Status: ${wi.workItemStatus}").toList()}');

                  if (workItems.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: widget.showAll ? 4.0 : 2.0),
                      child: const Text('No work items'),
                    );
                  }

                  // Show only first work item in list view
                  if (!widget.showAll) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '1 - ${workItems.first.serviceName} (${workItems.first.workItemStatus})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }

                  // Show all work items in popup
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: workItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final workItem = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: workItem.getIconColorBasedOnStatus(),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    workItem.workItemStatus,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              workItem.serviceName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Assigned To: ${workItem.assignedUserName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            if (!widget.showAll && widget.bookingEntries.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: Text(
                  '+${widget.bookingEntries.length - 1} more...',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<List<WorkItem>> _fetchWorkItemsForBooking(String bookingRef) async {
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
          .where((wi) =>
              wi.uniqueBookingRefIdentifier.trim().toUpperCase() ==
                  bookingRef.trim().toUpperCase() &&
              wi.rego == widget.rego)
          .toList();
      print(
          'Fetched work items for BookingRef: $bookingRef, Rego: ${widget.rego}: ${workItems.map((wi) => "${wi.serviceName}, Status: ${wi.workItemStatus}").toList()}');
      return workItems;
    } else {
      throw Exception(
          'Failed to fetch work items. Status code: ${response.statusCode}');
    }
  }
}

class BookingListItem extends StatefulWidget {
  const BookingListItem({
    super.key,
    required this.rego,
    required this.bookingEntries,
  });
  final String rego;
  final List<BookingEntry> bookingEntries;

  @override
  _BookingListItemState createState() => _BookingListItemState();
}

class _BookingListItemState extends State<BookingListItem> {
  List<BookingEntry> updatedBookingEntries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServiceItemIds();
  }

  Future<void> _fetchServiceItemIds() async {
    try {
      final updatedEntries = <BookingEntry>[];
      for (var entry in widget.bookingEntries) {
        final url = BackendConfig.getUri(
            'v1/booking/${entry.bookingRef}/service-items');
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final List serviceItems = json.decode(response.body);
          final serviceItemIds =
              serviceItems.map((item) => item['id'].toString()).toList();
          updatedEntries.add(BookingEntry(
            entry.phone,
            entry.customerName,
            entry.bookingRef,
            serviceItemIds,
            entry.bookingTime,
          ));
          print(
              'Fetched serviceItemIds for BookingRef: ${entry.bookingRef}, IDs: $serviceItemIds');
        } else {
          print(
              'Failed to fetch service items for BookingRef: ${entry.bookingRef}. Status code: ${response.statusCode}');
          updatedEntries.add(entry);
        }
      }
      setState(() {
        updatedBookingEntries = updatedEntries;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching service item IDs: $e');
      setState(() {
        updatedBookingEntries = widget.bookingEntries;
        isLoading = false;
      });
    }
  }

  void _showWorkItemsPopup(BuildContext context) {
    final isMobile = ResponsiveBookingListUtils.isMobileOrTablet(context);
    final bookingEntries = updatedBookingEntries.isNotEmpty
        ? updatedBookingEntries
        : widget.bookingEntries;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final dialogContent = AlertDialog(
          content: SizedBox(
            height: 400.0,
            width: isMobile ? double.maxFinite : 450,
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : BookingDescription(
                    rego: widget.rego,
                    bookingEntries: bookingEntries,
                    showAll: true,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => WorkItemManageScreen(
                      rego: widget.rego,
                      bookingEntries: bookingEntries,
                    ),
                  ),
                );
              },
              child: const Text('Manage Booking'),
            ),
          ],
        );

        if (isMobile) {
          return dialogContent;
        } else {
          return Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: dialogContent,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingEntries = updatedBookingEntries.isNotEmpty
        ? updatedBookingEntries
        : widget.bookingEntries;

    return GestureDetector(
      onTap: () => _showWorkItemsPopup(context),
      child: SizedBox(
        height: ResponsiveBookingListUtils.getItemHeightWidthAware(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : BookingDescription(
                      rego: widget.rego,
                      bookingEntries: bookingEntries,
                      showAll: false,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
