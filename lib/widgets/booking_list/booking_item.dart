import 'package:flutter/material.dart';
// import 'package:workmate_app/model/service_item.dart';
import 'package:workmate_app/widgets/booking_list/booking_calendar_container.dart';
import 'package:workmate_app/widgets/work_item/work_item.dart';

class UIConstants {
  static const double padding = 8.0;
}

class BookingDescription extends StatelessWidget {
  const BookingDescription({
    super.key,
    required this.rego,
    required this.bookingEntries,
  });

  final String rego;
  final List<BookingEntry> bookingEntries;

 String formatDuration(int durationInMinutes) {
    final int minutes = durationInMinutes;
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else {
      return '${remainingMinutes}m';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UIConstants.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: UIConstants.padding),
            child: Text(
              'Registration Number: $rego',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: UIConstants.padding),
            child: Text(
              'Items',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          for (int i = 0; i < bookingEntries.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: UIConstants.padding / 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1} - ${bookingEntries[i].serviceName}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Duration: ${formatDuration(bookingEntries[i].servicDuration)}',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontStyle: FontStyle.italic,
                      color: Colors.black54,
                    ),
                  ),
                  ],
              ),
            ),
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
