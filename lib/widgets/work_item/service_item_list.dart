// Packages
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Models
import '../../model/assignable_service_item.dart';
import '../../model/service_item.dart';
import '../../model/user.dart';

// Config
import '../../config/backend_config.dart';

// Utils
import '../../utils/responsive_utils/work_item/work_item_util.dart';

class ServiceItemList extends StatefulWidget {
  const ServiceItemList(
      {super.key,
      required this.serviceOffers,
      required this.slectableUsers,
      required this.workItemId});
  final List<ServiceOffer> serviceOffers;
  final List<User> slectableUsers;
  final int workItemId;
  @override
  // ignore: library_private_types_in_public_api
  _ServiceItemListState createState() => _ServiceItemListState();
}

class _ServiceItemListState extends State<ServiceItemList> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ResponsiveWorkItemUtils.getServiceItemListWidth(context),
      height: ResponsiveWorkItemUtils.getServiceItemListHeight(context),
      child: Container(
        margin: ResponsiveWorkItemUtils.getServiceItemListMargin(context),
        padding: ResponsiveWorkItemUtils.getServiceItemListPadding(context),
        decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 48, 144, 97))),
        child: ListView.builder(
            itemCount: widget.serviceOffers.length,
            itemBuilder: (ctx, index) => ListTile(
                  title: Text(widget.serviceOffers[index].name),
                  trailing: getAssignableServiceItems(
                      widget.serviceOffers[index], widget.workItemId),
                )),
      ),
    );
  }

  void setSlectedUser(String? value) {
    // This is called when the user selects an item.
    setState(() {
      //dropdownValue = value!;
    });
  }

  Widget getAssignableServiceItems(ServiceOffer serviceOffer, int workItemId) {
    return Padding(
      padding: ResponsiveWorkItemUtils.getDropdownPadding(
          context), // Responsive padding
      child: DropdownMenu(
          initialSelection: null,
          onSelected: (assignableServiceItem) =>
              {createWorkItem(assignableServiceItem!)},
          dropdownMenuEntries: [
            for (final user in widget.slectableUsers)
              DropdownMenuEntry<AssignableServiceItem>(
                  label: user.name,
                  value: AssignableServiceItem(
                      bookingRef: serviceOffer.bookingRef,
                      serviceItemId: serviceOffer.id,
                      userId: user.id,
                      workItemId:
                          workItemId)) //Create a wrapped entity workitemid<-->user
          ]),
    );
  }

  createWorkItem(AssignableServiceItem assignableServiceItem) async {
    final url = BackendConfig.getUri(
        'v1/workitem/${assignableServiceItem.bookingRef}/${assignableServiceItem.userId}');
    final response = await http.post(url, headers: {
      'Content-Type': 'application/json',
    });
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch servcie offers. Please try again later.');
    }
  }
}
