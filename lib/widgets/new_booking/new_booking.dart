import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:workmate_app/model/service_item.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:workmate_app/utils/responsive_utils/new_bookings/new_booking_util.dart';
import 'package:workmate_app/widgets/new_booking/add_service_item.dart';

// Config
import '../../config/backend_config.dart';

class NewBooking extends StatefulWidget {
  const NewBooking({super.key});

  @override
  State<NewBooking> createState() {
    return _NewBookingState();
  }
}

class _NewBookingState extends State<NewBooking> {
  final _formKey = GlobalKey<FormState>();
  final DateFormat serverDateFormater = DateFormat('yyyy-MM-ddTHH:mm:ss');
  var _enteredFirstName = '';
  var _enteredLasttName = '';
  var _enteredPhoneNumber = '';
  var _enteredMake = '';
  var _enteredModel = '';
  var _enteredRego = '';
  final List<ServiceOffer> serviceOffers = [];
  int _currentStep = 0;
  var selectedServiceItemId;
  List<ServiceOffer> selectedServiceOffers = [];
  bool offersLoaded = false;

  DateTime? bookingDateTime;

  final vehicalMakeController = TextEditingController();
  final vehicalModelController = TextEditingController();

  void _loadServiceItems(String make, String model) async {
    final url = BackendConfig.getUri('config/service-offers/$make/$model');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception(
          'Failed to fetch service offers. Please try again later.');
    }

    final List<dynamic> serviceOffersData = json.decode(response.body);

