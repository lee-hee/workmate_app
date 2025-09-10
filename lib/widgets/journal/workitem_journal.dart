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

// Sample data for test
import '../../utils/data/sample_journal_record.dart';

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

  final bool _isLoading = false;

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
            imageUrl: entry['imageUrl'], // Single image
            // imageUrls: [], // Placeholder for multiple images
            journalType: entry['workItemJournalType']));
      }
      return journalRecordList;
    } catch (e) {
      print('Error fetching journal records: $e');
      return [];
    }
  }

  // Navigation to add journal entry record
  void _navigateToJournalForm() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const JournalFormPage(),
      ),
    );
  }

  // Delete journal record
  void _deleteJournalRecord(int journalRecordId) {
    // Placeholder for delete functionality => backend implementation
    setState(() {
      loadedJournalRecords
          .removeWhere((record) => record.id == journalRecordId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal record deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Item Journal Records'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add),
        //     onPressed: _navigateToJournalForm,
        //     tooltip: 'Add Journal Entry',
        //   ),
        // ],
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
                      // : loadedJournalRecords.isEmpty
                      //     ? const Center(
                      //         child: Text('No journal records found'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: loadedJournalRecords.length,
                          // itemCount: sampleJournalRecords.length,
                          itemBuilder: (BuildContext context, int position) {
                            final record = loadedJournalRecords[position];
                            // itemBuilder: (BuildContext context, int index) {
                            //   final record = sampleJournalRecords[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
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
