import 'package:flutter/material.dart';

// Models
import '../../model/work_item.dart';

// Widgets
import '../../widgets/journal/workitem_journal.dart';

class WorkItemTile extends StatefulWidget {
  const WorkItemTile({super.key, required this.workItem});

  final WorkItem workItem;

  @override
  State<WorkItemTile> createState() {
    return _WorkItemTile();
  }
}

class _WorkItemTile extends State<WorkItemTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) =>
                WorkItemJournalScreen(selectedWorkItem: widget.workItem),
          ),
        );
      },
      child: ListTile(title: workItemListTile(widget.workItem)),
    );
  }

  Widget workItemListTile(WorkItem workItemByIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
            style: const TextStyle(fontWeight: FontWeight.w700),
            '${workItemByIndex.serviceName} ${workItemByIndex.getWorkItemStatusString()}'),
        Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: workItemByIndex.getIconColorBasedOnStatus(),
              child: workItemByIndex.getIconBasedOnStatus(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Assigned to : ${workItemByIndex.assignedUserName}'),
                    Text(
                        'Duration : ${durationToString(workItemByIndex.duration)}'),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text('Rego : ${workItemByIndex.rego}'),
                Text('Cost:\$${workItemByIndex.cost}')
              ],
            ),
          ],
        ),
        const Divider(color: Colors.black)
      ],
    );
  }

  String durationToString(int minutes) {
    var d = Duration(minutes: minutes);
    List<String> parts = d.toString().split(':');
    return '${parts[0].padLeft(2, '0')}h:${parts[1].padLeft(2, '0')}m';
  }
}
