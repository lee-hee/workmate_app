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
  String? _statusChange;

  final Map<String, String> _recordTypeMapping = {
    'Internal': 'INTERNAL',
    'Comment': 'COMMENT',
    'Price Adjust': 'PRICE_ADJUST',
    'Time Adjust': 'TIME_ADJUST',
    'External Email Only': 'EXTERNAL_EMAIL_ONLY',
    'External SMS Only': 'EXTERNAL_SMS_ONLY',
    'External SMS and Email': 'EXTERNAL_SMS_AND_EMAIL',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    _costController.dispose();
    super.dispose();
  }

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
      image =
          await _picker.pickImage(source: ImageSource.camera, maxWidth: 800);
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
        int? recordId = _extractRecordId(response);

        // Fallback: fetch latest record if no id returned
        recordId ??= await _fetchLatestRecordId();

        // Upload image if available
        if (_pickedImage != null && recordId != null) {
          await _uploadImage(recordId);
        }

        // Update status if changed
        bool statusUpdateSuccess = await _updateStatusIfChanged();

        if (mounted) {
          _showSuccessMessage(statusUpdateSuccess);
          setState(() {
            _statusChange = null;
          });
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

  int? _extractRecordId(http.Response response) {
    if (response.body.isNotEmpty) {
      try {
        final responseData = json.decode(response.body);
        return responseData['journalRecordId'];
      } catch (e) {
        print('Response not JSON or missing id: $e');
      }
    }
    return null;
  }

  Future<int?> _fetchLatestRecordId() async {
    final listUrl =
        BackendConfig.getUri('v1/workitem/journal/${widget.workItemId}');
    final listResp = await http.get(listUrl);
    if (listResp.statusCode == 200 && listResp.body.isNotEmpty) {
      final List<dynamic> list = json.decode(listResp.body);
      if (list.isNotEmpty) {
        return list.last['journalRecordId'];
      }
    }
    return null;
  }

  Future<void> _uploadImage(int recordId) async {
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

  Future<bool> _updateStatusIfChanged() async {
    if (_statusChange != null &&
        _statusChange != widget.workItem.workItemStatus) {
      final statusUrl = BackendConfig.getUri(
          'v1/workitem/${widget.workItemId}/status/${_statusChange!.toUpperCase()}');
      final statusResponse = await http.post(statusUrl);

      if (statusResponse.statusCode != 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Journal added, but status update failed: ${statusResponse.body}'),
          ),
        );
        return false;
      }
      return true;
    }
    return true;
  }

  void _showSuccessMessage(bool statusUpdateSuccess) {
    String message = statusUpdateSuccess
        ? 'Journal record added${_statusChange != null ? " and status updated to $_statusChange" : ""} successfully'
        : 'Journal record added, but status update failed';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Pop up window for status selection
  Future<void> _showStatusSelectionDialog(WorkItem workItem) async {
    String? selected = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.work_outline,
                      color: Theme.of(ctx).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Update Work Status",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Current Status Display
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(
                      workItem.getIconBasedOnStatus().icon,
                      color: workItem.getIconColorBasedOnStatus(),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            workItem.workItemStatus.replaceAll('_', ' '),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: WorkItem.statuses.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final status = WorkItem.statuses[index];
                    final isCurrentStatus = status == workItem.workItemStatus;

                    final tempWorkItem = WorkItem(
                      id: workItem.id,
                      assignedUserName: workItem.assignedUserName,
                      serviceName: workItem.serviceName,
                      duration: workItem.duration,
                      rego: workItem.rego,
                      cost: workItem.cost,
                      workItemStatus: status,
                      startedDateTime: workItem.startedDateTime,
                      uniqueBookingRefIdentifier:
                          workItem.uniqueBookingRefIdentifier,
                    );

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isCurrentStatus
                            ? null
                            : () => Navigator.pop(ctx, status),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: tempWorkItem
                                      .getIconColorBasedOnStatus()
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  tempWorkItem.getIconBasedOnStatus().icon,
                                  color:
                                      tempWorkItem.getIconColorBasedOnStatus(),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      status.replaceAll('_', ' '),
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: isCurrentStatus
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      tempWorkItem.getWorkItemStatusString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrentStatus)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                )
                              else
                                Icon(Icons.chevron_right,
                                    color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected != workItem.workItemStatus) {
      setState(() {
        _statusChange = selected;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Status will be updated to "${selected.replaceAll("_", " ")}" when you click Add'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_pickedImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Tap to add photo',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: kIsWeb
              ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
              : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => setState(() => _pickedImage = null),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldSpacing = ResponsiveJournalUtils.getFieldSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Journal Record'),
        elevation: 0,
      ),
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
                    if (_statusChange != null)
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Status will be updated to ${_statusChange!.replaceAll("_", " ")}',
                                  style: TextStyle(color: Colors.blue.shade900),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () =>
                                    setState(() => _statusChange = null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_statusChange != null) SizedBox(height: fieldSpacing),
                    _buildFormField(
                      label: 'Journal record type',
                      isRequired: true,
                      child: DropdownButtonFormField<String>(
                        value: _selectedRecordType,
                        items: _recordTypeMapping.keys
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRecordType = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        validator: (value) => value == null
                            ? 'Please select a record type'
                            : null,
                      ),
                    ),
                    SizedBox(height: fieldSpacing),
                    _buildFormField(
                      label: 'Journal record detail',
                      isRequired: true,
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
                            contentPadding: EdgeInsets.all(12),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please enter details'
                              : null,
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
                            border: Border.all(
                                color: Colors.grey.shade300, width: 1),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: _buildImagePreview(),
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
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        validator: (value) => value != null &&
                                value.isNotEmpty &&
                                double.tryParse(value) == null
                            ? 'Please enter a valid number'
                            : null,
                      ),
                    ),
                    SizedBox(height: fieldSpacing),
                    _buildFormField(
                      label: 'New Completion Date/Time',
                      child: InkWell(
                        onTap: _pickCompletionDateTime,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            suffixIcon: Icon(Icons.calendar_today,
                                color: Colors.grey[600]),
                          ),
                          child: Text(
                            _selectedCompletionDateTime != null
                                ? '${_selectedCompletionDateTime!.day}/${_selectedCompletionDateTime!.month}/${_selectedCompletionDateTime!.year} at ${_selectedCompletionDateTime!.hour}:${_selectedCompletionDateTime!.minute.toString().padLeft(2, '0')}'
                                : 'Select date and time',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedCompletionDateTime != null
                                  ? Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: fieldSpacing * 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showStatusSelectionDialog(widget.workItem),
                          icon: const Icon(Icons.work_outline),
                          label: const Text('Work Action'),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: _submitForm,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Add'),
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
