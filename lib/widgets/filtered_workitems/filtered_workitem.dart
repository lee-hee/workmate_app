import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workmate_app/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:workmate_app/model/work_item.dart';
import 'package:workmate_app/widgets/filtered_workitems/workitem_filter.dart';

class FilteredWorkItemScreen extends StatefulWidget {
  const FilteredWorkItemScreen({super.key});

  @override
  State<FilteredWorkItemScreen> createState() {
    return _FilteredWorkItemScreen();
  }
}

class _FilteredWorkItemScreen extends State<FilteredWorkItemScreen> {
  DateFormat serverDateFormater = DateFormat('yyyy-MM-ddTHH:mm:ss');
  List<WorkItem> workItemsLoaded = [];
  bool _isLoding = false;

  @override
  void initState() {
    super.initState();
  }

  Future<List<WorkItem>> fetchWorkItemsFilteredToUser(User selectedUser) async {
    final url = Uri.http('localhost:8080', 'v1/workitems/${selectedUser.id}');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch workitems. Please try again later.');
    }
    final List workItems = json.decode(response.body);
    List<WorkItem> workItemList = [];
    for (final entry in workItems) {
      workItemList.add(WorkItem(
          id: entry['id'],
          assignedUserId: entry['assignedUserId'],
          workItemStatus: entry['workItemStatus'],
          startedDateTime: entry['startedTime'] ?? 'Not started'));
    }
    return workItemList;
  }

  void _searchForWorkItems(User selectedUser) {
    setState(() {
      _isLoding = true;
    });
    fetchWorkItemsFilteredToUser(selectedUser).then((workItemsFetched) => {
          setState(() {
            workItemsLoaded = (workItemsFetched);
            _isLoding = false;
          })
        });
  }

  void getWorkItemsByUser() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) =>
          WorkItemFilterScreen(searchForWorkItems: _searchForWorkItems),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View tasks for user'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
                child: OutlinedButton(
                    onPressed: getWorkItemsByUser,
                    child: const Text(
                      'View work items assigned to user',
                    ))),
            _isLoding
                ? const CircularProgressIndicator()
                : workItemsLoaded.isEmpty
                    ? const Text('No data found for the filter criteria')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: workItemsLoaded.length,
                        itemBuilder: (BuildContext context, int position) {
                          return ListTile(
                            title: workItemListTile(workItemsLoaded[position]),
                            onTap: () {
                              print('onTap');
                            },
                          );
                        },
                      )
          ],
        ),
      ),
    );
  }

  Widget workItemListTile(WorkItem workItemByIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Work item assigned at : ${workItemByIndex.startedDateTime}'),
        Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: workItemByIndex.getIconColorBasedOnStatus(),
              child: workItemByIndex.getIconBasedOnStatus(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Assigned to : ${workItemByIndex.assignedUserId}'),
                    const Text('Duration : 1h 30 mins'),
                  ],
                ),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text("\$45.00"),
                //Text("Not Received"),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget buildWorkItemEntries(List<WorkItem> workItems) {
    return Column(
        children: [for (var workItem in workItems) Text('workItems')]);
  }
}
