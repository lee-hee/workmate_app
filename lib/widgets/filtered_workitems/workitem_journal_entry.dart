// Packages
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
  final TextEditingController _timeController = TextEditingController();
  String? _selectedRecordType;

  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _recordTypes = [
    'Maintenance',
    'Repair',
    'Inspection',
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera, // camera or gallery
      maxWidth: 800,
    );

    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  void _submitForm() {
    // Method of submission
    if (_selectedRecordType == null ||
        _detailsController.text.isEmpty ||
        _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    print('Record Type: $_selectedRecordType');
    print('Details: ${_detailsController.text}');
    print('Cost: ${_costController.text}');
    print('Time: ${_timeController.text}');
    print('Image Path: ${_pickedImage!.path}');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveJournalUtils.isWideScreen(context);

    Widget formFields = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown
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

        // Text area
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

        // Cost adjustment
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

        // Time adjustment
        const Text('Time adjustment'),
        const SizedBox(height: 6),
        TextField(
          controller: _timeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter time in hours',
            prefixIcon: Icon(Icons.timer),
          ),
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),

        // Attach Photo
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
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                      )),
          ),
        ),
        SizedBox(height: ResponsiveJournalUtils.getFieldSpacing(context)),

        // Submit Button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: _submitForm,
            child: const Text('Add'),
          ),
        )
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Work item journal records')),
      body: Padding(
        padding: ResponsiveJournalUtils.getPagePadding(context),
        child: SingleChildScrollView(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: formFields),
                    const SizedBox(width: 40),
                    Expanded(
                      child: _pickedImage == null
                          ? Container(
                              height: ResponsiveJournalUtils.getImageHeight(
                                  context),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey, width: 1),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: const Center(
                                  child: Text('Image will preview here')),
                            )
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
                  ],
                )
              : formFields,
        ),
      ),
    );
  }
}

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';

// class ImageInput extends StatefulWidget {
//   const ImageInput({super.key});

//   @override
//   State<ImageInput> createState() {
//     return _ImageInputState();
//   }
// }

// class _ImageInputState extends State<ImageInput> {
//   File? _selectedImage;

//   void _takePicture() async {
//     final imagePicker = ImagePicker();
//     final pickedImage =
//         await imagePicker.pickImage(source: ImageSource.camera, maxWidth: 600);

//     if (pickedImage == null) {
//       return;
//     }

//     setState(() {
//       _selectedImage = File(pickedImage.path);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget content = TextButton.icon(
//       icon: const Icon(Icons.camera),
//       label: const Text('Take Picture'),
//       onPressed: _takePicture,
//     );

//     if (_selectedImage != null) {
//       content = GestureDetector(
//         onTap: _takePicture,
//         child: Image.file(
//           _selectedImage!,
//           fit: BoxFit.cover,
//           width: double.infinity,
//           height: double.infinity,
//         ),
//       );
//     }

//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(
//           width: 1,
//           color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
//         ),
//       ),
//       height: 250,
//       width: double.infinity,
//       alignment: Alignment.center,
//       child: content,
//     );
//   }
// }
