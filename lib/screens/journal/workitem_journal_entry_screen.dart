import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// Config
import '../../config/backend_config.dart';
// Models
import '../../model/work_item.dart';
// Utils
import '../../utils/responsive_utils/filtered_workitems/journal_entry_util.dart';

class JournalFormScreen extends StatefulWidget {
  final int workItemId;
  final WorkItem workItem;

  const JournalFormScreen({
    super.key,
    required this.workItemId,
    required this.workItem,
  });

  @override
  State<JournalFormScreen> createState() => _JournalFormScreenState();
}

class _JournalFormScreenState extends State<JournalFormScreen> {
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
    XFile? image;
    if (kIsWeb) {
      image =
          await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    } else if (Platform.isAndroid || Platform.isIOS) {
      image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
      );
    }

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

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(workItemJournalRecordDto),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        int? recordId;

        // Try parsing response if body is not empty
        if (response.body.isNotEmpty) {
          try {
            final responseData = json.decode(response.body);
            recordId = responseData['journalRecordId'];
          } catch (e) {
            print('Response not JSON or missing id: $e');
          }
        }

        // Fallback: fetch latest record if no id returned
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

        // Upload image if available
        if (_pickedImage != null && recordId != null) {
          final imgUrl = BackendConfig.getUri('v1/journal-image/$recordId');
          var request = http.MultipartRequest('POST', imgUrl);

          if (kIsWeb) {
            final bytes = await _pickedImage!.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'fileUpload',
              bytes,
              filename: 'image_$recordId.jpg',
            ));
          } else {
            request.files.add(
              await http.MultipartFile.fromPath(
                'fileUpload',
                _pickedImage!.path,
                filename: 'image_$recordId.jpg',
              ),
            );
          }

          final imgResponse = await request.send();
          final imgResponseBody = await imgResponse.stream.bytesToString();

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleWorkAction() {
    // TODO: Implement work action functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Work Action - To be implemented')),
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldSpacing = ResponsiveJournalUtils.getFieldSpacing(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Journal Record')),
      body: Center(
        child: SizedBox(
          width: ResponsiveJournalUtils.getMaxWidth(context),
          child: Padding(
            padding: ResponsiveJournalUtils.getPagePadding(context),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormField(
                      label: 'Journal record type',
                      child: DropdownButtonFormField<String>(
                        value: _selectedRecordType,
                        items: _recordTypeMapping.keys
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRecordType = value;
                          });
                        },
                        decoration:
                            const InputDecoration(border: OutlineInputBorder()),
                        validator: (value) => value == null ? 'Required' : null,
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    _buildFormField(
                      label: 'Journal record detail',
                      child: SizedBox(
                        height:
                            ResponsiveJournalUtils.getTextFieldHeight(context) *
                                2,
                        child: TextFormField(
                          controller: _detailsController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter details here...',
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    _buildFormField(
                      label: 'Attach Photo',
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height:
                              ResponsiveJournalUtils.getImageHeight(context),
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
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_pickedImage!.path),
                                      fit: BoxFit.cover,
                                    )),
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing),

                    _buildFormField(
                      label: 'Cost adjustment',
                      child: TextFormField(
                        controller: _costController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
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
                    ),
                    SizedBox(height: fieldSpacing),

                    _buildFormField(
                      label: 'New Completion Date/Time',
                      child: GestureDetector(
                        onTap: _pickCompletionDateTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                          child: Text(
                            _selectedCompletionDateTime?.toString() ??
                                'Select date and time',
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing * 1.5),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _handleWorkAction,
                          icon: const Icon(Icons.work_outline),
                          label: const Text('Work Action'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
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
                    ),
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
