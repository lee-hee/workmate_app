import 'dart:ffi';

class WorkItemJournalRecord {
  const WorkItemJournalRecord(
      {required this.id,
      required this.workItemId,
      required this.note,
      required this.newCost,
      required this.newCompletionDateTime,
      required this.imageUrl,
      required this.journalType});
  final Long id;
  final Long workItemId;
  final String note;
  final Long newCost;
  final DateTime newCompletionDateTime;
  final String imageUrl;
  final String journalType;
}
