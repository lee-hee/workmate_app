import 'package:json_annotation/json_annotation.dart';

part 'customer.g.dart';

@JsonSerializable()
class Customer {
  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String phone;
}
