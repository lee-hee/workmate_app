import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Config
import '../../../config/backend_config.dart';

// Utils
import '../../../utils/responsive_utils/service_item/service_item_util.dart';

class ServiceItemRegisterScreen extends StatefulWidget {
  const ServiceItemRegisterScreen({super.key});

  @override
  State<ServiceItemRegisterScreen> createState() {
    return _ServiceItemRegisterScreenState();
  }
}

class _ServiceItemRegisterScreenState extends State<ServiceItemRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortNameController = TextEditingController();

  TimeOfDay _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
  bool _isDurationValid = true;

  void _pickDuration() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      helpText: 'Select Duration (Hh:Mm)',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDuration = picked;
        _isDurationValid = true; // Reset validation on successful selection
      });
    }
  }

  void _saveServiceItem() {
    if (_formKey.currentState!.validate() && _validateDuration()) {
      _formKey.currentState!.save();

      final make = _makeController.text.trim();
      final model = _modelController.text.trim();
      final serviceName = _serviceNameController.text.trim();
      final servicePrice =
          double.tryParse(_servicePriceController.text.trim()) ?? 0.0;
      final serviceDurationMinutes =
          (_selectedDuration.hour * 60) + _selectedDuration.minute;
      final description = _descriptionController.text.trim();
      final shortName = _shortNameController.text.trim();

      // Use this data as required (e.g., send it to an API or save locally)
      print('Make: $make');
      print('Model: $model');
      print('serviceName: $serviceName');
      print('servicePrice: $servicePrice');
      print('Duration: $serviceDurationMinutes');

      // Function to send data to the API
      void sendserviceNameItems(
          String make,
          String model,
          String serviceName,
          String servicePrice,
          String serviceDurationMinutes,
          String description,
          String shortName) async {
        final url = BackendConfig.getUri('config/service-item');

        // Prepare the data to send
        final Map<String, dynamic> data = {
          'make': make,
          'model': model,
          'serviceName': serviceName,
          'servicePrice': servicePrice,
          'serviceDurationMinutes': serviceDurationMinutes,
          'description': description,
          'shortName': shortName,
          'active': 1, // Default to active
        };
        // Convert the data to JSON format
        final String jsonData = json.encode(data);

        // Send a POST request to the API
        try {
          final response = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonData,
          );

          // Check the response
          if (response.statusCode == 200) {
            // Successful response
            print('Data successfully sent to the API');
          } else {
            // Handle server errors (4xx or 5xx)
            print('Failed to send data: ${response.statusCode}');
          }
        } catch (e) {
          // Handle any errors that occur during the request
          print('Error: $e');
        }
      }

      // Send data to the API
      sendserviceNameItems(make, model, serviceName, servicePrice.toString(),
          serviceDurationMinutes.toString(), description, shortName);

      // Clear the form after saving
      _formKey.currentState?.reset();
      _makeController.clear();
      _modelController.clear();
      _serviceNameController.clear();
      _servicePriceController.clear();
      _descriptionController.clear();
      _shortNameController.clear();
      setState(() {
        _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
        _isDurationValid = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service Item Saved!')),
      );
    }
  }

  bool _validateDuration() {
    if (_selectedDuration.hour == 0 && _selectedDuration.minute == 0) {
      setState(() {
        _isDurationValid = false;
      });
      return false;
    }
    return true;
  }

  void _cancelForm() {
    _formKey.currentState?.reset();
    _makeController.clear();
    _modelController.clear();
    _serviceNameController.clear();
    _servicePriceController.clear();
    _descriptionController.clear();
    _shortNameController.clear();
    setState(() {
      _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
      _isDurationValid = true;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a Service Item'),
      ),
      body: Align(
        alignment: ResponsiveServiceItemScreenUtils.getAlignment(
            context), // Center on web
        child: SizedBox(
          width: ResponsiveServiceItemScreenUtils.getMaxWidth(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Make
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        maxLength: 15,
                        controller: _makeController,
                        decoration: const InputDecoration(labelText: 'Make *'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid make';
                          }
                          return null;
                        },
                      ),
                    ),
                    // Model
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        maxLength: 15,
                        controller: _modelController,
                        decoration: const InputDecoration(labelText: 'Model *'),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.trim().length <= 1 ||
                              value.trim().length > 15) {
                            return 'Please enter a valid model';
                          }
                          return null;
                        },
                      ),
                    ),
                    // Service Name
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _serviceNameController,
                        decoration:
                            const InputDecoration(labelText: 'Service Name *'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid Service Name';
                          }
                          return null;
                        },
                      ),
                    ),
                    // Short Name
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _shortNameController,
                        decoration:
                            const InputDecoration(labelText: 'Short Name'),
                      ),
                    ),
                    // Description
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                      ),
                    ),
                    // Price
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _servicePriceController,
                        decoration:
                            const InputDecoration(labelText: 'Price (\$) *'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              double.tryParse(value) == null) {
                            return 'Please enter a valid Price';
                          }
                          return null;
                        },
                      ),
                    ),
                    // Duration
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: _pickDuration,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Duration (Hh:Mm) *',
                            border: const OutlineInputBorder(),
                            errorText: _isDurationValid
                                ? null
                                : 'Duration cannot be empty',
                          ),
                          child: Text(
                            '${_selectedDuration.hour.toString().padLeft(2, '0')}h:${_selectedDuration.minute.toString().padLeft(2, '0')}m',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _saveServiceItem,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 18, 107, 125),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelForm,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
