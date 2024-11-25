import 'package:flutter/material.dart';
import 'package:workmate_app/model/service_item.dart';
import 'package:workmate_app/widgets/work_item/service_item_list.dart';

class WorkItemPage extends StatefulWidget {
  const WorkItemPage(
      {super.key,
      required this.rego,
      required this.bookingRef,
      required this.bookingTime,
      required this.customerPhone,
      required this.duration,
      required this.currentServiceOffers});
  final List<ServiceOffer> currentServiceOffers;
  final String rego;
  final String bookingRef;
  final String bookingTime;
  final String customerPhone;
  final String duration;
  @override
  // ignore: library_private_types_in_public_api
  _WorkItemPageState createState() => _WorkItemPageState();
}

class _WorkItemPageState extends State<WorkItemPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Manage booking')),
        body: Column(children: [
          ListTile(
            leading:
                IconButton(onPressed: () => {}, icon: const Icon(Icons.phone)),
            title: const Text('Booking Refenece'),
            subtitle: Text(widget.bookingRef),
          ),
          ListTile(
            title: const Text('Rego'),
            subtitle: Text(widget.rego),
          ),
          ListTile(
            title: const Text('Booking start'),
            subtitle: Text(widget.bookingTime),
          ),
          const ListTile(
            title: Text('Pickup Time'),
            subtitle: Text('Future date'),
          ),
          Expanded(
              child:
                  ServiceItemList(serviceOffers: widget.currentServiceOffers))
        ]));
  }
}
