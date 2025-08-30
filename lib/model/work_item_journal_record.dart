class WorkItemJournalRecord {
  const WorkItemJournalRecord(
      {required this.id,
      required this.workItemId,
      required this.note,
      required this.newCost,
      required this.newCompletionDateTime,
      required this.imageUrl,
      required this.journalType});
  final int id;
  final int workItemId;
  final String note;
  final double newCost;
  final DateTime newCompletionDateTime;
  final String imageUrl;
  final String journalType;
}