    for (final item in serviceOffersData) {
      setState(() {
        serviceOffers.add(
          ServiceOffer(
              id: item['id'], name: item['serviceName'], bookingRef: ''),
        );
        selectedServiceItemId ??= serviceOffers.first.id;
      });
    }
    offersLoaded = true;
  }

  Future<void> _createCustomer() async {
    final url = BackendConfig.getUri('v1/customer');
    http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'firstName': _enteredFirstName,
            'lastName': _enteredLasttName,
            'phone': _enteredPhoneNumber,
          },
        ));
  }

  Future<void> _createServiceVehical() async {
    final url = BackendConfig.getUri('v1/vehicle');
    http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'rego': _enteredRego,
            'make': _enteredMake,
            'model': _enteredModel,
          },
        ));
  }

  Future<int> _createBooking() async {
    List<String> selectedOfferIds =
        selectedServiceOffers.map((offer) => offer.id.toString()).toList();
    final url = BackendConfig.getUri('v1/booking');
    final String formattedBookingDateTime =
        serverDateFormater.format(bookingDateTime!);
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'customerPhone': _enteredPhoneNumber,
            'rego': _enteredRego,
            'serviceItemId': selectedServiceItemId,
            'serviceItemIds': selectedOfferIds,
            'bookingDateTime': formattedBookingDateTime
          },
        ));
    return response.statusCode;
  }

  void openServiceSelectionOverlay() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => NewServiceItem(
          onAddServiceOffer: _addServiceoffer, serviceOffers: serviceOffers),
    );
  }

  void _addServiceoffer(ServiceOffer serviceOffer) {
    setState(() {
      selectedServiceOffers.add(serviceOffer);
    });
  }

  // Booking data time picker for web
  void _pickDateTime() async {
    // Limits
    final min = DateTime(2024, 5, 5, 20, 50);
    final max = DateTime(3020, 6, 7, 5, 9);

    if (kIsWeb || MediaQuery.of(context).size.width > 600) {
      // Web: use Material dialogs
      final now = DateTime.now();
      final initial = bookingDateTime ?? now;

      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(min.year, min.month, min.day),
        lastDate: DateTime(max.year, max.month, max.day),
      );
      if (date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time == null) return;

      final combined =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);

      if (combined.isBefore(min) || combined.isAfter(max)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please pick a time within the allowed range.')),
        );
        return;
      }

      setState(() => bookingDateTime = combined);
    } else {
      // Mobile: bottom-sheet from the package
      picker.DatePicker.showDateTimePicker(
        context,
        showTitleActions: true,
        minTime: min,
        maxTime: max,
        currentTime: bookingDateTime ?? DateTime.now(),
        onConfirm: (date) => setState(() => bookingDateTime = date),
        locale: picker.LocaleType.en,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // final ThemeData theme = Theme.of(context);
    // final ColorScheme colorScheme = theme.colorScheme;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a new booking'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
                child: Container(
              width: ResponsiveFormUtils.getMaxFormWidth(context),
              padding: ResponsiveFormUtils.getFormPadding(context),
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 3) {
                      setState(() {
                        _currentStep += 1;
                      });
                    }
                    if (_currentStep == 2) {
                      if (!offersLoaded) {
                        _loadServiceItems(vehicalMakeController.text,
                            vehicalModelController.text);
                      }
                    }
                    if (_currentStep == 3) {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        //Create customer
                        _createCustomer();
                        //Create service Vehicle
                        _createServiceVehical();
                        //Create booking
                        _createBooking();
                        setState(() {
                          _currentStep -= 1;
                        });
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() {
                        _currentStep -= 1;
                      });
                    }
                  },
                  steps: [
                    Step(
                      title: const Text('Customer'),
                      content: Column(children: [
                        TextFormField(
                          maxLength: 20,
                          decoration: const InputDecoration(
                            label: Text('First name'),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length <= 1 ||
                                value.trim().length > 20) {
                              return 'Must be between 1 and 20 characters.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // if (value == null) {
                            //   return;
                            // }
                            _enteredFirstName = value!;
                          },
                        ),
                        TextFormField(
                          maxLength: 20,
                          decoration: const InputDecoration(
                            label: Text('Last name'),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length <= 1 ||
                                value.trim().length > 20) {
                              return 'Must be between 1 and 20 characters.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // if (value == null) {
                            //   return;
                            // }
                            _enteredLasttName = value!;
                          },
                        ),
                        TextFormField(
                          maxLength: 15,
                          decoration: const InputDecoration(
                            label: Text('Phone'),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length <= 1 ||
                                value.trim().length > 15) {
                              return 'Must be between 1 and 15 characters.';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // if (value == null) {
                            //   return;
                            // }
                            _enteredPhoneNumber = value!;
                          },
                        )
                      ]),
                      isActive: _currentStep >= 0,
                    ),
                    Step(
                      title: const Text('Vehical'),
                      content: Column(children: [
                        TextFormField(
                          maxLength: 6,
                          decoration: const InputDecoration(
                            label: Text('Rego'),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length <= 1 ||
                                value.trim().length > 7) {
                              return 'Rego must be 6 charachers';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // if (value == null) {
                            //   return;
                            // }
                            _enteredRego = value!;
                          },
                        ),
                        TextFormField(
                          maxLength: 15,
                          controller: vehicalMakeController,
                          decoration: const InputDecoration(
                            label: Text('Make'),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length <= 1 ||
                                value.trim().length > 15) {
                              return 'Make is not valid';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // if (value == null) {
                            //   return;
                            // }
                            _enteredMake = value!;
                          },
                        ),
                        TextFormField(
                          maxLength: 15,
                          controller: vehicalModelController,
                          decoration: const InputDecoration(
                            label: Text('Model'),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.trim().length <= 1 ||
                                value.trim().length > 15) {
                              return 'Model is not valid';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            // if (value == null) {
                            //   return;
                            // }
                            _enteredModel = value!;
                          },
                        )
                      ]),
                      isActive: _currentStep >= 1,
                    ),
                    Step(
                      title: const Text('Service'),
                      content: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            // Date Time picker
                            OutlinedButton(
                                onPressed: _pickDateTime,
                                child: Text(
                                  bookingDateTime != null
                                      ? DateFormat.yMEd()
                                          .add_jms()
                                          .format(bookingDateTime!)
                                      : 'Select a booking date-time',
                                )),
                            OutlinedButton(
                                onPressed: openServiceSelectionOverlay,
                                child: const Text(
                                  'Select a service',
                                )),
                            const SizedBox(height: 10.0),
                            const Text('Currently selected services:'),
                            SizedBox(
                              height: 200.0,
                              child: selectedServiceOffers.isEmpty
                                  ? const Text(
                                      'No services selected for the booking',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w100,
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: selectedServiceOffers.length,
                                      itemBuilder: (context, index) {
                                        final item =
                                            selectedServiceOffers[index];
                                        return Dismissible(
                                          // Each Dismissible must contain a Key. Keys allow Flutter to
                                          // uniquely identify widgets.
                                          key: Key(item.id.toString()),
                                          // Provide a function that tells the app
                                          // what to do after an item has been swiped away.
                                          onDismissed: (direction) {
                                            // Remove the item from the data source.
                                            setState(() {
                                              selectedServiceOffers
                                                  .removeAt(index);
                                            });

                                            // Then show a snackbar.
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        '${item.name} removed from the sheduled services')));
                                          },
                                          // Show a red background as the item is swiped away.
                                          background:
                                              Container(color: Colors.blueGrey),
                                          child: Card(
                                            child: ListTile(
                                              tileColor: const Color.fromARGB(
                                                  255, 179, 208, 223),
                                              visualDensity:
                                                  const VisualDensity(
                                                      horizontal: 0,
                                                      vertical: -4),
                                              contentPadding:
                                                  const EdgeInsets.all(5),
                                              shape: RoundedRectangleBorder(
                                                side: const BorderSide(
                                                    color: Color.fromARGB(
                                                        255, 88, 97, 69),
                                                    width: 1),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              title: Text(item.name),
                                              trailing: const Icon(
                                                  Icons.arrow_circle_left,
                                                  color: Color.fromARGB(
                                                      255, 232, 130, 90)),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ]),
                      isActive: _currentStep >= 2,
                    ),
                  ],
                ),
              ),
            )),
          ),
        ));
  }
}
