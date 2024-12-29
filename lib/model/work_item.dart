import 'package:flutter/material.dart';

class WorkItem {
  const WorkItem(
      {required this.id,
      required this.assignedUserId,
      required this.workItemStatus,
      required this.startedDateTime});
  final int id;
  final int assignedUserId;
  final String workItemStatus;
  final String startedDateTime;

  Icon getIconBasedOnStatus() {
    switch (workItemStatus) {
      case 'ASSIGNED':
        return const Icon(Icons.thumb_up);
      case 'STARTED':
        return const Icon(Icons.build);
      case 'PAUSED':
        return const Icon(Icons.pending);
      case 'PARTS_ORDERED':
        return const Icon(Icons.shopping_cart_checkout);
      case 'INTERNAL_CONSULT_NEEDED':
        return const Icon(Icons.support);
      case 'EXTERNAL_CONSULT_NEEDED':
        return const Icon(Icons.local_shipping);
      case 'COMPLETED':
        return const Icon(Icons.check_circle);
      case 'INVOICED':
        return const Icon(Icons.price_check);
      case 'PAID':
        return const Icon(Icons.paid);
      default:
        return const Icon(Icons.warning);
    }
  }

  Color getIconColorBasedOnStatus() {
    switch (workItemStatus) {
      case 'ASSIGNED':
        return const Color.fromARGB(255, 174, 225, 55);
      case 'STARTED':
        return const Color.fromARGB(255, 57, 188, 37);
      case 'PAUSED':
        return const Color.fromARGB(255, 234, 125, 66);
      case 'PARTS_ORDERED':
        return const Color.fromARGB(255, 66, 234, 231);
      case 'INTERNAL_CONSULT_NEEDED':
        return const Color.fromARGB(255, 6, 142, 51);
      case 'EXTERNAL_CONSULT_NEEDED':
        return const Color.fromARGB(255, 226, 56, 9);
      case 'COMPLETED':
      case 'INVOICED':
      case 'PAID':
        return const Color.fromARGB(255, 4, 247, 37);
      default:
        return const Color.fromARGB(255, 247, 4, 227);
    }
  }
}
