import 'package:flutter/material.dart';

// Models
import '../../model/service_item.dart';

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
  ServiceOffer? _selectedOffer; // Changed to nullable to handle empty list

  // Submit selected service offer data
  void _submitSelectedOffersData() {
    // Ensure a service is selected before adding
    // Show error if no service is selected
    if (_selectedOffer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service to add.')),
      );
      return;
    }
    widget.onAddServiceOffer(_selectedOffer!);
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    // Set default selection if serviceOffers is not empty
    if (widget.serviceOffers.isNotEmpty) {
      _selectedOffer = widget.serviceOffers[0];
    } else {
      _selectedOffer = null;
    }
  }

  // @override
  // void dispose() {
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 16, 16),
      child: Column(
        children: [
          const Text(
            'Select and add a service',
            style: TextStyle(fontSize: 25.0),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              InputDecorator(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                child: DropdownButtonHideUnderline(
                  // Wrap DropdownButton to hide underline
                  child: DropdownButton<ServiceOffer>(
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(2.5),
                    // value: widget.serviceOffers[0],
                    value: _selectedOffer, // Use the state variable
                    hint: widget.serviceOffers.isEmpty
                        ? const Text('No services available')
                        : null,
                    // Dropdown menu items - loop through serviceOffers
                    // items: [
                    //   for (final serviceOffer in widget.serviceOffers)
                    //     DropdownMenuItem(
                    //       value: serviceOffer,
                    //       child: Row(
                    //         children: [
                    //           const SizedBox(width: 6),
                    //           Text(serviceOffer.name,
                    //               style: const TextStyle(fontSize: 20.0)),
                    //         ],
                    //       ),
                    //     )
                    // ],
                    // onChanged: (value) {
                    //   if (value == null) {
                    //     return;
                    //   }
                    //   setState(() {
                    //     _selectedOffer = value;
                    //   });
                    // },

                    // Handle empty serviceOffers list
                    items: widget.serviceOffers.isEmpty
                        ? []
                        : [
                            for (final serviceOffer in widget.serviceOffers)
                              DropdownMenuItem(
                                value: serviceOffer,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 6),
                                    Text(serviceOffer.name,
                                        style: const TextStyle(fontSize: 20.0)),
                                  ],
                                ),
                              )
                          ],
                    // Disable onChanged if no services are available
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedOffer = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _submitSelectedOffersData,
                  child: const Text('Add service'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
