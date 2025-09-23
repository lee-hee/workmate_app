// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Booking _$BookingFromJson(Map<String, dynamic> json) => Booking(
      id: (json['id'] as num).toInt(),
      customerId: (json['customerId'] as num).toInt(),
      vehicleId: (json['vehicleId'] as num).toInt(),
      bookingDateTime: json['bookingDateTime'] as String,
      bookingReferenceNumber: json['bookingReferenceNumber'] as String,
      bookingStatus: json['bookingStatus'] as String,
    );

Map<String, dynamic> _$BookingToJson(Booking instance) => <String, dynamic>{
      'id': instance.id,
      'customerId': instance.customerId,
      'vehicleId': instance.vehicleId,
      'bookingDateTime': instance.bookingDateTime,
      'bookingReferenceNumber': instance.bookingReferenceNumber,
      'bookingStatus': instance.bookingStatus,
    };
