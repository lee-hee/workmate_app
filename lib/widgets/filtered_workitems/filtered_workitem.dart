import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workmate_app/model/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:workmate_app/model/work_item.dart';
import 'package:workmate_app/widgets/filtered_workitems/filtered_workitem_tile.dart';
import 'package:workmate_app/widgets/filtered_workitems/workitem_filter.dart';

// Config
import '../../config/backend_config.dart';

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
    final url = BackendConfig.getUri('v1/workitem-summary/${selectedUser.id}');
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
                          return WorkItemTile(
                              workItem: workItemsLoaded[position]);
                        },
                      )
          ],
        ),
      ),
    );
  }
}
