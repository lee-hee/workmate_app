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
    _fetchJournalRecords();
  }

  // Fetch journal records for the selected work item
  Future<void> _fetchJournalRecords() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final records =
          await fetchJournalRecordsForWorkItem(widget.selectedWorkItem.id);
      setState(() {
        loadedJournalRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching journal records: $e')),
        );
      }
    }
  }

  // Fetch journal records from backend
  Future<List<WorkItemJournalRecord>> fetchJournalRecordsForWorkItem(
      int workItemId) async {
    final url = BackendConfig.getUri('v1/workitem/journal/$workItemId');
    print('Fetching journal records for workItemId: $workItemId');
    final response = await http.get(url);
    print('GET $url: ${response.statusCode} - ${response.body}');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch journal records. Status code: ${response.statusCode}');
    }
    final List journalRecords = json.decode(response.body);
    final journalRecordList = journalRecords
        .map((entry) => WorkItemJournalRecord(
              id: entry['journalRecordId'] ?? 0,
              workItemId: workItemId,
              note: entry['note'] ?? '',
              newCost: entry['newWorkItemCost']?.toDouble(),
              newCompletionDateTime:
                  entry['newWorkItemCompletionDate'] as String?,
              imageUrl: entry['imageUrl'] as String?,
              journalType: entry['workItemJournalType'] ?? 'COMMENT',
            ))
        .toList();
    print('Parsed ${journalRecordList.length} journal records');
    return journalRecordList;
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
        _fetchJournalRecords();
      }
    });
  }

  // Delete journal record by ID
  Future<void> _deleteJournalRecord(int journalRecordId) async {
    final url = BackendConfig.getUri('v1/workitem/journal/$journalRecordId');
    print('Deleting journal record: $journalRecordId');
    final response = await http.delete(url);
    if (response.statusCode == 200) {
      setState(() {
        loadedJournalRecords.removeWhere((r) => r.id == journalRecordId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal record deleted')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to delete journal record: ${response.body}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Journal Records for ${widget.selectedWorkItem.serviceName}'),
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
                  Text(
                    'Work Item: ${widget.selectedWorkItem.serviceName} (Rego: ${widget.selectedWorkItem.rego})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : loadedJournalRecords.isEmpty
                          ? const Center(
                              child: Text('No journal records found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: loadedJournalRecords.length,
                              itemBuilder: (context, index) {
                                final record = loadedJournalRecords[index];
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
