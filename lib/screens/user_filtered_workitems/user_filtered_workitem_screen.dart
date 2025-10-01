import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
import '../../model/work_item.dart';
import '../../model/user.dart';

// Widgets
import '../../widgets/user_filtered_workitems/filtered_workitem_tile.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/filtered_workitem_util.dart';

class FilteredWorkItemScreen extends StatefulWidget {
  const FilteredWorkItemScreen({super.key});

  @override
  State<FilteredWorkItemScreen> createState() => _FilteredWorkItemScreenState();
}

class _FilteredWorkItemScreenState extends State<FilteredWorkItemScreen> {
  static const double _padding = 16.0;
  static const double _spacing = 12.0;

  List<WorkItem> workItemsLoaded = [];
  bool _isLoading = false;
  User _selectedUser = const User(id: -1, name: '', role: '');
  late Future<List<User>> _loadUsersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsersFuture = loadUserData();
  }

  Future<List<User>> loadUserData() async {
    final url = BackendConfig.getUri('config/users');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users');
    }
    final List userList = json.decode(response.body);
    List<User> users = userList
        .map((e) => User(id: e['id'], name: e['name'], role: e['role']))
        .toList();
    if (users.isNotEmpty) _selectedUser = users.first;
    return users;
  }

  Future<List<WorkItem>> fetchWorkItemsFilteredToUser(User selectedUser) async {
    final url = BackendConfig.getUri('v1/workitem-summary/${selectedUser.id}');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch work items');
    }
    final List workItems = json.decode(response.body);
    return workItems
        .where((e) => e['id'] != null && e['id'] > 0)
        .map((entry) => WorkItem(
              id: entry['id'],
              assignedUserName: entry['userDto']?['name'] ?? 'Unassigned',
              workItemStatus: entry['workItemStatus'] ?? 'PENDING',
              startedDateTime: entry['startedTime'] ?? '',
              serviceName: entry['serviceItemDto']?['serviceName'] ?? '',
              duration: entry['serviceItemDto']?['serviceDurationMinutes'] ?? 0,
              rego: entry['serviceVehicleDto']?['rego'] ?? '',
              cost:
                  (entry['serviceItemDto']?['servicePrice'] ?? 0.0).toDouble(),
              uniqueBookingRefIdentifier:
                  entry['uniqueBookingRefIdentifier'] ?? '',
            ))
        .toList();
  }

  void _searchWorkItemsBasedOnUser() async {
    setState(() => _isLoading = true);
    try {
      final items = await fetchWorkItemsFilteredToUser(_selectedUser);
      setState(() {
        workItemsLoaded = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        workItemsLoaded = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work Items'),
            Text('Filter by User', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
      body: Align(
        alignment: FilteredWorkItemUtils.getAlignment(context),
        child: SizedBox(
          width: FilteredWorkItemUtils.getMaxWidth(context),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(_padding),
                    child: Column(
                      children: [
                        FutureBuilder<List<User>>(
                          future: _loadUsersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('No users available');
                            }
                            return InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Select User',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<User>(
                                  isExpanded: true,
                                  value: _selectedUser,
                                  items: snapshot.data!
                                      .map((user) => DropdownMenuItem(
                                            value: user,
                                            child: Text(user.name),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedUser = value);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: _spacing),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _searchWorkItemsBasedOnUser,
                              icon: const Icon(Icons.search),
                              label: const Text('Search'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: _padding),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : workItemsLoaded.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.work_outline,
                                      size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: _spacing),
                                  Text('No work items found',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: workItemsLoaded.length,
                              itemBuilder: (context, index) => WorkItemTile(
                                  workItem: workItemsLoaded[index]),
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
