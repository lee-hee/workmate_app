// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// // Config
// import '../../config/backend_config.dart';

// // Utils
// import '../../utils/common/custom_snackbar.dart';
// import '../../utils/responsive_utils/service_item/service_item_util.dart';

// class ServiceItemScreen extends StatefulWidget {
//   final String customerPhone;
//   final String rego;

//   const ServiceItemScreen({
//     super.key,
//     required this.customerPhone,
//     required this.rego,
//   });

//   @override
//   State<ServiceItemScreen> createState() => _ServiceItemScreenState();
// }

// class _ServiceItemScreenState extends State<ServiceItemScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _searchController = TextEditingController();
//   final _makeController = TextEditingController();
//   final _modelController = TextEditingController();
//   final _regoController = TextEditingController();

//   bool _isSearchingByRego = true; // true: rego, false: phone
//   List<Map<String, dynamic>> _searchResults = [];
//   List<Map<String, dynamic>> _serviceItems = [];
//   List<Map<String, dynamic>> _serviceOffers = [];
//   Map<String, dynamic>? _selectedServiceOffer;
//   String? _selectedBookingRef;

//   @override
//   void initState() {
//     super.initState();
//     _regoController.text = widget.rego;
//     _fetchVehicleByRego(widget.rego).then((vehicle) {
//       setState(() {
//         _makeController.text = vehicle['make'] ?? '';
//         _modelController.text = vehicle['model'] ?? '';
//       });
//       _loadServiceOffers(vehicle['make'] ?? '', vehicle['model'] ?? '');
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _makeController.dispose();
//     _modelController.dispose();
//     _regoController.dispose();
//     super.dispose();
//   }

//   // Fetch vehicle details by rego
//   Future<Map<String, dynamic>> _fetchVehicleByRego(String rego) async {
//     final url = BackendConfig.getUri('v1/vehicle/$rego');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         return json.decode(response.body);
//       }
//       CustomSnackBar.showMessageSnackBar(context, 'Vehicle not found: $rego');
//       return {};
//     } catch (e) {
//       CustomSnackBar.showMessageSnackBar(context, 'Error fetching vehicle: $e');
//       return {};
//     }
//   }

//   // Fetch all bookings by phone number
//   Future<void> _fetchBookingsByPhone(String phone) async {
//     final url = BackendConfig.getUri('v1/bookings-by-phone/$phone');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final bookings = json.decode(response.body) as List;
//         final results = await Future.wait(bookings.map((booking) async {
//           final vehicle = await _fetchVehicleByRego(booking['rego']);
//           return {
//             'bookingRef': booking['bookingReferenceNumber'],
//             'rego': booking['rego'],
//             'make': vehicle['make'] ?? '',
//             'model': vehicle['model'] ?? '',
//           };
//         }));
//         setState(() {
//           _searchResults = results;
//         });
//       } else {
//         CustomSnackBar.showMessageSnackBar(
//             context, 'No bookings found for phone: $phone');
//       }
//     } catch (e) {
//       CustomSnackBar.showMessageSnackBar(
//           context, 'Error fetching bookings: $e');
//     }
//   }

//   // Fetch service offers by make and model
//   Future<void> _loadServiceOffers(String make, String model) async {
//     final url = BackendConfig.getUri('config/service-offers/$make/$model');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final serviceOffersData = json.decode(response.body) as List;
//         setState(() {
//           _serviceOffers = serviceOffersData
//               .map((item) => {
//                     'id': item['id'],
//                     'serviceName': item['serviceName'],
//                     'servicePrice': item['servicePrice'].toString(),
//                     'serviceDurationMinutes':
//                         item['serviceDurationMinutes'].toString(),
//                     'make': item['make'] ?? '',
//                     'model': item['model'] ?? '',
//                     'shortName': item['shortName'] ?? '',
//                     'description': item['description'] ?? '',
//                   })
//               .toList();
//           if (_serviceOffers.isNotEmpty) {
//             _selectedServiceOffer = _serviceOffers[0];
//           }
//         });
//       } else {
//         CustomSnackBar.showMessageSnackBar(
//             context, 'Failed to load service offers');
//       }
//     } catch (e) {
//       CustomSnackBar.showMessageSnackBar(
//           context, 'Error loading service offers: $e');
//     }
//   }

