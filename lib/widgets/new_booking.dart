import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:workmate_app/model/service_item.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;

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
  final _enteredQuantity = 1;
  var _isSending = false;
  final List<ServiceItem> serviceOffers = [];
  int _currentStep = 0;
  final int _selectedServiceId = -1;
  var selectedServiceOffer;
  bool offersLoaded = false;

  DateTime bookingDateTime = DateTime.now();

  final vehicalMakeController = TextEditingController();
  final vehicalModelController = TextEditingController();

  void _loadServiceItems(String make, String model) async {
    final url =
        Uri.http('192.168.0.141:8080', '/config/service-offers/$make/$model');

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception('Failed to fetch grocery items. Please try again later.');
    }

    final List<dynamic> serviceOffersData = json.decode(response.body);

    for (final item in serviceOffersData) {
      setState(() {
        serviceOffers.add(
          ServiceItem(
              serviceItemId: item['id'], serviceItem: item['serviceName']),
        );
        selectedServiceOffer ??= serviceOffers.first.serviceItemId;
      });
    }

    offersLoaded = true;
  }

  Future<void> _createCustomer() async {
    final url = Uri.http('192.168.0.141:8080', '/v1/customer');
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
    final url = Uri.http('192.168.0.141:8080', '/v1/vehicle');
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
    final url = Uri.http('192.168.0.141:8080', '/v1/booking');

    final String formattedBookingDateTime =
        serverDateFormater.format(bookingDateTime);
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'customerPhone': _enteredPhoneNumber,
            'rego': _enteredRego,
            'serviceItemId': selectedServiceOffer,
            'bookingDateTime': formattedBookingDateTime
          },
        ));
    return response.statusCode;
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isSending = true;
      });
      final url = Uri.https(
          'flutter-prep-default-rtdb.firebaseio.com', 'shopping-list.json');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(
          {
            'name': '',
            'quantity': '',
            'category': '',
          },
        ),
      );

      final Map<String, dynamic> resData = json.decode(response.body);

      if (!context.mounted) {
        return;
      }

      // Navigator.of(context).pop(
      //   Booking(
      //     id: resData['name'],
      //     name: _enteredName,
      //     quantity: _enteredQuantity,
      //     category: _selectedCategory,
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Add a new booking'),
        ),
        body: Form(
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
                  _loadServiceItems(
                      vehicalMakeController.text, vehicalModelController.text);
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
                content: Column(children: [
                  DropdownButtonFormField(
                    value: selectedServiceOffer,
                    items: [
                      for (final serviceOffer in serviceOffers)
                        DropdownMenuItem(
                          value: serviceOffer.serviceItemId,
                          child: Row(
                            children: [
                              const SizedBox(width: 6),
                              Text(serviceOffer.serviceItem),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedServiceOffer = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: () {
                        picker.DatePicker.showDateTimePicker(context,
                            showTitleActions: true,
                            minTime: DateTime(2024, 5, 5, 20, 50),
                            maxTime: DateTime(3020, 6, 7, 05, 09),
                            onConfirm: (date) {
                          bookingDateTime = date;
                        }, locale: picker.LocaleType.en);
                      },
                      child: const Text(
                        'Select a booking date-time',
                      )),
                ]),
                isActive: _currentStep >= 2,
              ),
            ],
          ),
        ));
  }
}
