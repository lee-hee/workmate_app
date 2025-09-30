import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Models
import '../../model/work_item_journal_record.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

// Config
import '../../config/backend_config.dart';

class WorkItemJournalListTile extends StatelessWidget {
  final WorkItemJournalRecord journalRecord;

  const WorkItemJournalListTile({super.key, required this.journalRecord});

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
    } catch (e) {
      return dateTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                journalRecord.journalType,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note
                Text(
                  journalRecord.note,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Completion Date
                if (journalRecord.newCompletionDateTime != null)
                  RichText(
                    text: TextSpan(
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black87),
                      children: [
                        const TextSpan(
                          text: 'Completion Date: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                            text: _formatDateTime(
                                journalRecord.newCompletionDateTime)),
                      ],
                    ),
                  ),

                // Cost
                if (journalRecord.newCost != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black87),
                        children: [
                          const TextSpan(
                            text: 'Cost: ',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text:
                                '\$${journalRecord.newCost!.toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ),

                // Image
                if (journalRecord.imageUrl != null &&
                    journalRecord.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        BackendConfig.getUri(
                                'v1/journal-image/${journalRecord.id}')
                            .toString(),
                        height: ResponsiveJournalUtils.getImageHeight(context),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_outlined,
                                    size: 40, color: Colors.grey.shade400),
                                const SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
