import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:intl/intl.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/common/custom_snackbar.dart';
import '../../utils/responsive_utils/service_item/service_item_util.dart';

class NewBookingScreen extends StatefulWidget {
  final String customerPhone;
  final String rego;

  const NewBookingScreen({
    super.key,
    required this.customerPhone,
    required this.rego,
  });

  @override
  State<NewBookingScreen> createState() {
    return _NewBookingScreenState();
  }
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _regoController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _serviceSearchController = TextEditingController();

  String _phone = '';
  bool _isSearchingByRego = true;
  bool _hasOpenBooking = false;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _serviceItems = []; // Added services
  List<Map<String, dynamic>> _serviceOffers = []; // Predefined offers
  Map<String, dynamic>? _selectedServiceOffer;
  String? _selectedBookingRef;
  DateTime? _selectedBookingDateTime;

  @override
  void initState() {
    super.initState();
    _regoController.text = widget.rego;
    _phone = widget.customerPhone;
    if (widget.rego.isNotEmpty) {
      _fetchVehicleByRego(widget.rego).then((vehicle) async {
        if (vehicle.isNotEmpty) {
          setState(() {
            _makeController.text = vehicle['make'] ?? '';
            _modelController.text = vehicle['model'] ?? '';
          });
          if (_phone.isEmpty && vehicle['customerId'] != null) {
            _phone = await _fetchCustomerPhone(vehicle['customerId']);
          }
          _loadServiceOffers(
              vehicle['make'] ?? 'None', vehicle['model'] ?? 'None');
          _checkOpenBooking(widget.rego);
        } else if (widget.rego.isNotEmpty) {
          CustomSnackBar.showMessageSnackBar(
              context, 'Vehicle not found: ${widget.rego}');
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _regoController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
  }

  // Fetch customer phone by customerId
  Future<String> _fetchCustomerPhone(int customerId) async {
    final url = BackendConfig.getUri('v1/customer/id/$customerId');
    try {
      final response = await http.get(url);
      print('GET $url: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final customer = json.decode(response.body);
        return customer['phone'] ?? '';
      }
      return '';
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error fetching customer: $e');
      return '';
    }
  }

  // Fetch vehicle details by rego
  Future<Map<String, dynamic>> _fetchVehicleByRego(String rego) async {
    if (rego.isEmpty) {
      return {};
    }
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

  // Fetch all vehicles by phone number
  Future<void> _fetchVehiclesByPhone(String phone) async {
    final url = BackendConfig.getUri('v1/vehicles-by-phone/$phone');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final vehicles = json.decode(response.body) as List;
        setState(() {
          _searchResults = vehicles
              .map((vehicle) => {
                    'rego': vehicle['rego'],
                    'make': vehicle['make'] ?? '',
                    'model': vehicle['model'] ?? '',
                  })
              .toList();
        });
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'No vehicles found for phone number: $phone');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error fetching vehicles: $e');
    }
  }

  // Fetch predefined service items by make and model
  Future<void> _loadServiceOffers(String make, String model) async {
    final url = BackendConfig.getUri('config/service-offers/$make/$model');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final serviceOffersData = json.decode(response.body) as List;
        setState(() {
          _serviceOffers = serviceOffersData
              .map((item) => {
                    'id': item['id'],
                    'serviceName': item['serviceName'],
                    'servicePrice': item['servicePrice'].toString(),
                    'serviceDurationMinutes':
                        item['serviceDurationMinutes'].toString(),
                    'make': item['make'] ?? '',
                    'model': item['model'] ?? '',
                    'shortName': item['shortName'] ?? '',
                    'description': item['description'] ?? '',
                  })
              .toList();
          if (_serviceOffers.isNotEmpty) {
            _selectedServiceOffer = _serviceOffers[0];
          }
        });
        // Fallback to general if empty and not already general
        if (_serviceOffers.isEmpty && make != 'None' && model != 'None') {
          await _loadServiceOffers('None', 'None');
        }
      } else {
        // If specific fails and not general, try general
        if (make != 'None' && model != 'None') {
          await _loadServiceOffers('None', 'None');
        } else {
          CustomSnackBar.showMessageSnackBar(
              context, 'No service offers available');
        }
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error loading service offers: $e');
      // Fallback on error
      if (make != 'None' && model != 'None') {
        await _loadServiceOffers('None', 'None');
      }
    }
  }

  // Check if there is an open booking for the rego
  Future<void> _checkOpenBooking(String rego) async {
    if (rego.isEmpty) {
      setState(() {
        _hasOpenBooking = false;
        _serviceItems = [];
      });
      return;
    }
    final url = BackendConfig.getUri('v1/booking-by-rego/$rego');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final bookings = json.decode(response.body) as List;
        final openBooking = bookings.firstWhere(
            (b) => b['bookingStatus'] == 'BOOKED',
            orElse: () => null);
        if (openBooking != null) {
          setState(() {
            _hasOpenBooking = true;
            _selectedBookingRef = openBooking['bookingReferenceNumber'];
          });
          await _fetchServiceItems(_selectedBookingRef!);
        } else {
          setState(() {
            _hasOpenBooking = false;
            _serviceItems = [];
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _hasOpenBooking = false;
          _serviceItems = [];
        });
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Failed to check bookings: ${response.statusCode}');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error checking bookings: $e');
    }
  }

  // Fetch existing service items for a bookingRef
  Future<void> _fetchServiceItems(String bookingRef) async {
    final url = BackendConfig.getUri('v1/booking/$bookingRef/service-items');
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
      } else {
        setState(() {
          _serviceItems = [];
        });
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error fetching service items: $e');
    }
  }

