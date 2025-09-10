import 'package:flutter/material.dart';

// Models
import '../../model/work_item_journal_record.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

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
              journalRecord.imageUrl!,
              height: ResponsiveJournalUtils.getImageHeight(context),
              fit: BoxFit.cover,
            ),
          ),

        // If there is list of images
        // const SizedBox(height: 8.0),

        // Horizontal scrollable image gallery
        // if (journalRecord.imageUrls.isNotEmpty)
        //   SizedBox(
        //     height: 120,
        //     child: ListView.separated(
        //       scrollDirection: Axis.horizontal,
        //       itemCount: journalRecord.imageUrls.length,
        //       separatorBuilder: (context, index) => const SizedBox(width: 8),
        //       itemBuilder: (context, index) {
        //         return ClipRRect(
        //           borderRadius: BorderRadius.circular(8),
        //           child: Image.network(
        //             journalRecord.imageUrls[index],
        //             width: 150,
        //             fit: BoxFit.cover,
        //           ),
        //         );
        //       },
        //     ),
        //   ),
        const Divider(color: Colors.black),
      ],
    );
  }
}
