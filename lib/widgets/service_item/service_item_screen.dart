// import 'package:flutter/material.dart';

// class ServiceItemScreen extends StatefulWidget {
//   const ServiceItemScreen({super.key});

//   @override
//   State<ServiceItemScreen> createState() => _ScaffoldExampleState();
// }

// class _ScaffoldExampleState extends State<ServiceItemScreen> {
//   int _count = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add a service Item'),
//       ),
//       body: Center(child: Text('You have added $_count service items.')),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => setState(() => _count++),
//         tooltip: 'Service item',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

class ServiceItemScreen extends StatefulWidget {
  const ServiceItemScreen({super.key});

  @override
  State<ServiceItemScreen> createState() {
    return _ServiceItemScreenState();
  }
}

class _ServiceItemScreenState extends State<ServiceItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serviceController = TextEditingController();
  final _priceController = TextEditingController();

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

      final make = _makeController.text;
      final model = _modelController.text;
      final service = _serviceController.text;
      final price = double.tryParse(_priceController.text) ?? 0.0;
      final duration =
          '${_selectedDuration.hour}h ${_selectedDuration.minute}m';

      // Use this data as required (e.g., send it to an API or save locally)
      print('Make: $make');
      print('Model: $model');
      print('Service: $service');
      print('Price: $price');
      print('Duration: $duration');

      // Clear the form after saving
      _formKey.currentState?.reset();
      _makeController.clear();
      _modelController.clear();
      _serviceController.clear();
      _priceController.clear();
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
    _serviceController.clear();
    _priceController.clear();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    maxLength: 15,
                    controller: _makeController,
                    decoration: const InputDecoration(labelText: 'Make'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid make';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    maxLength: 15,
                    controller: _modelController,
                    decoration: const InputDecoration(labelText: 'Model'),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _serviceController,
                    decoration: const InputDecoration(labelText: 'Service'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid service';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price (\$)'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null ||
                          value.isEmpty ||
                          double.tryParse(value) == null) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: _pickDuration,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Duration (Hh:Mm)',
                        border: const OutlineInputBorder(),
                        errorText: _isDurationValid
                            ? null
                            : 'Duration cannot be empty',
                      ),
                      child: Text(
                        '${_selectedDuration.hour.toString().padLeft(2, '0')}h:${_selectedDuration.minute.toString().padLeft(2, '0')}m',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _saveServiceItem,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(
                            255, 18, 107, 125), // Text color
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
                            borderRadius:
                                BorderRadius.circular(4)), // Button shape
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
    );
  }
}
