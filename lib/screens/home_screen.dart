import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poster_tool/data/poster_db_service.dart';
import 'package:poster_tool/routes/app_routes.dart';

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
  final _cropController = CropController();
  final _scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();
  final List<File?> _images = [null, null, null];

  bool _isPickingImage = false;
  bool _isSaving = false;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showQuickStart();
    });
  }

  @override
  void dispose() {
    _typeController.dispose();
    _modelController.dispose();
    _priceController.dispose();
    _distanceController.dispose();
    _engineController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _phoneController.dispose();
    _webIdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showQuickStart() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quick Start'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Add up to 3 cropped images for the vehicle.'),
              SizedBox(height: 8),
              Text('2. Fill the poster fields and keep the ID unique.'),
              SizedBox(height: 8),
              Text('3. Save the poster, review it, then export the final asset.'),
              SizedBox(height: 8),
              Text(
                'You can also import many posters from Excel if your sheet follows the app field order.',
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(int index) async {
    setState(() => _isPickingImage = true);
    try {
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        return;
      }

      final Uint8List inputData = await picked.readAsBytes();
      final File? croppedFile = await showDialog<File?>(
        context: context,
        builder: (context) {
          final navigator = Navigator.of(context);
          var closed = false;

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
                        if (closed) {
                          return;
                        }

                        if (result is CropSuccess) {
                          closed = true;
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
                          await outFile.writeAsBytes(result.croppedImage);
                          navigator.pop(outFile);
                          return;
                        }

                        closed = true;
                        navigator.pop(null);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FilledButton(
                          onPressed: _cropController.crop,
                          child: const Text('Crop & Save'),
                        ),
                        TextButton(
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

      if (!mounted || croppedFile == null) {
        return;
      }

      setState(() {
        _images[index] = croppedFile;
      });
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      _showMessage('Please complete the required fields correctly.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await PosterDbService.instance.insertPoster(
        image1: _images[0]?.path,
        image2: _images[1]?.path,
        image3: _images[2]?.path,
        type: _typeController.text,
        model: _modelController.text,
        price: _parseOptionalNumber(_priceController.text),
        distanceTraveled: _parseOptionalNumber(_distanceController.text),
        engineSize: _engineController.text,
        location: _locationController.text,
        notes: _notesController.text
            .split(',')
            .map((note) => note.trim())
            .where((note) => note.isNotEmpty)
            .toList(),
        phoneNumber: _phoneController.text,
        webId: _webIdController.text,
      );

      _resetForm();
      _showMessage('Poster saved successfully.');
    } catch (error) {
      final message = error.toString().contains('UNIQUE constraint failed')
          ? 'This ID already exists. Use a different ID.'
          : 'Failed to save the poster.';
      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _importFromExcel() async {
    setState(() => _isImporting = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null || result.files.single.path == null) {
        return;
      }

      final fileBytes = await File(result.files.single.path!).readAsBytes();
      final excel = Excel.decodeBytes(fileBytes);

      final appDir = await getApplicationDocumentsDirectory();
      final uploadDir = Directory(p.join(appDir.path, 'poster_tool_upload'));
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      Future<String?> ensureImageInUpload(String? imagePath) async {
        if (imagePath == null) {
          return null;
        }
        final trimmed = imagePath.trim();
        if (trimmed.isEmpty) {
          return null;
        }
        if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
          return trimmed;
        }

        final file = File(trimmed);
        if (!await file.exists()) {
          return null;
        }

        final outPath = p.join(
          uploadDir.path,
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(trimmed)}',
        );
        final copied = await file.copy(outPath);
        return copied.path;
      }

      var inserted = 0;
      var skipped = 0;

      for (final table in excel.tables.keys) {
        final rows = excel.tables[table]!.rows;
        if (rows.length <= 1) {
          continue;
        }

        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          final type = _cellValue(row, 3);
          final model = _cellValue(row, 4);
          final webId = _cellValue(row, 11);

          if (type.isEmpty || model.isEmpty || webId.isEmpty) {
            skipped++;
            continue;
          }

          try {
            final image1 = await ensureImageInUpload(_cellValue(row, 0));
            final image2 = await ensureImageInUpload(_cellValue(row, 1));
            final image3 = await ensureImageInUpload(_cellValue(row, 2));

            await PosterDbService.instance.insertPoster(
              image1: image1,
              image2: image2,
              image3: image3,
              type: type,
              model: model,
              price: _parseOptionalNumber(_cellValue(row, 5)),
              distanceTraveled: _parseOptionalNumber(_cellValue(row, 6)),
              engineSize: _cellValue(row, 7),
              location: _cellValue(row, 8),
              notes: _cellValue(row, 9)
                  .split(',')
                  .map((note) => note.trim())
                  .where((note) => note.isNotEmpty)
                  .toList(),
              phoneNumber: _cellValue(row, 10),
              webId: webId,
            );
            inserted++;
          } catch (_) {
            skipped++;
          }
        }
      }

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Import Complete'),
            content: Text(
              'Imported $inserted poster(s). Skipped $skipped row(s) because they were incomplete or invalid.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage('Excel import failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _typeController.clear();
    _modelController.clear();
    _priceController.clear();
    _distanceController.clear();
    _engineController.clear();
    _locationController.clear();
    _notesController.clear();
    _phoneController.clear();
    _webIdController.clear();
    setState(() {
      _images.fillRange(0, _images.length, null);
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index]?.value == null) {
      return '';
    }
    return row[index]!.value.toString().trim();
  }

  double? _parseOptionalNumber(String raw) {
    final normalized = raw.replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  Widget _buildImagePicker(int index) {
    final image = _images[index];

    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isPickingImage ? null : () => _pickImage(index),
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF2F2F2),
                  image: image != null
                      ? DecorationImage(
                          image: FileImage(image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: image == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 30),
                          SizedBox(height: 8),
                          Text('Add image'),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Image ${index + 1}'),
                Row(
                  children: [
                    IconButton(
                      tooltip: image == null ? 'Select image' : 'Replace image',
                      onPressed: _isPickingImage ? null : () => _pickImage(index),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Remove image',
                      onPressed: image == null
                          ? null
                          : () => setState(() => _images[index] = null),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
        ),
        validator: validator ??
            (required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter $label';
                    }
                    return null;
                  }
                : null),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearForm() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Form'),
          content: const Text(
            'This will remove the current draft values and selected images.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (shouldClear == true) {
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Poster'),
        actions: [
          IconButton(
            tooltip: 'Creation guide',
            onPressed: _showQuickStart,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: 'View all posters',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.allPosters),
            icon: const Icon(Icons.view_list_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: RawScrollbar(
            controller: _scrollController,
            interactive: true,
            thumbVisibility: true,
            trackVisibility: false,
            thickness: 10,
            radius: const Radius.circular(999),
            thumbColor: const Color(0xFF17652F),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: ListView(
                controller: _scrollController,
                primary: false,
                padding: const EdgeInsets.all(24),
                children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1C6B34), Color(0xFFB4892B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Poster production workspace',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Prepare ad data, crop vehicle images, save reusable records, and export channel-ready posters from the review screen.',
                      style: TextStyle(color: Colors.white, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionCard(
                      title: 'Images',
                      subtitle:
                          'Use up to 3 images. Each one can be cropped before it is saved.',
                      trailing: _isPickingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                      child: Row(children: List.generate(3, _buildImagePicker)),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Poster Details',
                      subtitle:
                          'The type, model, and ID are required because they define the poster record.',
                      child: Column(
                        children: [
                          _buildTextField(
                            _typeController,
                            'Type',
                            required: true,
                            helperText: 'Example: Sedan, SUV, Pickup',
                          ),
                          _buildTextField(
                            _modelController,
                            'Model',
                            required: true,
                            helperText: 'Example: Toyota Camry 2023',
                          ),
                          _buildTextField(
                            _priceController,
                            'Price',
                            keyboard: TextInputType.number,
                            helperText: 'Numbers only. Commas are allowed.',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return _parseOptionalNumber(value) == null
                                  ? 'Enter a valid number'
                                  : null;
                            },
                          ),
                          _buildTextField(
                            _distanceController,
                            'Distance Traveled',
                            keyboard: TextInputType.number,
                            helperText: 'Mileage or traveled distance.',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return null;
                              }
                              return _parseOptionalNumber(value) == null
                                  ? 'Enter a valid number'
                                  : null;
                            },
                          ),
                          _buildTextField(_engineController, 'Engine Size'),
                          _buildTextField(_locationController, 'Location'),
                          _buildTextField(
                            _notesController,
                            'Notes',
                            maxLines: 3,
                            helperText:
                                'Separate multiple notes with commas. They will appear as poster bullets.',
                          ),
                          _buildTextField(
                            _phoneController,
                            'Phone Number',
                            keyboard: TextInputType.phone,
                          ),
                          _buildTextField(
                            _webIdController,
                            'Poster ID',
                            required: true,
                            helperText: 'Must stay unique across posters.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Bulk Import',
                      subtitle:
                          'Expected column order: image1, image2, image3, type, model, price, distance, engine, location, notes, phone, ID.',
                      trailing: IconButton(
                        tooltip: 'Import posters from Excel',
                        onPressed: _isImporting ? null : _importFromExcel,
                        icon: _isImporting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_outlined),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4EA),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Rows missing Type, Model, or ID are skipped automatically. Local image paths are copied into the app upload folder so poster previews remain stable.',
                          style: TextStyle(height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _submit,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: const Text('Save Poster'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _confirmClearForm,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Clear Draft'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.allPosters),
                          icon: const Icon(Icons.list_alt_outlined),
                          label: const Text('Show All Posters'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
