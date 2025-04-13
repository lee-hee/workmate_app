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
    final url =
        Uri.http('localhost:8080', 'v1/workitem-summary/${selectedUser.id}');
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
          cost: entry['serviceItemDto']['servicePrice']));
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
        title: const Text('View work items for user'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
                child: FilledButton.icon(
              onPressed: getWorkItemsByUser,
              icon: const Icon(Icons.search_off_outlined),
              label: const Text('Search for work items'),
              iconAlignment: IconAlignment.start,
            )),
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
              style: const TextStyle(fontWeight: FontWeight.w700),
              '${workItemByIndex.serviceName} ${workItemByIndex.getWorkItemStatusString()}'),
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
                      Text('Assigned to : ${workItemByIndex.assignedUserName}'),
                      Text(
                          'Duration : ${durationToString(workItemByIndex.duration)}'),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('Rego : ${workItemByIndex.rego}'),
                  Text('Cost:\$${workItemByIndex.cost}')
                ],
              ),
            ],
          ),
          const Divider(color: Colors.black)
        ],
      ),
    );
  }

  String durationToString(int minutes) {
    var d = Duration(minutes: minutes);
    List<String> parts = d.toString().split(':');
    return '${parts[0].padLeft(2, '0')}h:${parts[1].padLeft(2, '0')}m';
  }
}
