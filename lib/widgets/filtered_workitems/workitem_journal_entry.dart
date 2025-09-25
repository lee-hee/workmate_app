import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'
    show
        File,
        Platform; // which is not supported on web caused to upload images from web
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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  String? _selectedRecordType;
  DateTime? _selectedCompletionDateTime;
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

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
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
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
    if (image != null && mounted) {
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
      'note': _detailsController.text,
      'newWorkItemCost': double.tryParse(_costController.text) ?? 0.0,
      'newWorkItemCompletionDate':
          _selectedCompletionDateTime?.toIso8601String(),
      'workItemJournalType':
          _recordTypeMapping[_selectedRecordType] ?? 'COMMENT',
    };

    final url =
        BackendConfig.getUri('v1/workitem/journal/${widget.workItemId}');
    print('Submitting journal record: $workItemJournalRecordDto');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(workItemJournalRecordDto),
      );
      print('POST $url: ${response.statusCode} - ${response.body}');

      // 1️. Try parsing response if body is not empty
      if (response.statusCode == 200 || response.statusCode == 201) {
        int? recordId;
        if (response.body.isNotEmpty) {
          try {
            final responseData = json.decode(response.body);
            recordId = responseData['journalRecordId'];
          } catch (e) {
            print('Response not JSON or missing id: $e');
          }
        }

        // 2️. Fallback: fetch latest record if no id returned
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
          // var request = http.MultipartRequest('POST', imgUrl)
          //   ..files.add(
          //       await http.MultipartFile.fromPath('file', _pickedImage!.path));
          // final imgResponse = await request.send();
          var request = http.MultipartRequest('POST', imgUrl);
          if (kIsWeb) {
            // Web: Use bytes from XFile
            final bytes = await _pickedImage!.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'fileUpload',
              bytes,
              filename: 'image_${recordId}.jpg',
            ));
          } else {
            // Mobile: Use file path
            request.files.add(
              await http.MultipartFile.fromPath(
                'fileUpload',
                _pickedImage!.path,
                filename: 'image_${recordId}.jpg',
              ),
            );
          }
          final imgResponse = await request.send();
          final imgResponseBody = await imgResponse.stream.bytesToString();
          // print(
          //     'Image upload to $imgUrl: ${imgResponse.statusCode} - ${await imgResponse.stream.bytesToString()}');
          // if (imgResponse.statusCode != 200 && imgResponse.statusCode != 201) {
          //   throw Exception('Failed to upload image');
          // }
          print(
              'Image upload to $imgUrl: ${imgResponse.statusCode} - $imgResponseBody');
          if (imgResponse.statusCode != 200 && imgResponse.statusCode != 201) {
            throw Exception('Failed to upload image: $imgResponseBody');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journal record added successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save journal record: ${response.body}');
      }
    } catch (e) {
      print('Error submitting journal record: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
            child: _pickedImage == null
                ? const Center(child: Text('Tap to add photo'))
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
                      )),
          ),
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
            decoration: const InputDecoration(border: OutlineInputBorder()),
            child: Text(
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
      appBar: AppBar(title: const Text('Add Journal Record')),
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