//   // Create a booking
//   Future<String?> _createBooking() async {
//     final url = BackendConfig.getUri('v1/booking');
//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'customerPhone': widget.customerPhone,
//           'rego': widget.rego,
//         }),
//       );
//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         return decoded['bookingReferenceNumber'];
//       }
//       CustomSnackBar.showMessageSnackBar(context, 'Failed to create booking');
//       return null;
//     } catch (e) {
//       CustomSnackBar.showMessageSnackBar(context, 'Error creating booking: $e');
//       return null;
//     }
//   }

//   // Save service item
//   Future<void> _saveServiceItem() async {
//     if (_formKey.currentState!.validate() && _selectedServiceOffer != null) {
//       if (_selectedBookingRef == null) {
//         _selectedBookingRef = await _createBooking();
//         if (_selectedBookingRef == null) return;
//       }

//       final serviceItem = {
//         'serviceName': _selectedServiceOffer!['serviceName'],
//         'servicePrice': double.parse(_selectedServiceOffer!['servicePrice']),
//         'serviceDurationMinutes':
//             int.parse(_selectedServiceOffer!['serviceDurationMinutes']),
//         'make': _makeController.text.trim(),
//         'model': _modelController.text.trim(),
//         'shortName': _selectedServiceOffer!['shortName'] ?? '',
//         'description': _selectedServiceOffer!['description'] ?? '',
//         'active': true,
//       };

//       final url = BackendConfig.getUri('v1/service-item');
//       try {
//         final response = await http.post(
//           url,
//           headers: {'Content-Type': 'application/json'},
//           body: json.encode(serviceItem),
//         );
//         if (response.statusCode == 200) {
//           setState(() {
//             _serviceItems.add({
//               'serviceName': _selectedServiceOffer!['serviceName'],
//               'servicePrice': _selectedServiceOffer!['servicePrice'],
//               'serviceDurationMinutes':
//                   _selectedServiceOffer!['serviceDurationMinutes'],
//             });
//             _selectedServiceOffer =
//                 _serviceOffers.isNotEmpty ? _serviceOffers[0] : null;
//           });
//           CustomSnackBar.showSuccess(context,
//               'Service item added successfully! Ref: $_selectedBookingRef');
//         } else {
//           CustomSnackBar.showMessageSnackBar(
//               context, 'Failed to save service item');
//         }
//       } catch (e) {
//         CustomSnackBar.showMessageSnackBar(
//             context, 'Error saving service item: $e');
//       }
//     } else {
//       CustomSnackBar.showMessageSnackBar(
//           context, 'Please select a valid service item');
//     }
//   }

//   // Search service offers
//   void _searchServiceOffers(String query) {
//     if (query.isEmpty) {
//       setState(() {
//         _selectedServiceOffer =
//             _serviceOffers.isNotEmpty ? _serviceOffers[0] : null;
//       });
//       return;
//     }
//     setState(() {
//       _selectedServiceOffer = _serviceOffers.firstWhere(
//         (offer) =>
//             offer['serviceName'].toLowerCase().contains(query.toLowerCase()),
//         orElse: () => _serviceOffers.isNotEmpty ? _serviceOffers[0] : {},
//       );
//     });
//   }

//   // Select a booking from search results
//   void _selectSearchResult(Map<String, dynamic> booking) {
//     setState(() {
//       _regoController.text = booking['rego'];
//       _makeController.text = booking['make'] ?? '';
//       _modelController.text = booking['model'] ?? '';
//       _selectedBookingRef = booking['bookingRef'];
//       _searchResults.clear();
//     });
//     _loadServiceOffers(booking['make'] ?? '', booking['model'] ?? '');
//     _fetchServiceItems(booking['bookingRef']);
//   }

//   // Fetch existing service items for a bookingRef
//   Future<void> _fetchServiceItems(String bookingRef) async {
//     final url = BackendConfig.getUri('v1/service-items/$bookingRef');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final items = json.decode(response.body) as List;
//         setState(() {
//           _serviceItems = items
//               .map((item) => {
//                     'serviceName': item['serviceName'],
//                     'servicePrice': item['servicePrice'].toString(),
//                     'serviceDurationMinutes':
//                         item['serviceDurationMinutes'].toString(),
//                   })
//               .toList();
//         });
//       }
//     } catch (e) {
//       CustomSnackBar.showMessageSnackBar(
//           context, 'Error fetching service items: $e');
//     }
//   }

