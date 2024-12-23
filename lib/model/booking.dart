class Booking {
  const Booking(
      {required this.bookingTime,
      required this.bookingReferenceNumber,
      required this.customerPhone,
      required this.rego,
      required this.bookedItems});

  final String bookingTime;
  final String bookingReferenceNumber;
  final String customerPhone;
  final String rego;
  final List<String> bookedItems;
}
