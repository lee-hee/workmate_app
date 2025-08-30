import 'package:flutter/material.dart';

// utils
import '../../utils/responsive_utils/booking_list/calender_list_util.dart';

// Widgets
import '../../widgets/booking_list/booking_calendar_container.dart';
import '../../widgets/work_item/work_item.dart';

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
    return Padding(
      padding: ResponsiveBookingListUtils.getDescriptionPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Text(
              'Vehical Rego: $rego',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            ' Work Items',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          for (int i = 0; i < bookingEntries.length; i++)
            Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(' ${i + 1} - ${bookingEntries[i].serviceName}')),
        ],
      ),
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
        height: ResponsiveBookingListUtils.getItemHeight(context),
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
