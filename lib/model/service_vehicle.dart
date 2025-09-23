import 'package:json_annotation/json_annotation.dart';

part 'service_vehicle.g.dart';

@JsonSerializable()
class ServiceVehicle {
  const ServiceVehicle({
    required this.id,
    required this.rego,
    required this.make,
    required this.model,
    required this.customerId,
  });

  final int id;
  final String rego;
  final String make;
  final String model;
  final int customerId;

  factory ServiceVehicle.fromJson(Map<String, dynamic> json) => _$ServiceVehicleFromJson(json);
  Map<String, dynamic> toJson() => _$ServiceVehicleToJson(this);
}