//   // Perform search by rego or phone
//   void _performSearch() async {
//     final query = _searchController.text.trim();
//     if (query.isEmpty) {
//       CustomSnackBar.showMessageSnackBar(
//           context, 'Please enter a search query');
//       return;
//     }
//     setState(() {
//       _searchResults.clear();
//     });
//     if (_isSearchingByRego) {
//       final url = BackendConfig.getUri('v1/vehicle/$query');
//       try {
//         final response = await http.get(url);
//         if (response.statusCode == 200) {
//           final vehicle = json.decode(response.body);
//           final bookingUrl = BackendConfig.getUri('v1/booking-by-rego/$query');
//           final bookingResponse = await http.get(bookingUrl);
//           if (bookingResponse.statusCode == 200) {
//             final booking = json.decode(bookingResponse.body);
//             setState(() {
//               _regoController.text = query;
//               _makeController.text = vehicle['make'] ?? '';
//               _modelController.text = vehicle['model'] ?? '';
//               _selectedBookingRef = booking['bookingReferenceNumber'];
//               _searchResults.clear();
//             });
//             _loadServiceOffers(vehicle['make'] ?? '', vehicle['model'] ?? '');
//             _fetchServiceItems(_selectedBookingRef!);
//           } else {
//             setState(() {
//               _regoController.text = query;
//               _makeController.text = vehicle['make'] ?? '';
//               _modelController.text = vehicle['model'] ?? '';
//               _selectedBookingRef = null;
//               _serviceItems.clear();
//             });
//             _loadServiceOffers(vehicle['make'] ?? '', vehicle['model'] ?? '');
//           }
//         } else {
//           CustomSnackBar.showMessageSnackBar(
//               context, 'Vehicle not found: $query');
//         }
//       } catch (e) {
//         CustomSnackBar.showMessageSnackBar(context, 'Error searching rego: $e');
//       }
//     } else {
//       await _fetchBookingsByPhone(query);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add a Service Item'),
//       ),
//       body: Align(
//         alignment: ResponsiveServiceItemScreenUtils.getAlignment(
//             context), // Center on web
//         child: SizedBox(
//           width: ResponsiveServiceItemScreenUtils.getMaxWidth(context),
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 // ---------- SEARCH BAR ----------
//                 Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         controller: _searchController,
//                         decoration: InputDecoration(
//                           labelText: _isSearchingByRego
//                               ? 'Search by Vehicle Rego'
//                               : 'Search by Customer Phone',
//                           suffixIcon: IconButton(
//                             icon: const Icon(Icons.search),
//                             onPressed: _performSearch,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     DropdownButton<bool>(
//                       value: _isSearchingByRego,
//                       items: const [
//                         DropdownMenuItem(value: true, child: Text('Rego')),
//                         DropdownMenuItem(value: false, child: Text('Phone')),
//                       ],
//                       onChanged: (value) {
//                         setState(() {
//                           _isSearchingByRego = value ?? true;
//                           _searchResults.clear();
//                           _searchController.clear();
//                         });
//                       },
//                     ),
//                   ],
//                 ),

//                 // ---------- SEARCH RESULTS ----------
//                 if (_searchResults.isNotEmpty)
//                   ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: _searchResults.length,
//                     itemBuilder: (context, index) {
//                       final booking = _searchResults[index];
//                       return ListTile(
//                         title: Text('Rego: ${booking['rego']}'),
//                         subtitle: Text(
//                             'Make: ${booking['make']} | Model: ${booking['model']}'),
//                         onTap: () => _selectSearchResult(booking),
//                       );
//                     },
//                   ),

//                 // ---------- SERVICE ITEMS ----------
//                 if (_serviceItems.isNotEmpty)
//                   ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: _serviceItems.length,
//                     itemBuilder: (context, index) {
//                       final item = _serviceItems[index];
//                       return ListTile(
//                         title: Text(item['serviceName']),
//                         subtitle: Text(
//                             'Price: \$${item['servicePrice']} | Duration: ${item['serviceDurationMinutes']} min'),
//                       );
//                     },
//                   ),

