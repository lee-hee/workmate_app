import 'package:flutter/material.dart';
import 'package:workmate_app/model/app_action.dart';

class WorkActionGridItem extends StatelessWidget {
  const WorkActionGridItem(
      {super.key, required this.action, required this.onActionSelected});

  final AppAction action;
  final void Function() onActionSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onActionSelected,
      splashColor: Theme.of(context).primaryColor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: [
            action.color.withOpacity(0.55),
            action.color.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )),
        child: Text(
          action.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
              ),
        ),
      ),
    );
  }
}
