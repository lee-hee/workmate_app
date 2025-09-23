import 'package:json_annotation/json_annotation.dart';

part 'booking.g.dart';

@JsonSerializable()
class Booking {
  const Booking({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.bookingDateTime,
    required this.bookingReferenceNumber,
    required this.bookingStatus,
  });

  final int id;
  final int customerId;
  final int vehicleId;
  final String bookingDateTime;
  final String bookingReferenceNumber;
  final String bookingStatus;

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);
  Map<String, dynamic> toJson() => _$BookingToJson(this);
}
