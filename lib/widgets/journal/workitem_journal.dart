import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Models
import '../../model/work_item.dart';
import '../../model/work_item_journal_record.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

// Widgets
import '../filtered_workitems/work_item_journal_tile.dart';
import '../filtered_workitems/workitem_journal_entry.dart';

class WorkItemJournalScreen extends StatefulWidget {
  final WorkItem selectedWorkItem;

  const WorkItemJournalScreen({super.key, required this.selectedWorkItem});

  @override
  State<WorkItemJournalScreen> createState() {
    return _WorkItemJournalScreen();
  }
}

class _WorkItemJournalScreen extends State<WorkItemJournalScreen> {
  List<WorkItemJournalRecord> loadedJournalRecords = [];

  bool _isLoading = true;

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
    try {
      final url = BackendConfig.getUri('v1/workitem/journal/$workItemId');
      final response = await http.get(url);
      print('GET $url: ${response.statusCode} - ${response.body}');
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch workitems. Please try again later.');
      }
      final List journalRecords = json.decode(response.body);
      final journalRecordList = journalRecords
          .map((entry) => WorkItemJournalRecord(
                id: entry['journalRecordId'],
                workItemId: workItemId,
                newCompletionDateTime: entry['newWorkItemCompletionDate'],
                newCost: entry['newWorkItemCost']?.toDouble(),
                note: entry['note'],
                imageUrl: entry['imageUrl'],
                journalType: entry['workItemJournalType'],
              ))
          .toList();
      print('Parsed ${journalRecordList.length} journal records');
      return journalRecordList;
    } catch (e) {
      print('Error fetching journal records: $e');
      setState(() {
        _isLoading = false;
      });
      return [];
    }
  }

  // Navigation to add journal entry record
  void _navigateToJournalForm() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (ctx) => JournalFormPage(
          workItemId: widget.selectedWorkItem.id,
          workItem: widget.selectedWorkItem,
        ),
      ),
    )
        .then((value) {
      if (value == true) {
        // refresh list after new record added
        fetchJournalRecordsForWorkItem(widget.selectedWorkItem.id)
            .then((journalRecords) {
          setState(() {
            loadedJournalRecords = journalRecords;
          });
        });
      }
    });
  }

  // Delete journal record by ID
  Future<void> _deleteJournalRecord(int journalRecordId) async {
    final url = BackendConfig.getUri('v1/workitem/journal/$journalRecordId');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        loadedJournalRecords.removeWhere((r) => r.id == journalRecordId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal record deleted')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Delete failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Item Journal Records'),
      ),
      body: Align(
        alignment: ResponsiveJournalUtils.getAlignment(context),
        child: SizedBox(
          width: ResponsiveJournalUtils.getMaxWidth(context),
          child: Padding(
            padding: ResponsiveJournalUtils.getPagePadding(context),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : loadedJournalRecords.isEmpty
                          ? Center(
                              child: Text(
                                  'No journal records found: ${widget.selectedWorkItem.id}'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: loadedJournalRecords.length,
                              itemBuilder:
                                  (BuildContext context, int position) {
                                final record = loadedJournalRecords[position];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    title: WorkItemJournalListTile(
                                        journalRecord: record),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _deleteJournalRecord(record.id),
                                      tooltip: 'Delete Record',
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToJournalForm,
        tooltip: 'Add Journal Entry',
        child: const Icon(Icons.add),
      ),
    );
  }
}
