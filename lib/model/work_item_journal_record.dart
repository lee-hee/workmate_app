class WorkItemJournalRecord {
  const WorkItemJournalRecord(
      {required this.id,
      required this.workItemId,
      required this.note,
      required this.newCost,
      required this.newCompletionDateTime,
      required this.imageUrl,
      // required this.imageUrls,
      required this.journalType});
  final int id;
  final int workItemId;
  final String note;
  final double newCost;
  final DateTime newCompletionDateTime;
  final String imageUrl;
  // final List<String> imageUrls; // for multiple images
  final String journalType;
}
