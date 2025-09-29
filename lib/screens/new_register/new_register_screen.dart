import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Utils
import '../../utils/common/custom_snackbar.dart';
import '../../utils/responsive_utils/new_bookings/new_booking_util.dart';

// Config
import '../../config/backend_config.dart';

// Widgets
import '../home_view/work_action_home_screen.dart';
import '../new_booking/new_booking_screen.dart';

class NewRegisterScreen extends StatefulWidget {
  const NewRegisterScreen({super.key});

  @override
  State<NewRegisterScreen> createState() {
    return _NewRegisterState();
  }
}

class _NewRegisterState extends State<NewRegisterScreen> {
  int _currentStep = 0;
  String? _regoError;
  // ignore: unused_field
  bool _isCheckingRego = false;
  bool _isCheckingPhone = false; // check phone exists
  String? _phoneExistMessage;
  bool _isCustomerSelected = false;
  Map<String, dynamic>? _existingCustomer;
  Timer? _debounce;

  // Customer fields
  final _customerFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  // Vehicle fields
  final _vehicleFormKey = GlobalKey<FormState>();
  var _enteredRego = '';
  var _enteredMake = '';
  var _enteredModel = '';
  var _enteredBodyColor = '';
  var _enteredVinNumber = '';

  final vehicleMakeController = TextEditingController();
  final vehicleModelController = TextEditingController();

