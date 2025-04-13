import 'dart:collection';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:workmate_app/model/service_item.dart';
import 'package:workmate_app/model/user.dart';
import 'package:workmate_app/model/work_item_user_booking_ref.dart';

class ServiceItemList extends StatefulWidget {
const ServiceItemList({
    super.key,
    required this.serviceOffers,
    required this.slectableUsers,
    required this.workItemId,
    required this.bookingRef,
  });
  final List<ServiceOffer> serviceOffers;
  final List<User> slectableUsers;
  final Long workItemId;
  final String bookingRef;
  @override
  // ignore: library_private_types_in_public_api
  _ServiceItemListState createState() => _ServiceItemListState();
}

class _ServiceItemListState extends State<ServiceItemList> {
  @override
  Widget build(Object context) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 48, 144, 97))),
      child: ListView.builder(
          itemCount: widget.serviceOffers.length,
          itemBuilder: (ctx, index) => ListTile(
                title: Text(
                    '${widget.serviceOffers[index].name} ${widget.serviceOffers[index].id}'),
                trailing: getUsers(),
              )),
    );
  }

  DropdownMenu getUsers() {
    return DropdownMenu(
        initialSelection: null,
        onSelected: (value) => {
              //we have workitemid<-->user
              print('link work item to user in the server'+value)
            },
        dropdownMenuEntries: [
          for (final user in widget.slectableUsers)
            DropdownMenuEntry<WorkItemToUserBookingRef>(
                label: user.name,
                value: WorkItemToUserBookingRef(
                  userId: user.id, workItemId: widget.workItemId, bookingRef: widget.bookingRef)
                )) //Create a wrapped entity workitemid<-->user
        ]);
  }

  void setSlectedUser(String? value) {
    // This is called when the user selects an item.
    setState(() {
      //dropdownValue = value!;
    });
  }
}
