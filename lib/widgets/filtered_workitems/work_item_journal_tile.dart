import 'package:flutter/material.dart';

// Models
import '../../model/work_item_journal_record.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

// Config
import '../../config/backend_config.dart';

class WorkItemJournalListTile extends StatelessWidget {
  final WorkItemJournalRecord journalRecord;

  const WorkItemJournalListTile({super.key, required this.journalRecord});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${journalRecord.journalType} - ${journalRecord.note}',
          style: const TextStyle(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        if (journalRecord.newCompletionDateTime != null)
          Text('Completion: ${journalRecord.newCompletionDateTime}'),
        if (journalRecord.newCost != null)
          Text('Cost: \$${journalRecord.newCost}'),

        // If there is a single image
        if (journalRecord.imageUrl != null &&
            journalRecord.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Image.network(
              BackendConfig.getUri('v1/journal-image/${journalRecord.imageUrl}')
                  .toString(),
              height: ResponsiveJournalUtils.getImageHeight(context),
              fit: BoxFit.cover,
            ),
          ),
        const Divider(color: Colors.black),
      ],
    );
  }
}
