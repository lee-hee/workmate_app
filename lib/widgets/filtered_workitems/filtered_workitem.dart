import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
import '../../model/work_item.dart';
import '../../model/user.dart';

// Widgets
import '../filtered_workitems/filtered_workitem_tile.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/filtered_workitem_util.dart';

class FilteredWorkItemScreen extends StatefulWidget {
  const FilteredWorkItemScreen({super.key});

  @override
  State<FilteredWorkItemScreen> createState() {
    return _FilteredWorkItemScreenState();
  }
}

class _FilteredWorkItemScreenState extends State<FilteredWorkItemScreen> {
  DateFormat serverDateFormater = DateFormat('yyyy-MM-ddTHH:mm:ss');
  List<WorkItem> workItemsLoaded = [];
  bool _isLoading = false;
  late User _selectedUser = const User(id: -1, name: '', role: '');
  late Future<List<User>> _loadUsersFuture;

  @override
  void initState() {
    super.initState();
    _loadUsersFuture = loadUserData();
  }

  Future<List<User>> loadUserData() async {
    try {
      final url = BackendConfig.getUri('config/users');
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch users. Please try again later.');
      }
      final List userList = json.decode(response.body);
      List<User> users = [];
      for (final entry in userList) {
        users.add(
            User(id: entry['id'], name: entry['name'], role: entry['role']));
      }
      _selectedUser = users.isNotEmpty ? users.first : _selectedUser;
      return users;
    } catch (e) {
      print('Error loading users: $e');
      return [];
    }
  }

  Future<List<WorkItem>> fetchWorkItemsFilteredToUser(User selectedUser) async {
    try {
      final url =
          BackendConfig.getUri('v1/workitem-summary/${selectedUser.id}');
      print('xxxxxxx$url');
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch workitems. Please try again later.');
      }
      final List workItems = json.decode(response.body);
      List<WorkItem> workItemList = [];
      for (final entry in workItems) {
        workItemList.add(WorkItem(
          id: entry['id'],
          assignedUserName: entry['userDto']['name'],
          workItemStatus: entry['workItemStatus'],
          startedDateTime: entry['startedTime'] ?? 'Not started',
          serviceName: entry['serviceItemDto']['serviceName'],
          duration: entry['serviceItemDto']['serviceDurationMinutes'],
          rego: entry['serviceVehicleDto']['rego'],
          cost: entry['serviceItemDto']['servicePrice'],
        ));
      }
      return workItemList;
    } catch (e) {
      print('Error fetching workitems: $e');
      return [];
    }
  }

  // From workitem_filter.dart
  void _searchWorkItemsBasedOnUser() {
    setState(() {
      _isLoading = true;
    });
    fetchWorkItemsFilteredToUser(_selectedUser).then((workItemsFetched) {
      setState(() {
        workItemsLoaded = workItemsFetched;
        _isLoading = false;
      });
    }).catchError((e) {
      setState(() {
        _isLoading = false;
        workItemsLoaded = [];
      });
      print('Error in search: $e');
    });
  }

  Widget buildUserSelection(List<User> users) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Select a User',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<User>(
          isExpanded: true,
          value: users.isNotEmpty ? _selectedUser : null,
          items: [
            for (final user in users)
              DropdownMenuItem(
                value: user,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0),
                  child:
                      Text(user.name, style: const TextStyle(fontSize: 18.0)),
                ),
              )
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedUser = value;
              });
            }
          },
          hint: const Text('Select a User', style: TextStyle(fontSize: 16.0)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View work items for user'),
      ),
      body: Align(
        alignment: FilteredWorkItemUtils.getAlignment(context), //web
        child: SizedBox(
          width: FilteredWorkItemUtils.getMaxWidth(context), // web
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select a User to Filter Work Items',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  FutureBuilder<List<User>>(
                    future: _loadUsersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
                        return buildUserSelection(snapshot.data!);
                      } else {
                        return const Text('No users available');
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: _searchWorkItemsBasedOnUser,
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : workItemsLoaded.isEmpty
                          ? const Center(child: Text('No data available'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: workItemsLoaded.length,
                              itemBuilder:
                                  (BuildContext context, int position) {
                                return WorkItemTile(
                                    workItem: workItemsLoaded[position]);
                              },
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
