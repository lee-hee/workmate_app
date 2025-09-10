// To do:
// 1. add formKey validator
// 2. attach image logic

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

class JournalFormPage extends StatefulWidget {
  const JournalFormPage({super.key});

  @override
  State<JournalFormPage> createState() => _JournalFormPageState();
}

class _JournalFormPageState extends State<JournalFormPage> {
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  // final TextEditingController _timeController = TextEditingController();
  String? _selectedRecordType;

  // final List<XFile> _pickedImages = [];
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _recordTypes = [
    'Maintenance',
    'Repair',
    'Inspection',
  ];

  // Duration picker method
  TimeOfDay _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
  bool _isDurationValid = true;

  void _pickDuration() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
      helpText: 'Select Duration (Hh:Mm)',
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDuration = picked;
        _isDurationValid = true; // Reset validation on successful selection
      });
    }
  }

  bool _validateDuration() {
    if (_selectedDuration.hour == 0 && _selectedDuration.minute == 0) {
      setState(() {
        _isDurationValid = false;
      });
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
    );

    if (image != null) {
      setState(() {
        // _pickedImages.add(image);
        _pickedImage = image;
      });
    }
  }

  void _submitForm() {
    if (_selectedRecordType == null ||
        _detailsController.text.isEmpty ||
        _pickedImage == null ||
        !_validateDuration()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final durationMinutes =
        (_selectedDuration.hour * 60) + _selectedDuration.minute;

    print('Record Type: $_selectedRecordType');
    print('Details: ${_detailsController.text}');
    print('Cost: ${_costController.text}');
    // print('Time: ${_timeController.text}');
    print('Duration (minutes): $durationMinutes');
    // for (var image in _pickedImages) {
    //   print('Image Path: ${image.path}');
    // }
    print('Image Path: ${_pickedImage!.path}');

    // Clear form after submission
    setState(() {
      _selectedRecordType = null;
      _detailsController.clear();
      _costController.clear();
      // _timeController.clear();
      _selectedDuration = const TimeOfDay(hour: 0, minute: 0);
      _isDurationValid = true;
      // _pickedImages.clear();
      _pickedImage = null;
    });
    Navigator.pop(context); // Return to previous screen
  }

  void _cancelForm() {
    Navigator.pop(context); // Return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveJournalUtils.isWideScreen(context);

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Journal record type'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedRecordType,
          items: _recordTypes
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRecordType = value;
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),
        const Text('Journal record detail'),
        const SizedBox(height: 6),
        SizedBox(
          height: ResponsiveJournalUtils.getTextFieldHeight(context) * 2,
          child: TextField(
            controller: _detailsController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter details here...',
            ),
          ),
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),
        const Text('Attach Photo'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: ResponsiveJournalUtils.getImageHeight(context),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            // child: _pickedImages.isEmpty
            child: (_pickedImage == null
                ? const Center(child: Text('Tap to add photo'))
                // : SingleChildScrollView(
                //     scrollDirection: Axis.horizontal,
                //     child: Row(
                //       children: _pickedImages.map((image) {
                //         return Padding(
                //           padding: const EdgeInsets.only(right: 8.0),
                //           child: (kIsWeb
                //               ? Image.network(image.path,
                //                   height: ResponsiveJournalUtils.getImageHeight(
                //                       context),
                //                   fit: BoxFit.cover)
                //               : Image.file(File(image.path),
                //                   height: ResponsiveJournalUtils.getImageHeight(
                //                       context),
                //                   fit: BoxFit.cover)),
                //         );
                //       }).toList(),
                //     ),
                //   )
                : (kIsWeb
                    ? Image.network(
                        _pickedImage!.path,
                        height: ResponsiveJournalUtils.getImageHeight(context),
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_pickedImage!.path),
                        height: ResponsiveJournalUtils.getImageHeight(context),
                        fit: BoxFit.cover,
                      ))),
          ),
        ),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cost adjustment'),
        const SizedBox(height: 6),
        TextField(
          controller: _costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter cost',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),
        const Text('Duration (Hh:Mm)'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickDuration,
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              errorText: _isDurationValid ? null : 'Duration cannot be empty',
            ),
            child: Text(
              '${_selectedDuration.hour.toString().padLeft(2, '0')}h:${_selectedDuration.minute.toString().padLeft(2, '0')}m',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
            ),
          ),
        ),
      ],
    );

    Widget buttonRow = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _cancelForm,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8.0),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          onPressed: _submitForm,
          child: const Text('Add'),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Work Item Journal Records')),
      body: Align(
        alignment: ResponsiveJournalUtils.getAlignment(context),
        child: SizedBox(
          width: ResponsiveJournalUtils.getMaxWidth(context),
          child: Padding(
            padding: ResponsiveJournalUtils.getPagePadding(context),
            child: SingleChildScrollView(
              child: isWide
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: leftColumn,
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 1,
                              child: rightColumn,
                            ),
                          ],
                        ),
                        SizedBox(
                            height: ResponsiveJournalUtils.getFieldSpacing(
                                context)),
                        buttonRow,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leftColumn,
                        SizedBox(
                            height: ResponsiveJournalUtils.getFieldSpacing(
                                context)),
                        rightColumn,
                        SizedBox(
                            height: ResponsiveJournalUtils.getFieldSpacing(
                                context)),
                        buttonRow,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
