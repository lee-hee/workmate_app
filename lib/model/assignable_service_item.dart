class AssignableServiceItem {
  const AssignableServiceItem(
      {required this.workItemId,
      required this.bookingRef,
      required this.userId,
      required this.serviceItemId});
  final int workItemId;
  final String bookingRef;
  final int userId;
  final int serviceItemId;
}
