import 'package:flutter/material.dart';
import 'package:workmate_app/model/service_item.dart';

class NewServiceItem extends StatefulWidget {
  const NewServiceItem(
      {super.key,
      required this.onAddServiceOffer,
      required this.serviceOffers});

  final void Function(ServiceOffer serviceOffer) onAddServiceOffer;
  final List<ServiceOffer> serviceOffers;

  @override
  State<NewServiceItem> createState() {
    return _NewServiceItemState();
  }
}

class _NewServiceItemState extends State<NewServiceItem> {
  late ServiceOffer _selectedOffer;

  void _submitSlectedOffersData() {
    widget.onAddServiceOffer(_selectedOffer);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('Select and add a service'),
          Row(
            children: [
              DropdownButton(
                value: widget.serviceOffers[0],
                items: [
                  for (final serviceOffer in widget.serviceOffers)
                    DropdownMenuItem(
                      value: serviceOffer,
                      child: Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(serviceOffer.name),
                        ],
                      ),
                    )
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedOffer = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _submitSlectedOffersData,
                child: const Text('Add service'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
