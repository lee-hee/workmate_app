import 'package:flutter/material.dart';
import 'package:workmate_app/model/service_item.dart';

class ServiceItemList extends StatelessWidget {
  const ServiceItemList({
    super.key,
    required this.serviceOffers,
  });

  final List<ServiceOffer> serviceOffers;

  @override
  Widget build(Object context) {
    return Container(
      margin: const EdgeInsets.all(15.0),
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
          border: Border.all(color: const Color.fromARGB(255, 48, 144, 97))),
      child: ListView.builder(
          itemCount: serviceOffers.length,
          itemBuilder: (ctx, index) =>
              ListTile(title: Text(serviceOffers[index].name))),
    );
  }
}
