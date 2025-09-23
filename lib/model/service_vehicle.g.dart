// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceVehicle _$ServiceVehicleFromJson(Map<String, dynamic> json) =>
    ServiceVehicle(
      id: (json['id'] as num).toInt(),
      rego: json['rego'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      customerId: (json['customerId'] as num).toInt(),
    );

Map<String, dynamic> _$ServiceVehicleToJson(ServiceVehicle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'rego': instance.rego,
      'make': instance.make,
      'model': instance.model,
      'customerId': instance.customerId,
    };
