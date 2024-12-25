import 'package:flutter/material.dart';
import 'package:workmate_app/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AssignedWorkItemScreen extends StatefulWidget {
  const AssignedWorkItemScreen({super.key});

  @override
  State<AssignedWorkItemScreen> createState() {
    return _AssignedWorkItemScreen();
  }
}

class _AssignedWorkItemScreen extends State<AssignedWorkItemScreen> {
  late Future<List<User>> _future;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _future = loadUserData();
  }

  Future<List<User>> loadUserData() async {
    final url = Uri.http('localhost:8080', 'config/users');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch bookings. Please try again later.');
    }
    final List userList = json.decode(response.body);
    List<User> users = [];
    for (final entry in userList) {
      users
          .add(User(id: entry['id'], name: entry['name'], role: entry['role']));
    }
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View tasks for user'),
      ),
      body: Column(
        children: [
          Padding(
              padding: const EdgeInsets.all(15.0),
              child: FutureBuilder<List<User>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.data == null) {
                    return const CircularProgressIndicator();
                  }
                  return Column(
                    children: [
                      DropdownButton<User>(
                        hint: const Text('Select user'),
                        onChanged: (user) =>
                            setState(() => _selectedUser = user),
                        value: _selectedUser,
                        items: [
                          ...snapshot.data!.map(
                            (user) => DropdownMenuItem(
                              value: user,
                              child: Row(
                                children: [
                                  const Icon(Icons.man_2_outlined),
                                  Text(user.name),
                                ],
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  );
                },
              )),
          const Text('This this the work Item component')
        ],
      ),
    );
  }
}
