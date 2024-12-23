import 'package:flutter/material.dart';
import 'package:workmate_app/model/service_item.dart';
import 'package:workmate_app/widgets/booking_list/booking_calendar_container.dart';
import 'package:workmate_app/widgets/work_item/service_item_list.dart';

class WorkItemPage extends StatefulWidget {
  const WorkItemPage({
    super.key,
    required this.rego,
    required this.bookingEntries,
  });
  final List<BookingEntry> bookingEntries;
  final String rego;

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
            subtitle: Text('Booking ref'),
          ),
          ListTile(
            title: const Text('Rego'),
            subtitle: Text('Rego value'),
          ),
          ListTile(
            title: const Text('Booking start'),
            subtitle: Text('Booking start time'),
          ),
          const ListTile(
            title: Text('Pickup Time'),
            subtitle: Text('Future date'),
          ),
          const Expanded(
              child: ServiceItemList(serviceOffers: [
            ServiceOffer(id: 1, name: 'offer 1'),
            ServiceOffer(id: 2, name: 'offer 2'),
          ])) //widget.currentServiceOffers
        ]));
  }
}
