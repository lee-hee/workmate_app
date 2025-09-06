import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:workmate_app/model/work_item.dart';
import 'package:workmate_app/model/work_item_journal_record.dart';
import 'package:http/http.dart' as http;

// Config
import '../../config/backend_config.dart';

class WorkItemJournalScreen extends StatefulWidget {
  const WorkItemJournalScreen({super.key, required this.selectedWorkItem});

  final WorkItem selectedWorkItem;

  @override
  State<WorkItemJournalScreen> createState() {
    return _WorkItemJournalScreen();
  }
}

class _WorkItemJournalScreen extends State<WorkItemJournalScreen> {
  List<WorkItemJournalRecord> loadedJournalRecords = [];

  bool _isLoding = false;

  @override
  void initState() {
    super.initState();
    fetchJournalRecordsForWorkItem(widget.selectedWorkItem.id).then((onValue) {
      setState(() {
        loadedJournalRecords = onValue;
      });
    });
  }

  Future<List<WorkItemJournalRecord>> fetchJournalRecordsForWorkItem(
      int workItemId) async {
    final url = BackendConfig.getUri('v1/workitem/journal/$workItemId');
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch workitems. Please try again later.');
    }
    final List journalRecords = json.decode(response.body);
    List<WorkItemJournalRecord> journalRecordList = [];
    for (final entry in journalRecords) {
      journalRecordList.add(WorkItemJournalRecord(
          id: entry['journalRecordId'],
          workItemId: workItemId,
          newCompletionDateTime: entry['newWorkItemCompletionDate'],
          newCost: entry['newWorkItemCost'],
          note: entry['note'],
          imageUrl: entry['imageUrl'],
          journalType: entry['workItemJournalType']));
    }
    return journalRecordList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work item journal records'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _isLoding
                ? const CircularProgressIndicator()
                : loadedJournalRecords.isEmpty
                    ? const Text('No journal records found')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: loadedJournalRecords.length,
                        itemBuilder: (BuildContext context, int position) {
                          return ListTile(
                            title: workItemJournalListTile(
                                loadedJournalRecords[position]),
                            onTap: () {
                              print('load the camera ..... ');
                            },
                          );
                        },
                      )
          ],
        ),
      ),
    );
  }

  Widget workItemJournalListTile(WorkItemJournalRecord workItemJournalRecord) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
              child: Text(
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  '${workItemJournalRecord.journalType} ${workItemJournalRecord.note}',
                  overflow: TextOverflow.ellipsis)),
          const Divider(color: Colors.black)
        ],
      ),
    );
  }
}
