// To do:
// 1. add formKey validator => done
// 2. attach image logic => done
// 3. Accept only single image => done
// 4. Pick full DateTime for newWorkItemCompletionDate => done
// 5. Use full enum for types => done

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Models
import '../../model/work_item.dart';

// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

// Config
import '../../config/backend_config.dart';

class JournalFormPage extends StatefulWidget {
  // fetch work item id and item details
  final int workItemId;
  final WorkItem workItem;

  const JournalFormPage(
      {super.key, required this.workItemId, required this.workItem});

  @override
  State<JournalFormPage> createState() => _JournalFormPageState();
}

class _JournalFormPageState extends State<JournalFormPage> {
  final _formKey = GlobalKey<FormState>(); // For validation
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  String? _selectedRecordType;
  DateTime? _selectedCompletionDateTime;

  // final List<XFile> _pickedImages = [];
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  // final List<String> _recordTypes = [
  //   'INTERNAL',
  //   'COMMENT',
  //   'PRICE ADJUST',
  //   'TIME ADJUST',
  //   'EXTERNAL EMAIL ONLY',
  //   'EXTERNAL SMS ONLY',
  //   'EXTERNAL SMS AND EMAIL',
  // ];
  final Map<String, String> _recordTypeMapping = {
    'Internal': 'INTERNAL',
    'Comment': 'COMMENT',
    'Price Adjust': 'PRICE_ADJUST',
    'Time Adjust': 'TIME_ADJUST',
    'External Email Only': 'EXTERNAL_EMAIL_ONLY',
    'External SMS Only': 'EXTERNAL_SMS_ONLY',
    'External SMS and Email': 'EXTERNAL_SMS_AND_EMAIL',
  };

  // Duration from Complete DateTime picker method
  Future<void> _pickCompletionDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedCompletionDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
    );

    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final workItemJournalRecordDto = {
      "note": _detailsController.text,
      "newWorkItemCost": double.tryParse(_costController.text) ?? 0,
      "newWorkItemCompletionDate":
          _selectedCompletionDateTime?.toIso8601String(),
      // "workItemJournalType": _selectedRecordType,
      "workItemJournalType":
          _recordTypeMapping[_selectedRecordType] ?? 'INTERNAL'
    };

    final url =
        BackendConfig.getUri('v1/workitem/journal/${widget.workItemId}');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: json.encode(workItemJournalRecordDto),
    );

    // if (response.statusCode == 200) {
    // Upload image separately
    // if (_pickedImage != null) {
    //   final recordId = json.decode(response.body)['journalRecordId'];
    //   final imgUrl = BackendConfig.getUri('v1/journal-image/$recordId');
    //   var request = http.MultipartRequest("POST", imgUrl)
    //     ..files.add(
    //         await http.MultipartFile.fromPath("file", _pickedImage!.path));
    //   await request.send();
    // }

    if (response.statusCode == 200 || response.statusCode == 201) {
      int? recordId;

      // 1️. Try parsing response if body is not empty
      if (response.body.isNotEmpty) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          recordId = responseData['journalRecordId'];
        } catch (e) {
          debugPrint("Response not JSON or missing id: $e");
        }
      }

      // 2️. Fallback: fetch latest record if no id
      if (recordId == null) {
        final listUrl =
            BackendConfig.getUri('v1/workitem/journal/${widget.workItemId}');
        final listResp = await http.get(listUrl);
        if (listResp.statusCode == 200 && listResp.body.isNotEmpty) {
          final List<dynamic> list = json.decode(listResp.body);
          if (list.isNotEmpty) {
            recordId = list.last['journalRecordId'];
          }
        }
      }

      // 3️. Upload image if available
      if (_pickedImage != null && recordId != null) {
        final imgUrl = BackendConfig.getUri('v1/journal-image/$recordId');
        var request = http.MultipartRequest("POST", imgUrl)
          ..files.add(
              await http.MultipartFile.fromPath("file", _pickedImage!.path));
        await request.send();
      }

      Navigator.pop(context, true); // Go back and refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save journal record: ${response.body}')),
      );
    }
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
          items: _recordTypeMapping.keys
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRecordType = value;
            });
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
          validator: (value) => value == null ? 'Required' : null,
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),
        const Text('Journal record detail'),
        const SizedBox(height: 6),
        SizedBox(
          height: ResponsiveJournalUtils.getTextFieldHeight(context) * 2,
          child: TextFormField(
            controller: _detailsController,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter details here...',
            ),
            validator: (value) => value!.isEmpty ? 'Required' : null,
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
              child: _pickedImage == null
                  ? const Center(child: Text('Tap to add photo'))
                  : (kIsWeb
                      ? Image.network(
                          _pickedImage!.path,
                          height:
                              ResponsiveJournalUtils.getImageHeight(context),
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_pickedImage!.path),
                          height:
                              ResponsiveJournalUtils.getImageHeight(context),
                          fit: BoxFit.cover,
                        ))),
        ),
      ],
    );

    Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cost adjustment'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _costController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter cost',
            prefixIcon: Icon(Icons.attach_money),
          ),
          validator: (value) =>
              value!.isNotEmpty && double.tryParse(value) == null
                  ? 'Invalid cost'
                  : null,
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),
        const Text('New Completion Date/Time'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pickCompletionDateTime,
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              // errorText: _isDurationValid ? null : 'Duration cannot be empty',
            ),
            child: Text(
              // '${_selectedDuration.hour.toString().padLeft(2, '0')}h:${_selectedDuration.minute.toString().padLeft(2, '0')}m',
              _selectedCompletionDateTime?.toString() ?? 'Select date and time',
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
              child: Form(
                key: _formKey,
                child: isWide
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: leftColumn),
                              const SizedBox(width: 40),
                              Expanded(flex: 1, child: rightColumn),
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
      ),
    );
  }
}
