import 'package:flutter/material.dart';
import 'package:workmate_app/model/app_action.dart';

// Widgets
import '../../widgets/filtered_workitems/filtered_workitem.dart';
import '../../widgets/booking_list/booking_calendar.dart';
import '../../widgets/home_view/work_action_grid_item.dart';
import '../../widgets/new_booking/new_booking.dart';
import '../../widgets/service_item/service_item_screen.dart';

// Utils
import '../../utils/responsive_utils/home_view/home_util.dart';

// Testing purpose - journal entry page
import '../filtered_workitems/workitem_journal_entry.dart';

class WorkActionHomeScreen extends StatelessWidget {
  const WorkActionHomeScreen({super.key});

  void _selectAction(BuildContext context, String actionKey) {
    StatefulWidget navigatingWidget;
    if ('new_booking' == actionKey) {
      navigatingWidget = const NewBooking();
    } else if ('list_booking' == actionKey) {
      navigatingWidget = const BookingCalender();
    } else if ('add_service_item' == actionKey) {
      navigatingWidget = const ServiceItemScreen();
    } else {
      navigatingWidget = const FilteredWorkItemScreen();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => navigatingWidget,
      ),
    ); // Navigator.push(context, route)
  }

  // Testing purpose
  void _navigateToJournalPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const JournalFormPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Action'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView(
              padding: ResponsiveHomeUtils.getGridPadding(
                  context), // Dynamic padding
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    ResponsiveHomeUtils.getGridCrossAxisCount(context).toInt(),
                childAspectRatio:
                    ResponsiveHomeUtils.getGridChildAspectRatio(context),
                crossAxisSpacing: ResponsiveHomeUtils.getGridSpacing(context),
                mainAxisSpacing: ResponsiveHomeUtils.getGridSpacing(context),
              ),
              children: [
                WorkActionGridItem(
                  key: const Key('new_booking'),
                  action: const AppAction(
                      id: '1',
                      title: 'Add New Booking',
                      color: Color.fromARGB(9, 127, 152, 97)),
                  onActionSelected: () {
                    _selectAction(context, 'new_booking');
                  },
                ),
                WorkActionGridItem(
                    key: const Key('list_booking'),
                    action: const AppAction(
                        id: '2',
                        title: 'List of Bookings',
                        color: Color.fromARGB(8, 233, 190, 98)),
                    onActionSelected: () {
                      _selectAction(context, 'list_booking');
                    }),
                WorkActionGridItem(
                    key: const Key('add_service_item'),
                    action: const AppAction(
                        id: '3',
                        title: 'Add New Service Item',
                        color: Color.fromARGB(6, 55, 67, 46)),
                    onActionSelected: () {
                      _selectAction(context, 'add_service_item');
                    }),
                WorkActionGridItem(
                  key: const Key('view_work_items'),
                  action: const AppAction(
                      id: '4',
                      title: 'View Work Items',
                      color: Color.fromARGB(6, 144, 176, 119)),
                  onActionSelected: () {
                    _selectAction(context, 'view_work_items');
                  },
                ),
              ],
            ),
          ),
          // Testing button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.note_add),
                label: const Text('Go to Journal Entry'),
                onPressed: () => _navigateToJournalPage(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
