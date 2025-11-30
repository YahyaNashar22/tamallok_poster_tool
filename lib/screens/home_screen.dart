import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poster_tool/data/poster_db_service.dart';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _modelController = TextEditingController();
  final _priceController = TextEditingController();
  final _distanceController = TextEditingController();
  final _engineController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneController = TextEditingController();
  final _webIdController = TextEditingController();

  final List<File?> _images = [null, null, null];
  final ImagePicker _picker = ImagePicker();
  final _cropController = CropController();

  bool _isPickingImage = false;

  Future<void> _pickImage(int index) async {
    setState(() => _isPickingImage = true);
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      if (!mounted) return;
      setState(() => _isPickingImage = false);
      return;
    }

    final Uint8List inputData = await picked.readAsBytes();

    // show crop dialog
    final File? croppedFile = await showDialog<File?>(
      context: context,
      builder: (context) {
        final navigator = Navigator.of(context);
        // Local flag to ensure we only pop the dialog once even if crop() is
        // triggered multiple times (prevents double-pop crashes).
        bool closed = false;

        return Dialog(
          child: SizedBox(
            width: 700,
            height: 700,
            child: Column(
              children: [
                Expanded(
                  child: Crop(
                    controller: _cropController,
                    image: inputData,
                    onCropped: (result) async {
                      if (closed) return;

                      if (result is CropSuccess) {
                        closed = true;
                        final Uint8List croppedBytes = result.croppedImage;
                        final dir = await getApplicationDocumentsDirectory();
                        final uploadDir = Directory(
                          p.join(dir.path, 'poster_tool_upload'),
                        );
                        if (!await uploadDir.exists()) {
                          await uploadDir.create(recursive: true);
                        }
                        final outPath = p.join(
                          uploadDir.path,
                          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}',
                        );
                        final outFile = File(outPath);
                        await outFile.writeAsBytes(croppedBytes);
                        navigator.pop(outFile);
                        return;
                      }

                      // handle failure
                      if (result is CropFailure) {
                        if (!closed) {
                          closed = true;
                          navigator.pop(null);
                        }
                        return;
                      }

                      if (!closed) {
                        closed = true;
                        navigator.pop(null);
                      }
                    },
                  ),
                ),

                // controls
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // trigger crop with current area
                          _cropController.crop();
                        },
                        child: const Text('Crop & Save'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (!closed) {
                            closed = true;
                            navigator.pop(null);
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _isPickingImage = false;
      if (croppedFile != null) _images[index] = croppedFile;
    });
  }

  // removed unused _saveImageToUploadFolder to avoid analyzer warnings

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      // Save to database here, e.g.:
      await PosterDbService.instance.insertPoster(
        image1: _images[0]?.path,
        image2: _images[1]?.path,
        image3: _images[2]?.path,
        type: _typeController.text,
        model: _modelController.text,
        price: double.tryParse(_priceController.text),
        distanceTraveled: double.tryParse(_distanceController.text),
        engineSize: _engineController.text,
        location: _locationController.text,
        notes: _notesController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        phoneNumber: _phoneController.text,
        webId: _webIdController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poster saved successfully')),
      );

      _formKey.currentState!.reset();
      setState(() => _images.fillRange(0, 3, null));
    }
  }

  Widget _buildImagePicker(int index) {
    return GestureDetector(
      onTap: () => _pickImage(index),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade100,
          image: _images[index] != null
              ? DecorationImage(
                  image: FileImage(_images[index]!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _images[index] == null
            ? const Icon(Icons.add_a_photo, color: Colors.grey, size: 30)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Poster'), centerTitle: true),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 700),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Poster Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _isPickingImage
                      ? [
                          CircularProgressIndicator(),
                          CircularProgressIndicator(),
                          CircularProgressIndicator(),
                        ]
                      : List.generate(3, _buildImagePicker),
                ),
                const SizedBox(height: 20),
                _buildTextField(_typeController, 'Type', required: true),
                _buildTextField(_modelController, 'Model', required: true),
                _buildTextField(
                  _priceController,
                  'Price',
                  keyboard: TextInputType.number,
                ),
                _buildTextField(
                  _distanceController,
                  'Distance Traveled',
                  keyboard: TextInputType.number,
                ),
                _buildTextField(_engineController, 'Engine Size'),
                _buildTextField(_locationController, 'Location'),
                _buildTextField(
                  _notesController,
                  'Notes (comma separated)',
                  maxLines: 3,
                ),
                _buildTextField(
                  _phoneController,
                  'Phone Number',
                  keyboard: TextInputType.phone,
                ),
                _buildTextField(
                  _webIdController,
                  'ID',
                  keyboard: TextInputType.text,
                ),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Poster'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/all_posters'),
                  icon: const Icon(Icons.list),
                  label: const Text('Show All Posters'),
                ),
                OutlinedButton.icon(
                  onPressed: _importFromExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import from Excel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required ? (v) => v!.isEmpty ? 'Enter $label' : null : null,
      ),
    );
  }

  Future<void> _importFromExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null) return;

    final fileBytes = File(result.files.single.path!).readAsBytesSync();
    final excel = Excel.decodeBytes(fileBytes);

    // prepare upload directory once
    final appDir = await getApplicationDocumentsDirectory();
    final uploadDir = Directory(p.join(appDir.path, 'poster_tool_upload'));
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    // helper: ensure a referenced image is copied into uploadDir
    Future<String?> _ensureImageInUpload(String? imagePath) async {
      if (imagePath == null) return null;
      final String trimmed = imagePath.trim();
      if (trimmed.isEmpty) return null;

      // If it's a remote URL, leave it as-is
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
      }

      final File f = File(trimmed);
      if (!await f.exists()) {
        // If the file doesn't exist, return the original path so the importer
        // can decide what to do (or keep it empty)
        return trimmed;
      }

      final String outPath = p.join(
        uploadDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(trimmed)}',
      );
      final File outFile = await f.copy(outPath);
      return outFile.path;
    }

    int inserted = 0;
    for (var table in excel.tables.keys) {
      final rows = excel.tables[table]!.rows;
      if (rows.isEmpty) continue;

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        try {
          // copy images into upload folder (if local files)
          final String? rawImage1 = row.length > 0
              ? row[0]?.value?.toString()
              : null;
          final String? rawImage2 = row.length > 1
              ? row[1]?.value?.toString()
              : null;
          final String? rawImage3 = row.length > 2
              ? row[2]?.value?.toString()
              : null;

          final String? image1 = await _ensureImageInUpload(rawImage1);
          final String? image2 = await _ensureImageInUpload(rawImage2);
          final String? image3 = await _ensureImageInUpload(rawImage3);

          await PosterDbService.instance.insertPoster(
            image1: image1,
            image2: image2,
            image3: image3,
            type: row.length > 3 ? row[3]?.value?.toString() ?? '' : '',
            model: row.length > 4 ? row[4]?.value?.toString() ?? '' : '',
            price: double.tryParse(
              row.length > 5 ? row[5]?.value?.toString() ?? '' : '',
            ),
            distanceTraveled: double.tryParse(
              row.length > 6 ? row[6]?.value?.toString() ?? '' : '',
            ),
            engineSize: row.length > 7 ? row[7]?.value?.toString() : '',
            location: row.length > 8 ? row[8]?.value?.toString() : '',
            notes: row.length > 9
                ? (row[9]?.value != null
                      ? row[9]!.value
                            .toString()
                            .split(',')
                            .map((e) => e.trim())
                            .toList()
                      : [])
                : [],
            phoneNumber: row.length > 10
                ? row[10]?.value?.toString() ?? ''
                : '',
            webId: row.length > 11 ? row[11]?.value?.toString() ?? '' : '',
          );

          inserted++;
        } catch (e) {
          // skip invalid rows silently
          continue;
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('✅ Imported $inserted posters')));
  }
}