  // Check if customer exists by phone number
  Future<Map<String, dynamic>?> _checkCustomerExists(String phone) async {
    final url = BackendConfig.getUri('v1/customer/$phone');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Customer not found
      } else {
        print('Error checking customer: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error checking customer: $e');
      return null;
    }
  }

  // Create customer
  Future<Map<String, dynamic>?> _createCustomer() async {
    if (_isCustomerSelected && _existingCustomer != null) {
      return _existingCustomer; // Reuse existing customer
    }
    final url = BackendConfig.getUri('v1/customer');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'email': _emailController.text,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Failed to create customer: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error creating customer: $e');
      return null;
    }
  }

  // Create service vehicle
  Future<void> _createServiceVehicle(int customerId) async {
    final url = BackendConfig.getUri('v1/vehicle');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'rego': _enteredRego,
          'make': _enteredMake,
          'model': _enteredModel,
          'bodyColor': _enteredBodyColor,
          'vinNumber': _enteredVinNumber,
          'customerId': customerId,
        }),
      );
      if (response.statusCode != 200) {
        CustomSnackBar.showMessageSnackBar(
            context, 'Failed to create vehicle: ${response.statusCode}');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(context, 'Error creating vehicle: $e');
    }
  }

  // Check if vehicle rego exists
  Future<bool> _checkRegoExists(String rego) async {
    final url = BackendConfig.getUri('v1/booking/check/$rego');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['exists'] == true;
    }
    return false;
  }

  // Show success dialog with countdown
  void _showSuccessDialog(String rego) {
    int countdown = 15;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (countdown == 0) {
                t.cancel();
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewBookingScreen(
                      customerPhone: _phoneController.text,
                      rego: rego,
                    ),
                  ),
                );
              } else {
                setState(() => countdown--);
              }
            });

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text("Registration Done!"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'Vehicle $rego registered successfully!\n\n'
                    'To add service items for $rego, auto navigating to service page in $countdown seconds...',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => NewBookingScreen(
                          customerPhone: _phoneController.text,
                          rego: rego,
                        ),
                      ),
                    );
                  },
                  child: const Text("Continue"),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const WorkActionHomeScreen()),
                    );
                  },
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    vehicleMakeController.dispose();
    vehicleModelController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register a New Vehicle')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: ResponsiveFormUtils.getMaxFormWidth(context),
              padding: ResponsiveFormUtils.getFormPadding(context),
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: () async {
                  if (_currentStep == 0) {
                    if (_customerFormKey.currentState!.validate()) {
                      _customerFormKey.currentState!.save();
                      setState(() => _currentStep += 1);
                    } else {
                      CustomSnackBar.showMessageSnackBar(
                        context,
                        'Please complete all customer fields.',
                      );
                    }
                  } else if (_currentStep == 1) {
                    if (_regoError != null) {
                      CustomSnackBar.showMessageSnackBar(
                        context,
                        _regoError!,
                      );
                      return;
                    }

                    if (_vehicleFormKey.currentState!.validate()) {
                      _vehicleFormKey.currentState!.save();
                      final customer = await _createCustomer();
                      if (customer != null) {
                        await _createServiceVehicle(customer['id']);
                        _showSuccessDialog(_enteredRego);
                      }
                    } else {
                      CustomSnackBar.showMessageSnackBar(
                        context,
                        'Please complete all vehicle fields.',
                      );
                    }
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep -= 1;
                      _isCustomerSelected = false;
                      _existingCustomer = null;
                      _phoneController.clear();
                      _firstNameController.clear();
                      _lastNameController.clear();
                      _emailController.clear();
                    });
                  }
                },
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child:
                            Text(_currentStep == 1 ? 'Register' : 'Continue'),
                      ),
                      const SizedBox(width: 8),
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                    ],
                  );
                },
                steps: [
                  Step(
                    title: const Text('Customer'),
                    content: Form(
                      key: _customerFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            maxLength: 15,
                            decoration: InputDecoration(
                              label: const Text('Phone'),
                              helper: _phoneExistMessage != null
                                  ? Text(
                                      _phoneExistMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    )
                                  : null,
                              counterText: _phoneExistMessage != null
                                  ? ''
                                  : null, // Hide counter when message is shown
                              suffixIcon: _isCheckingPhone
                                  ? const CircularProgressIndicator()
                                  : _existingCustomer != null &&
                                          !_isCustomerSelected
                                      ? TextButton(
                                          // icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              _isCustomerSelected = true;
                                              _firstNameController.text =
                                                  _existingCustomer![
                                                          'firstName'] ??
                                                      '';
                                              _lastNameController.text =
                                                  _existingCustomer![
                                                          'lastName'] ??
                                                      '';
                                              _emailController.text =
                                                  _existingCustomer!['email'] ??
                                                      '';
                                            });
                                          },
                                          child: const Text('Add'),
                                        )
                                      : null,
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
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) {
                                _debounce!.cancel();
                              }
                              _debounce = Timer(
                                  const Duration(milliseconds: 300), () async {
                                if (value.length >= 1) {
                                  setState(() {
                                    _isCheckingPhone = true;
                                    _existingCustomer = null;
                                    _isCustomerSelected = false;
                                    _phoneExistMessage = null;
                                    // Clear controllers when no customer is selected
                                    if (!_isCustomerSelected) {
                                      _firstNameController.clear();
                                      _lastNameController.clear();
                                      _emailController.clear();
                                    }
                                  });
                                  final customer =
                                      await _checkCustomerExists(value);
                                  setState(() {
                                    _isCheckingPhone = false;
                                    _existingCustomer = customer;
                                    _phoneExistMessage = customer != null
                                        ? 'Customer already registered. Click Add to use.'
                                        : null;
                                  });
                                } else {
                                  setState(() {
                                    _phoneExistMessage = null;
                                    // Clear controllers when input is too short
                                    _firstNameController.clear();
                                    _lastNameController.clear();
                                    _emailController.clear();
                                  });
                                }
                              });
                            },
                            onSaved: (value) => _phoneController.text = value!,
                          ),
                          TextFormField(
                            controller: _firstNameController,
                            maxLength: 20,
                            decoration: const InputDecoration(
                                label: Text('First name')),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length <= 1 ||
                                  value.trim().length > 20) {
                                return 'Must be between 1 and 20 characters.';
                              }
                              return null;
                            },
                            enabled: !_isCustomerSelected,
                            onSaved: (value) =>
                                _firstNameController.text = value!,
                          ),
                          TextFormField(
                            controller: _lastNameController,
                            maxLength: 20,
                            decoration:
                                const InputDecoration(label: Text('Last name')),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length <= 1 ||
                                  value.trim().length > 20) {
                                return 'Must be between 1 and 20 characters.';
                              }
                              return null;
                            },
                            enabled: !_isCustomerSelected,
                            onSaved: (value) =>
                                _lastNameController.text = value!,
                          ),
                          TextFormField(
                            controller: _emailController,
                            maxLength: 50,
                            decoration:
                                const InputDecoration(label: Text('Email')),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            enabled: !_isCustomerSelected,
                            onSaved: (value) => _emailController.text = value!,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 0,
                  ),
                  Step(
                    title: const Text('Vehicle'),
                    content: Form(
                      key: _vehicleFormKey,
                      child: Column(
                        children: [
                          TextFormField(
                            maxLength: 6,
                            decoration: InputDecoration(
                              label: const Text('Rego'),
                              errorText: _regoError,
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  !RegExp(r'^[a-zA-Z0-9]{6}$')
                                      .hasMatch(value)) {
                                return 'Rego must be 6 alphanumeric characters';
                              }
                              if (_regoError != null) {
                                return _regoError;
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) {
                                _debounce!.cancel();
                              }
                              _debounce = Timer(
                                  const Duration(milliseconds: 300), () async {
                                if (value.length == 6) {
                                  setState(() {
                                    _isCheckingRego = true;
                                    _regoError = null;
                                  });
                                  final exists = await _checkRegoExists(value);
                                  setState(() {
                                    _isCheckingRego = false;
                                    _regoError = exists
                                        ? 'This vehicle is already registered'
                                        : null;
                                  });
                                }
                              });
                            },
                            onSaved: (value) => _enteredRego = value!,
                          ),
                          TextFormField(
                            maxLength: 15,
                            controller: vehicleMakeController,
                            decoration:
                                const InputDecoration(label: Text('Make')),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.trim().length <= 1 ||
                                  value.trim().length > 15) {
                                return 'Must be between 1 and 15 characters.';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredMake = value!,
                          ),
                          TextFormField(
                            maxLength: 15,
                            controller: vehicleModelController,
                            decoration:
                                const InputDecoration(label: Text('Model')),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Model is required';
                              }
                              if (value.trim().length < 2 ||
                                  value.trim().length > 15) {
                                return 'Must be 2-15 characters';
                              }
                              if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                                return 'Only letters and numbers';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredModel = value!,
                          ),
                          TextFormField(
                            maxLength: 20,
                            decoration: const InputDecoration(
                                label: Text('Body Color')),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Body color is required';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredBodyColor = value!,
                          ),
                          TextFormField(
                            maxLength: 17,
                            decoration: const InputDecoration(
                                label: Text('VIN Number')),
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length != 17) {
                                return 'VIN must be 17 characters';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredVinNumber = value!,
                          ),
                        ],
                      ),
                    ),
                    isActive: _currentStep >= 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