//                 // ---------- SERVICE ITEM FORM ----------
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Form(
//                       key: _formKey,
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 16),
//                           TextFormField(
//                             controller: _regoController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Rego'),
//                             enabled: false,
//                           ),
//                           TextFormField(
//                             controller: _makeController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Make'),
//                             enabled: false,
//                           ),
//                           TextFormField(
//                             controller: _modelController,
//                             decoration:
//                                 const InputDecoration(labelText: 'Model'),
//                             enabled: false,
//                           ),
//                           const SizedBox(height: 16),
//                           InputDecorator(
//                             decoration: InputDecoration(
//                               labelText: 'Service',
//                               border: const OutlineInputBorder(),
//                               suffixIcon: IconButton(
//                                 icon: const Icon(Icons.search),
//                                 onPressed: () {
//                                   _searchServiceOffers(
//                                       _searchController.text.trim());
//                                 },
//                               ),
//                             ),
//                             child: DropdownButtonHideUnderline(
//                               child: DropdownButton<Map<String, dynamic>>(
//                                 isExpanded: true,
//                                 value: _selectedServiceOffer,
//                                 hint: _serviceOffers.isEmpty
//                                     ? const Text('No services available')
//                                     : const Text('Select a service'),
//                                 items: _serviceOffers.map((offer) {
//                                   return DropdownMenuItem<Map<String, dynamic>>(
//                                     value: offer,
//                                     child: Text(offer['serviceName']),
//                                   );
//                                 }).toList(),
//                                 onChanged: (value) {
//                                   setState(() {
//                                     _selectedServiceOffer = value;
//                                   });
//                                 },
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               ElevatedButton(
//                                 onPressed: _saveServiceItem,
//                                 style: ElevatedButton.styleFrom(
//                                   foregroundColor: Colors.white,
//                                   backgroundColor:
//                                       const Color.fromARGB(255, 18, 107, 125),
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 16, vertical: 8),
//                                   shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(4)),
//                                 ),
//                                 child: const Text('Save'),
//                               ),
//                               const SizedBox(width: 8),
//                               TextButton(
//                                 onPressed: () {
//                                   Navigator.of(context).pop();
//                                 },
//                                 child: const Text('Cancel'),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_typeahead/flutter_typeahead.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/common/custom_snackbar.dart';
import '../../utils/responsive_utils/service_item/service_item_util.dart';

class ServiceItemScreen extends StatefulWidget {
  final String customerPhone;
  final String rego;

  const ServiceItemScreen({
    super.key,
    required this.customerPhone,
    required this.rego,
  });

  @override
  State<ServiceItemScreen> createState() => _ServiceItemScreenState();
}

