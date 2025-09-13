// New Logic......................................................................
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
    final isAbbreviated = ResponsiveBookingListUtils.isMobileOrTablet(context);
    final visibleEntries =
        isAbbreviated ? bookingEntries.take(1) : bookingEntries;

    return Padding(
      padding:
          ResponsiveBookingListUtils.getDescriptionPaddingWidthAware(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Text(
              'Vehical Rego: $rego',
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2.0),
          const Text(
            ' Work Items',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          for (int i = 0; i < visibleEntries.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                ' ${i + 1} - ${visibleEntries.elementAt(i).serviceName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (isAbbreviated && bookingEntries.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text(
                '+${bookingEntries.length - 1} more...',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class BookingListItem extends StatelessWidget {
  const BookingListItem({
    super.key,
    required this.rego,
    required this.bookingEntries,
  });
  final String rego;
  final List<BookingEntry> bookingEntries;

  // Popup dialog for work items
  void _showWorkItemsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Work Items for $rego',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            height: 300.0,
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehical Rego: $rego',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Work Items',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: SingleChildScrollView(
                    // Scrollable for all items
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < bookingEntries.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              ' ${i + 1} - ${bookingEntries[i].serviceName}',
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              // Navigate button to Manage Bookings
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => WorkItemPage(
                      rego: rego,
                      bookingEntries: bookingEntries,
                    ),
                  ),
                );
              },
              child: const Text('Manage Booking'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ResponsiveBookingListUtils.isMobileOrTablet(context)
          ? () => _showWorkItemsPopup(context) // Popup for mobile/tablet
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => WorkItemPage(
                    rego: rego,
                    bookingEntries: bookingEntries,
                  ),
                ),
              ), // Web: direct navigation
      child: SizedBox(
        height: ResponsiveBookingListUtils.getItemHeightWidthAware(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: BookingDescription(
                    rego: rego,
                    bookingEntries: bookingEntries,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Old logic ................................................................................

// import 'package:flutter/material.dart';

// // utils
// import '../../utils/responsive_utils/booking_list/calender_list_util.dart';

// // Widgets
// import '../../widgets/booking_list/booking_calendar_container.dart';
// import '../../widgets/work_item/work_item.dart';

// class BookingDescription extends StatelessWidget {
//   const BookingDescription({
//     super.key,
//     required this.rego,
//     required this.bookingEntries,
//   });

//   final String rego;
//   final List<BookingEntry> bookingEntries;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: ResponsiveBookingListUtils.getDescriptionPadding(context),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min, // Height to fit content only
//         children: <Widget>[
//           Center(
//             child: Text(
//               'Vehical Rego: $rego',
//               style: const TextStyle(fontWeight: FontWeight.w600),
//               maxLines: 1, // Prevent overflow for long rego numbers
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           const SizedBox(height: 4.0),
//           const Text(
//             ' Work Items',
//             style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           for (int i = 0; i < bookingEntries.length; i++)
//             Padding(
//                 padding: const EdgeInsets.only(top: 4.0),
//                 child: Text(
//                   ' ${i + 1} - ${bookingEntries[i].serviceName}',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 )),
//         ],
//       ),
//     );
//   }
// }

// class BookingListItem extends StatelessWidget {
//   const BookingListItem(
//       {super.key, required this.rego, required this.bookingEntries});
//   final String rego;
//   final List<BookingEntry> bookingEntries;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (ctx) =>
//                 WorkItemPage(rego: rego, bookingEntries: bookingEntries),
//           ),
//         );
//       },
//       child: SizedBox(
//         height: ResponsiveBookingListUtils.getItemHeight(context),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             Column(
//               children: <Widget>[
//                 Expanded(
//                   child: BookingDescription(
//                       rego: rego, bookingEntries: bookingEntries),
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
