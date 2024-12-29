import 'package:flutter/material.dart';
import 'package:workmate_app/model/app_action.dart';
import 'package:workmate_app/widgets/assigned_workitems/assigned_workitem.dart';
import 'package:workmate_app/widgets/booking_list/booking_calendar.dart';
import 'package:workmate_app/widgets/home_view/work_action_grid_item.dart';
import 'package:workmate_app/widgets/new_booking/new_booking.dart';
import 'package:workmate_app/widgets/register_user/register_new_user.dart';
import 'package:workmate_app/widgets/service_item/service_item_screen.dart';

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
    } else if ('register_user' == actionKey){
      navigatingWidget = const RegisterUserScreen();
    } else {
      navigatingWidget = const AssignedWorkItemScreen();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => navigatingWidget,
      ),
    ); // Navigator.push(context, route)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Action'),
      ),
      body: GridView(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        children: [
          WorkActionGridItem(
            key: const Key('new_booking'),
            action: const AppAction(
                id: '1',
                title: 'New booking',
                color: Color.fromARGB(9, 127, 152, 97)),
            onActionSelected: () {
              _selectAction(context, 'new_booking');
            },
          ),
          WorkActionGridItem(
              key: const Key('list_booking'),
              action: const AppAction(
                  id: '2',
                  title: 'List bookins',
                  color: Color.fromARGB(8, 233, 190, 98)),
              onActionSelected: () {
                _selectAction(context, 'list_booking');
              }),
          WorkActionGridItem(
              key: const Key('add_service_item'),
              action: const AppAction(
                  id: '3',
                  title: 'Add new service item',
                  color: Color.fromARGB(6, 55, 67, 46)),
              onActionSelected: () {
                _selectAction(context, 'add_service_item');
              }),
          WorkActionGridItem(
              key: const Key('view_work_items'),
              action: const AppAction(
                  id: '4',
                  title: 'View work items',
                  color: Color.fromARGB(6, 144, 176, 119)),
              onActionSelected: () {
                _selectAction(context, 'view_work_items');
              }),
          WorkActionGridItem(
              key: const Key('register_user'),
              action: const AppAction(
                  id: '5',
                  title: 'Register User',
                  color: Color.fromARGB(6, 172, 200, 100)),
              onActionSelected: () {
                _selectAction(context, 'register_user');
              }),
        ],
      ),
    );
  }
}