class _ServiceItemScreenState extends State<ServiceItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _regoController = TextEditingController();
  final _serviceSearchController = TextEditingController();

  bool _isSearchingByRego = true;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _serviceItems = [];
  List<Map<String, dynamic>> _serviceOffers = [];
  Map<String, dynamic>? _selectedServiceOffer;
  String? _selectedBookingRef;

  @override
  void initState() {
    super.initState();
    _regoController.text = widget.rego;
    _fetchVehicleByRego(widget.rego).then((vehicle) {
      if (vehicle.isNotEmpty) {
        setState(() {
          _makeController.text = vehicle['make'] ?? '';
          _modelController.text = vehicle['model'] ?? '';
        });
        _loadServiceOffers(
            vehicle['make'] ?? 'None', vehicle['model'] ?? 'None');
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'Vehicle not found: ${widget.rego}');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _regoController.dispose();
    _serviceSearchController.dispose();
    super.dispose();
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

  // Fetch bookings by phone number
  Future<void> _fetchBookingsByPhone(String phone) async {
    final url = BackendConfig.getUri('v1/bookings-by-phone/$phone');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final bookings = json.decode(response.body) as List;
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
            context, 'No bookings found for phone: $phone');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error fetching bookings: $e');
    }
  }

  // Fetch service offers by make and model
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
      } else {
        CustomSnackBar.showMessageSnackBar(
            context, 'No service offers available');
      }
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Error loading service offers: $e');
    }
  }

  // Create a booking
  Future<String?> _createBooking() async {
    final url = BackendConfig.getUri('v1/booking');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'customerPhone': widget.customerPhone,
          'rego': widget.rego,
        }),
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['bookingReferenceNumber'];
      }
      CustomSnackBar.showMessageSnackBar(context, 'Failed to create booking');
      return null;
    } catch (e) {
      CustomSnackBar.showMessageSnackBar(context, 'Error creating booking: $e');
      return null;
    }
  }

  // Save service item
  Future<void> _saveServiceItem() async {
    if (_formKey.currentState!.validate() && _selectedServiceOffer != null) {
      if (_selectedBookingRef == null) {
        _selectedBookingRef = await _createBooking();
        if (_selectedBookingRef == null) {
          CustomSnackBar.showMessageSnackBar(
              context, 'Cannot add service: Booking creation failed');
          return;
        }
      }

      final serviceItem = {
        'serviceName': _selectedServiceOffer!['serviceName'],
        'servicePrice': double.parse(_selectedServiceOffer!['servicePrice']),
        'serviceDurationMinutes':
            int.parse(_selectedServiceOffer!['serviceDurationMinutes']),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'shortName': _selectedServiceOffer!['shortName'] ?? '',
        'description': _selectedServiceOffer!['description'] ?? '',
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
              'serviceName': _selectedServiceOffer!['serviceName'],
              'servicePrice': _selectedServiceOffer!['servicePrice'],
              'serviceDurationMinutes':
                  _selectedServiceOffer!['serviceDurationMinutes'],
            });
            _serviceSearchController.clear();
            _selectedServiceOffer =
                _serviceOffers.isNotEmpty ? _serviceOffers[0] : null;
          });
          CustomSnackBar.showSuccess(context,
              'Service item added successfully! Ref: $_selectedBookingRef');
          _fetchServiceItems(_selectedBookingRef!); // Refresh service items
        } else {
          CustomSnackBar.showMessageSnackBar(
              context, 'Failed to save service item');
        }
      } catch (e) {
        CustomSnackBar.showMessageSnackBar(
            context, 'Error saving service item: $e');
      }
    } else {
      CustomSnackBar.showMessageSnackBar(
          context, 'Please select a valid service item');
    }
  }

  // Select a booking from search results
  void _selectSearchResult(Map<String, dynamic> booking) {
    setState(() {
      _regoController.text = booking['rego'];
      _makeController.text = booking['make'] ?? '';
      _modelController.text = booking['model'] ?? '';
      _selectedBookingRef = booking['bookingRef'];
      _searchResults.clear();
      _serviceItems.clear();
    });
    _loadServiceOffers(booking['make'] ?? 'None', booking['model'] ?? 'None');
    _fetchServiceItems(booking['bookingRef']);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a Service Item')),
      body: Align(
        alignment: ResponsiveServiceItemScreenUtils.getAlignment(context),
        child: SizedBox(
          width: ResponsiveServiceItemScreenUtils.getMaxWidth(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
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
                            onPressed: () {
                              if (_searchController.text.trim().isEmpty) {
                                CustomSnackBar.showMessageSnackBar(
                                    context, 'Please enter a search query');
                                return;
                              }
                              _performSearch();
                            },
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
                          _selectedBookingRef = null;
                        });
                      },
                    ),
                  ],
                ),
                // Search results
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
                // Form
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
                          const SizedBox(height: 16),
                          TypeAheadField<Map<String, dynamic>>(
                            textFieldConfiguration: TextFieldConfiguration(
                              controller: _serviceSearchController,
                              decoration: const InputDecoration(
                                labelText: 'Service',
                                hintText:
                                    'No service selected. Search or select from dropdown',
                                border: OutlineInputBorder(),
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
                          const SizedBox(height: 16),
                          // Service items
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
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
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

  // Perform search by rego or phone
  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      CustomSnackBar.showMessageSnackBar(
          context, 'Please enter a search query');
      return;
    }
    setState(() {
      _searchResults.clear();
      _serviceItems.clear();
      _selectedBookingRef = null;
    });
    if (_isSearchingByRego) {
      final url = BackendConfig.getUri('v1/vehicle/$query');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final vehicle = json.decode(response.body);
          final bookingUrl = BackendConfig.getUri('v1/booking-by-rego/$query');
          final bookingResponse = await http.get(bookingUrl);
          if (bookingResponse.statusCode == 200) {
            final booking = json.decode(bookingResponse.body);
            setState(() {
              _regoController.text = query;
              _makeController.text = vehicle['make'] ?? '';
              _modelController.text = vehicle['model'] ?? '';
              _selectedBookingRef = booking['bookingReferenceNumber'];
              _searchResults.clear();
            });
            _loadServiceOffers(
                vehicle['make'] ?? 'None', vehicle['model'] ?? 'None');
            _fetchServiceItems(_selectedBookingRef!);
          } else {
            setState(() {
              _regoController.text = query;
              _makeController.text = vehicle['make'] ?? '';
              _modelController.text = vehicle['model'] ?? '';
              _selectedBookingRef = null;
              _serviceItems.clear();
            });
            _loadServiceOffers(
                vehicle['make'] ?? 'None', vehicle['model'] ?? 'None');
          }
        } else {
          CustomSnackBar.showMessageSnackBar(
              context, 'Vehicle not found: $query');
        }
      } catch (e) {
        CustomSnackBar.showMessageSnackBar(context, 'Error searching rego: $e');
      }
    } else {
      await _fetchBookingsByPhone(query);
    }
  }
}
