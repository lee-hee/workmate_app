import 'package:flutter/material.dart';
import 'package:workmate_app/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Config
import '../../config/backend_config.dart';

class WorkItemFilterScreen extends StatefulWidget {
  const WorkItemFilterScreen({super.key, required this.searchForWorkItems});

  final void Function(User slectedUser) searchForWorkItems;

  @override
  State<WorkItemFilterScreen> createState() {
    return _WorkItemFilterScreen();
  }
}

class _WorkItemFilterScreen extends State<WorkItemFilterScreen> {
  late User _selectedUser = const User(id: -1, name: '', role: '');
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
      throw Exception('Failed to fetch users. Please try again later.');
    }
    final List userList = json.decode(response.body);
    List<User> users = [];
    for (final entry in userList) {
      users
          .add(User(id: entry['id'], name: entry['name'], role: entry['role']));
    }
    _selectedUser = users.first;
    return users;
  }

  void _searchWorkItemsBasedOnUser() {
    widget.searchForWorkItems(_selectedUser);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 16, 16),
      child: Column(
        children: [
          const Text(
            'Select a user',
            style: TextStyle(fontSize: 25.0),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              FutureBuilder<List<User>>(
                future: _loadUsersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // until data is fetched, show loader
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasData) {
                    // once data is fetched, display it on screen (call buildPosts())
                    final users = snapshot.data!;
                    return buildUserSelection(users);
                  } else {
                    // if no data, show simple Text
                    return const Text("No data available");
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _searchWorkItemsBasedOnUser,
                  child: const Text('Search'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildUserSelection(List<User> users) {
    return InputDecorator(
      decoration: const InputDecoration(border: OutlineInputBorder()),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          isExpanded: true,
          borderRadius: BorderRadius.circular(2.5),
          hint: const Text('Select'),
          value: _selectedUser,
          items: [
            for (final user in users)
              DropdownMenuItem(
                value: user,
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    Text(user.name, style: const TextStyle(fontSize: 20.0)),
                  ],
                ),
              )
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            _selectedUser = value;
          },
        ),
      ),
    );
  }
}
