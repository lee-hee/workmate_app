import 'package:flutter/material.dart';
import 'package:workmate_app/model/journal_type.dart';
import 'package:workmate_app/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:workmate_app/model/work_item.dart';

// Config
import '../../config/backend_config.dart';

class AddJournalRecord extends StatefulWidget {
  const AddJournalRecord({super.key, required this.workItem});

  final WorkItem workItem;

  @override
  State<AddJournalRecord> createState() {
    return _AddJournalRecordScreen();
  }
}

class _AddJournalRecordScreen extends State<AddJournalRecord> {
  List<JournalType> journalTypes = [];

  @override
  void initState() {
    super.initState();
    getJournalTypes().then((onValue) {
      setState(() {
        journalTypes = onValue;
      });
    });
  }

  Future<List<JournalType>> getJournalTypes() async {
    final url = BackendConfig.getUri('config/journalTypes');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch journalTypes. Please try again later.');
    }
    final List journalTypesData = json.decode(response.body);

    List<JournalType> journalTypes = [];
    for (final entry in journalTypesData) {
      journalTypes.add(JournalType(id: entry['id'], title: entry['value']));
    }
    return journalTypes;
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
              // FutureBuilder<List<JournalType>>(
              //   //future: getJournalTypes,
              //   builder: (context, snapshot) {
              //     if (snapshot.connectionState == ConnectionState.waiting) {
              //       // until data is fetched, show loader
              //       return const CircularProgressIndicator();
              //     } else if (snapshot.hasData) {
              //       // once data is fetched, display it on screen (call buildPosts())
              //       final users = snapshot.data!;
              //       List<JournalType> emptyUsers = [];
              //       return const Text("User data needs to be processed.");
              //       //return buildUserSelection(users);
              //     } else {
              //       // if no data, show simple Text
              //       return const Text("No data available");
              //     }
              //   },
              // ),
              const Text("No data available")
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
                  onPressed: () {}, //,_searchWorkItemsBasedOnUser,
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
          //value: _selectedUser,
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
            //_selectedUser = value;
          },
        ),
      ),
    );
  }
}
