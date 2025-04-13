import 'dart:ffi';

class WorkItemToUserBookingRef {
  const WorkItemToUserBookingRef(
      {required this.workItemId,
      required this.userId,
      required this.bookingRef});
  final Long workItemId;
  final Long userId;
  final String bookingRef;
}
