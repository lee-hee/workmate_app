import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Config
import '../../../config/backend_config.dart';

// Utils
import '../../../utils/responsive_utils/service_item/service_item_util.dart';

class UserRegisterScreen extends StatefulWidget {
  const UserRegisterScreen({super.key});

  @override
  State<UserRegisterScreen> createState() {
    return _UserRegisterScreenState();
  }
}

class _UserRegisterScreenState extends State<UserRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String? _selectedRole; // MANAGER, TECHNICIAN, OFFICE_STAFF
  final List<String> _roles = ["MANAGER", "TECHNICIAN", "OFFICE_STAFF"];

  void _saveUser() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      _formKey.currentState!.save();

      final name = _nameController.text.trim();
      final role = _selectedRole!;

      // Prepare the data to send
      final Map<String, dynamic> data = {
        "name": name,
        "role": role,
      };

      final url = BackendConfig.getUri("config/user");

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode(data),
        );

        if (response.statusCode == 200) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User saved successfully!")),
          );

          // Clear form
          _formKey.currentState?.reset();
          _nameController.clear();
          setState(() {
            _selectedRole = null;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Failed to save user: ${response.statusCode}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } else if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role")),
      );
    }
  }

  void _cancelForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    setState(() {
      _selectedRole = null;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New User"),
      ),
      body: Align(
        alignment: ResponsiveServiceItemScreenUtils.getAlignment(context),
        child: SizedBox(
          width: ResponsiveServiceItemScreenUtils.getMaxWidth(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: TextFormField(
                        controller: _nameController,
                        maxLength: 30,
                        decoration: const InputDecoration(labelText: "Name"),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.trim().length < 2) {
                            return "Please enter a valid name";
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: const InputDecoration(
                          labelText: "Role",
                          border: OutlineInputBorder(),
                        ),
                        items: _roles.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a role";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _saveUser,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                const Color.fromARGB(255, 18, 107, 125),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                          child: const Text("Save"),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _cancelForm,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text("Cancel"),
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
