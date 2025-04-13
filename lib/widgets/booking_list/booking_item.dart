import 'package:flutter/material.dart';
import 'package:workmate_app/widgets/booking_list/booking_calendar_container.dart';
import 'package:workmate_app/widgets/work_item/work_item.dart';

class BookingDescription extends StatelessWidget {
  const BookingDescription({
    super.key,
    required this.rego,
    required this.bookingEntries,
  });

  final String rego;
  final List<BookingEntry> bookingEntries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: Text('Vehical Rego: $rego'),
        ),
        const Text(' Work Items'),
        for (int i = 0; i < bookingEntries.length; i++)
          Expanded(child: Text(' ${i + 1} - ${bookingEntries[i].serviceName}')),
      ],
    );
  }
}

class BookingListItem extends StatelessWidget {
  const BookingListItem(
      {super.key, required this.rego, required this.bookingEntries});
  final String rego;
  final List<BookingEntry> bookingEntries;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) =>
                WorkItemPage(rego: rego, bookingEntries: bookingEntries),
          ),
        );
      },
      child: SizedBox(
        height: 100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: BookingDescription(
                      rego: rego, bookingEntries: bookingEntries),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
