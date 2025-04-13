import 'package:workmate_app/model/user.dart';

class ServiceOffer {
  const ServiceOffer(
      {required this.id, required this.name, required this.bookingRef});
  final int id;
  final String name;
  final String bookingRef;
}
