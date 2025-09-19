import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/common/custom_snackbar.dart';
import '../../utils/responsive_utils/service_item/service_item_util.dart';

class ServiceItemScreen extends StatefulWidget {
  final String? bookingRef;
  const ServiceItemScreen({super.key, this.bookingRef});

  @override
  State<ServiceItemScreen> createState() {
    return _ServiceItemScreenState();
  }
}

class _ServiceItemScreenState extends State<ServiceItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _searchController = TextEditingController();

  bool _isSearchingByRego = true; // true: rego, false: phone
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _serviceItems = []; // Store multiple service items
  String? _selectedBookingRef; // Track selected bookingRef

  TimeOfDay _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
  bool _isDurationValid = true;

  @override
  void initState() {
    super.initState();
    if (widget.bookingRef != null && widget.bookingRef!.isNotEmpty) {
      _selectedBookingRef = widget.bookingRef;
      _fetchBookingByRef(widget.bookingRef!);
      _fetchServiceItems(widget.bookingRef!);
    }
  }

  // Fetch booking details by bookingRef
  Future<void> _fetchBookingByRef(String bookingRef) async {
    final url = BackendConfig.getUri('v1/booking/by-ref/$bookingRef');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final bookings = json.decode(response.body) as List;
        if (bookings.isNotEmpty) {
          final booking = bookings[0];
          final rego = booking['rego'] as String;
          final vehicle = await _fetchVehicleByRego(rego);
          setState(() {
            _makeController.text = vehicle['make'] ?? '';
            _modelController.text = vehicle['model'] ?? '';
            _selectedBookingRef = bookingRef;
          });
        } else {
          CustomSnackBar.showMessageSnackBar(
              context, 'Booking not found for ref: $bookingRef');
        }
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Failed to fetch booking: ${response.statusCode}');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(context, 'Error fetching booking: $e');
    }
  }

  // Fetch vehicle details by rego
  Future<Map<String, dynamic>> _fetchVehicleByRego(String rego) async {
    final url = BackendConfig.getUri('v1/vehicle/$rego');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {};
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(context, 'Error fetching vehicle: $e');
      return {};
    }
  }

  // Fetch all booking details (multiple regos) by phone number
  Future<void> _fetchBookingsByPhone(String phone) async {
    final url = BackendConfig.getUri('v1/bookings-by-phone/$phone');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final bookings = json.decode(response.body) as List;

        // Map to futures
        final results = await Future.wait(bookings.map((booking) async {
          final vehicle = await _fetchVehicleByRego(booking['rego']);
          return {
            'bookingRef': booking['bookingReferenceNumber'],
            'rego': booking['rego'],
            'make': vehicle['make'] ?? '',
            'model': vehicle['model'] ?? '',
          };
        }));

        setState(() {
          _searchResults = results;
        });
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Failed to fetch bookings.');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error fetching bookings: $e');
    }
  }

  // Fetch existing service items for a bookingRef
  Future<void> _fetchServiceItems(String bookingRef) async {
    final url = BackendConfig.getUri('v1/service-items/$bookingRef');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final items = json.decode(response.body) as List;
        setState(() {
          _serviceItems = items
              .map((item) => {
                    'serviceName': item['serviceName'],
                    'servicePrice': item['servicePrice'].toString(),
                    'serviceDurationMinutes':
                        item['serviceDurationMinutes'].toString(),
                  })
              .toList();
        });
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error fetching service items: $e');
    }
  }

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

  // Save service item
  Future<void> _saveServiceItem() async {
    if (_formKey.currentState!.validate() && _validateDuration()) {
      if (_selectedBookingRef == null) {
        CustomSnackBar.showMessageSnackBar(context, 'Please select a vehicle.');
        return;
      }
      _formKey.currentState!.save();

      final serviceName = _serviceNameController.text.trim();
      final servicePrice =
          double.tryParse(_servicePriceController.text.trim()) ?? 0.0;
      final serviceDurationMinutes =
          (_selectedDuration.hour * 60) + _selectedDuration.minute;

      final serviceItem = {
        'bookingRef': _selectedBookingRef,
        'serviceName': serviceName,
        'servicePrice': servicePrice,
        'serviceDurationMinutes': serviceDurationMinutes,
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'active': true,
      };

      final url = BackendConfig.getUri('v1/service-item');
      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(serviceItem),
        );
        if (response.statusCode == 200) {
          setState(() {
            _serviceItems.add({
              'serviceName': serviceName,
              'servicePrice': servicePrice.toString(),
              'serviceDurationMinutes': serviceDurationMinutes.toString(),
            });
          });
          _formKey.currentState?.reset();
          _serviceNameController.clear();
          _servicePriceController.clear();
          setState(() {
            _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
            _isDurationValid = true;
          });
          CustomSnackBar.showSuccess(
              context, 'Service item added successfully!');
        } else {
          CustomSnackBar.showMessageSnackBar(
              context, 'Failed to save service item: ${response.statusCode}');
        }
      } catch (e) {
        CustomSnackBar.showMessageSnackBar(
            context, 'Error saving service item: $e');
      }
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
    _searchController.clear();
    setState(() {
      _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
      _isDurationValid = true;
      _searchResults.clear();
      _serviceItems.clear();
      _selectedBookingRef = widget.bookingRef;
      if (_selectedBookingRef != null) {
        _fetchBookingByRef(_selectedBookingRef!);
        _fetchServiceItems(_selectedBookingRef!);
      }
    });
    Navigator.of(context).pop();
  }

  // Search vehicle details by rego or phone
  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Please enter a search query.');
      return;
    }
    setState(() {
      _searchResults.clear();
    });
    if (_isSearchingByRego) {
      final url = BackendConfig.getUri('v1/booking/check/$query');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['exists'] == true) {
            final bookingUrl =
                BackendConfig.getUri('v1/booking-by-rego/$query');
            final bookingResponse = await http.get(bookingUrl);
            if (bookingResponse.statusCode == 200) {
              final booking = json.decode(bookingResponse.body);
              final vehicle = await _fetchVehicleByRego(query);
              setState(() {
                _makeController.text = vehicle['make'] ?? '';
                _modelController.text = vehicle['model'] ?? '';
                _selectedBookingRef = booking['bookingReferenceNumber'];
                _searchResults.clear();
              });
              _fetchServiceItems(_selectedBookingRef!);
            } else if (bookingResponse.statusCode == 404) {
              CustomSnackBar.showMessageSnackBar(
                  context, 'No booking found for rego: $query');
            } else {
              CustomSnackBar.showMessageSnackBar(context,
                  'Failed to fetch booking: ${bookingResponse.statusCode}');
            }
          } else {
            CustomSnackBar.showMessageSnackBar(
                context, 'Vehicle not registered: $query');
          }
        } else {
          CustomSnackBar.showMessageSnackBar(
              context, 'Failed to check rego: ${response.statusCode}');
        }
      } catch (e) {
        CustomSnackBar.showMessageSnackBar(context, 'Error searching rego: $e');
      }
    } else {
      await _fetchBookingsByPhone(query);
    }
  }

  // Select a booking from search results (for phone search)
  void _selectSearchResult(Map<String, dynamic> booking) {
    setState(() {
      _makeController.text = booking['make'] ?? '';
      _modelController.text = booking['model'] ?? '';
      _selectedBookingRef = booking['bookingRef'];
      _searchResults.clear();
    });
    _fetchServiceItems(_selectedBookingRef!);
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
            child: Column(
              children: [
                // ---------- SEARCH BAR ----------
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: _isSearchingByRego
                              ? 'Search by Vehicle Rego'
                              : 'Search by Customer Phone',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _performSearch,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<bool>(
                      value: _isSearchingByRego,
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Rego')),
                        DropdownMenuItem(value: false, child: Text('Phone')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _isSearchingByRego = value ?? true;
                          _searchResults.clear();
                          _searchController.clear();
                          _makeController.clear();
                          _modelController.clear();
                          _selectedBookingRef = null;
                          _serviceItems.clear();
                        });
                      },
                    ),
                  ],
                ),

                // ---------- SEARCH RESULTS ----------
                if (_searchResults.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final booking = _searchResults[index];
                      return ListTile(
                        title: Text('Rego: ${booking['rego']}'),
                        subtitle: Text(
                            'Make: ${booking['make']} | Model: ${booking['model']}'),
                        onTap: () => _selectSearchResult(booking),
                      );
                    },
                  ),

                // ---------- SERVICE ITEMS ----------
                if (_serviceItems.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: _serviceItems.length,
                    itemBuilder: (context, index) {
                      final item = _serviceItems[index];
                      return ListTile(
                        title: Text(item['serviceName']),
                        subtitle: Text(
                            'Price: \$${item['servicePrice']} | Duration: ${item['serviceDurationMinutes']} min'),
                      );
                    },
                  ),

                // ---------- SERVICE ITEM FORM ----------
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            maxLength: 15,
                            controller: _makeController,
                            decoration:
                                const InputDecoration(labelText: 'Make'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid make';
                              }
                              return null;
                            },
                            enabled: false, // Read-only after prefill
                          ),
                          TextFormField(
                            maxLength: 15,
                            controller: _modelController,
                            decoration:
                                const InputDecoration(labelText: 'Model'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid model';
                              }
                              return null;
                            },
                            enabled: false, // Read-only after prefill
                          ),
                          TextFormField(
                            controller: _serviceNameController,
                            decoration:
                                const InputDecoration(labelText: 'Service'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a valid Service';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _servicePriceController,
                            decoration:
                                const InputDecoration(labelText: 'Price (\$)'),
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
                          const SizedBox(height: 16),
                          GestureDetector(
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
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
