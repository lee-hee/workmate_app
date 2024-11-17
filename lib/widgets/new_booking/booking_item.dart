import 'package:flutter/material.dart';
import 'package:workmate_app/widgets/work_item/work_item.dart';

class _BookingDescription extends StatelessWidget {
  const _BookingDescription({
    required this.rego,
    required this.serviceType,
    required this.bookingRef,
    required this.bookingTime,
    required this.customerPhone,
    required this.duration,
  });

  final String rego;
  final String serviceType;
  final String bookingRef;
  final String bookingTime;
  final String customerPhone;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          rego,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Padding(padding: EdgeInsets.only(bottom: 2.0)),
        Expanded(
          child: Text(
            serviceType,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
        ),
        Text(
          'Booking ref: $bookingRef',
          style: const TextStyle(
            fontSize: 12.0,
            color: Colors.black87,
          ),
        ),
        Text(
          'Start at : $bookingTime - $duration',
          style: const TextStyle(
            fontSize: 12.0,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class BookingListItem extends StatelessWidget {
  const BookingListItem({
    super.key,
    required this.thumbnail,
    required this.rego,
    required this.serviceType,
    required this.bookingRef,
    required this.bookingTime,
    required this.customerPhone,
    required this.duration,
  });

  final Widget thumbnail;
  final String rego;
  final String serviceType;
  final String bookingRef;
  final String bookingTime;
  final String customerPhone;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => const WorkItemPage(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1.0,
                child: thumbnail,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 0.0, 2.0, 0.0),
                  child: _BookingDescription(
                    rego: rego,
                    serviceType: serviceType,
                    bookingRef: bookingRef,
                    bookingTime: bookingTime,
                    duration: duration,
                    customerPhone: customerPhone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