  // Create booking with selected service item ids and date time
  Future<void> _createBooking() async {
    if (_hasOpenBooking) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Cannot create new booking: Open booking exists.');
      return;
    }
    if (_serviceItems.isEmpty) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Please add at least one service item.');
      return;
    }
    if (_selectedBookingDateTime == null) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Please select a booking date and time.');
      return;
    }
    if (_phone.isEmpty) {
      // check phone exists
      CustomSnackBar.showMessageSnackBar(
          context, 'Customer phone number is missing.');
      return;
    }

    final url = BackendConfig.getUri('v1/booking');
    final List<int> serviceItemIds =
        _serviceItems.map((item) => item['id'] as int).toList();
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerPhone': _phone,
          'rego': _regoController.text,
          'bookingDateTime': DateFormat("yyyy-MM-dd'T'HH:mm:ss")
              .format(_selectedBookingDateTime!),
          'serviceItemIds': serviceItemIds,
        }),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final bookingRef = decoded['bookingReferenceNumber'];
        // CustomSnackBar.showSuccess(
        //     context, 'Booking created successfully! Ref: $bookingRef');
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: Text('Booking created successfully! Ref: $bookingRef'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _cancelForm(); // Move form clearing and navigation here
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // Refresh after create
        await _checkOpenBooking(_regoController.text);
        // Navigate or clear form as needed
        // _cancelForm();
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Failed to create booking: ${response.statusCode}');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(context, 'Error creating booking: $e');
    }
  }

  // Add selected service to list
  void _addServiceItem() {
    if (_hasOpenBooking) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Cannot add services: Open booking exists.');
      return;
    }
    if (_selectedServiceOffer != null) {
      setState(() {
        _serviceItems.add({
          'id': _selectedServiceOffer!['id'],
          'serviceName': _selectedServiceOffer!['serviceName'],
          'servicePrice': _selectedServiceOffer!['servicePrice'],
          'serviceDurationMinutes':
              _selectedServiceOffer!['serviceDurationMinutes'],
        });
        _serviceSearchController.clear();
        _selectedServiceOffer =
            _serviceOffers.isNotEmpty ? _serviceOffers[0] : null;
      });
    } else {
      CustomSnackBar.showMessageSnackBar(
          context, 'Please select a service item');
    }
  }

  // Remove a service item from the list
  void _removeServiceItem(int index) {
    setState(() {
      _serviceItems.removeAt(index);
    });
  }

  void _cancelForm() {
    _formKey.currentState?.reset();
    _makeController.clear();
    _modelController.clear();
    _serviceSearchController.clear();
    _searchController.clear();
    setState(() {
      _selectedBookingDateTime = null;
      _searchResults.clear();
      _serviceItems.clear();
      _hasOpenBooking = false;
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
      final vehicle = await _fetchVehicleByRego(query);
      if (vehicle.isNotEmpty) {
        setState(() {
          _regoController.text = query;
          _makeController.text = vehicle['make'] ?? '';
          _modelController.text = vehicle['model'] ?? '';
          _searchResults.clear();
        });
        if (vehicle['customerId'] != null) {
          _phone = await _fetchCustomerPhone(vehicle['customerId']);
        }
        await _loadServiceOffers(
            vehicle['make'] ?? 'None', vehicle['model'] ?? 'None');
        await _checkOpenBooking(query);
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Vehicle not found: $query');
      }
    } else {
      setState(() {
        _phone = query;
      });
      await _fetchVehiclesByPhone(query);
    }
  }

  // Select a vehicle from search results (for phone search)
  void _selectSearchResult(Map<String, dynamic> vehicle) {
    setState(() {
      _regoController.text = vehicle['rego'] ?? '';
      _makeController.text = vehicle['make'] ?? '';
      _modelController.text = vehicle['model'] ?? '';
      _searchResults.clear();
      _serviceItems.clear();
    });
    _loadServiceOffers(vehicle['make'] ?? 'None', vehicle['model'] ?? 'None');
    _checkOpenBooking(vehicle['rego']);
  }

  Future<void> _pickBookingDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedBookingDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Booking'),
      ),
      body: Align(
        alignment: ResponsiveServiceItemScreenUtils.getAlignment(context),
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
                          suffixIcon: TextButton(
                            // icon: const Icon(Icons.search),
                            onPressed: _performSearch,
                            child: const Text('Search'),
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
                          _serviceItems.clear();
                          _hasOpenBooking = false;
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
                      final vehicle = _searchResults[index];
                      return ListTile(
                        title: Text('Rego: ${vehicle['rego']}'),
                        subtitle: Text(
                            'Make: ${vehicle['make']} | Model: ${vehicle['model']}'),
                        onTap: () => _selectSearchResult(vehicle),
                      );
                    },
                  ),

                // ---------- VEHICLE DETAILS ----------
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _regoController,
                            decoration:
                                const InputDecoration(labelText: 'Rego'),
                            enabled: false,
                          ),
                          TextFormField(
                            controller: _makeController,
                            decoration:
                                const InputDecoration(labelText: 'Make'),
                            enabled: false,
                          ),
                          TextFormField(
                            controller: _modelController,
                            decoration:
                                const InputDecoration(labelText: 'Model'),
                            enabled: false,
                          ),
                          if (_hasOpenBooking)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Open booking exists. Cannot add new services until completed or cancelled.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          if (!_hasOpenBooking) ...[
                            const SizedBox(height: 16),
                            // ---------- SERVICE SELECTION ----------
                            TypeAheadField<Map<String, dynamic>>(
                              textFieldConfiguration: TextFieldConfiguration(
                                controller: _serviceSearchController,
                                decoration: InputDecoration(
                                  labelText: 'Search Service',
                                  border: const OutlineInputBorder(),
                                  // Add button inside the text field
                                  suffixIcon: (_selectedServiceOffer != null ||
                                          _serviceSearchController
                                              .text.isNotEmpty)
                                      ? TextButton(
                                          // icon: const Icon(Icons.add, size: 20),
                                          onPressed: _addServiceItem,
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(
                                                color: Colors.teal,
                                                fontSize: 14),
                                          ), // Disable if no service selected
                                        )
                                      : null,
                                ),
                              ),
                              suggestionsCallback: (pattern) async {
                                if (pattern.isEmpty) return _serviceOffers;
                                return _serviceOffers
                                    .where((offer) => offer['serviceName']
                                        .toLowerCase()
                                        .contains(pattern.toLowerCase()))
                                    .toList();
                              },
                              itemBuilder: (context, suggestion) {
                                return ListTile(
                                  title: Text(suggestion['serviceName']),
                                  subtitle: Text(
                                      'Price: \$${suggestion['servicePrice']} | Duration: ${suggestion['serviceDurationMinutes']} min'),
                                );
                              },
                              onSuggestionSelected: (suggestion) {
                                setState(() {
                                  _selectedServiceOffer = suggestion;
                                  _serviceSearchController.text =
                                      suggestion['serviceName'];
                                });
                              },
                              noItemsFoundBuilder: (context) => const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('No services found'),
                              ),
                            ),
                            // const SizedBox(height: 8),
                            // ElevatedButton(
                            //   onPressed: _addServiceItem,
                            //   child: const Text('Add Service'),
                            // ),
                          ],
                          // ---------- ADDED / EXISTING SERVICE ITEMS ----------
                          if (_serviceItems.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 0, 8),
                              child: Text(
                                'Service Items:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _serviceItems.length,
                              itemBuilder: (context, index) {
                                final item = _serviceItems[index];
                                return ListTile(
                                  title: Text(item['serviceName']),
                                  subtitle: Text(
                                      'Price: \$${item['servicePrice']} | Duration: ${item['serviceDurationMinutes']} min'),
                                  // Service item removal button
                                  trailing: _hasOpenBooking
                                      ? null
                                      : IconButton(
                                          icon:
                                              const Icon(Icons.close, size: 20),
                                          color: Colors.red,
                                          tooltip: 'Remove Service',
                                          onPressed: () =>
                                              _removeServiceItem(index),
                                        ),
                                );
                              },
                            ),
                          ],
                          if (!_hasOpenBooking) ...[
                            const SizedBox(height: 16),
                            // ---------- BOOKING DATE TIME ----------
                            GestureDetector(
                              onTap: _pickBookingDateTime,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Booking Date & Time',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _selectedBookingDateTime == null
                                      ? 'Select date and time'
                                      : DateFormat('yyyy-MM-dd HH:mm')
                                          .format(_selectedBookingDateTime!),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_hasOpenBooking)
                                ElevatedButton(
                                  onPressed: _createBooking,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        const Color.fromARGB(255, 18, 107, 125),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                  ),
                                  child: const Text('Create Booking'),
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
