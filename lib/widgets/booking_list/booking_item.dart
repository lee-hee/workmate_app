import 'package:flutter/material.dart';
import 'package:workmate_app/model/service_item.dart';
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
        Expanded(child: Text(rego)),
        const Text('Items'),
        for (int i = 0; i < bookingEntries.length; i++)
          Expanded(child: Text('${i + 1} - ${bookingEntries[i].serviceName}')),
        // const Padding(padding: EdgeInsets.only(bottom: 2.0)),
        // Expanded(
        //   child: Text(
        //     rego,
        //     maxLines: 2,
        //     overflow: TextOverflow.ellipsis,
        //     style: const TextStyle(
        //       fontSize: 12.0,
        //       color: Colors.black54,
        //     ),
        //   ),
        // ),
        // Text(
        //   'Booking ref: $bookingRef',
        //   style: const TextStyle(
        //     fontSize: 12.0,
        //     color: Colors.black87,
        //   ),
        // ),
        // Text(
        //   'Start at : $bookingTime - $duration',
        //   style: const TextStyle(
        //     fontSize: 12.0,
        //     color: Colors.black54,
        //   ),
        // ),
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
        height: 170,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
