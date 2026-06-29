import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poster_tool/data/poster_db_service.dart';
import 'package:poster_tool/widgets/custom_icon_btn.dart';

class PosterViewerScreen extends StatefulWidget {
  final Map<String, dynamic> poster;

  const PosterViewerScreen({super.key, required this.poster});

  @override
  State<PosterViewerScreen> createState() => _PosterViewerScreenState();
}

class _PosterViewerScreenState extends State<PosterViewerScreen> {
  final GlobalKey _exportKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  final CropController _cropController = CropController();

  late final Map<String, _PosterEditorLayout> _editorLayouts;

  bool _exporting = false;
  bool _saving = false;
  bool _hasUnsavedEditorChanges = false;
  bool _showEditorChrome = true;
  String _market = 'jordan';
  String _platform = 'meta';
  String? _selectedElementId;

  @override
  void initState() {
    super.initState();
    _editorLayouts = _decodeEditorLayouts(widget.poster['editor_state']);
  }

  String get _activeVariantKey => '${_market}_$_platform';

  _PosterTemplateLayout get _templateLayout {
    if (_platform == 'snap') {
      return _PosterTemplateLayout(
        asset: _market == 'saudi'
            ? 'assets/template/new_SA_snap.jpeg'
            : 'assets/template/new_JOD_snap.jpeg',
        exportPrefix: _market == 'saudi' ? 'saudi_snap' : 'jordan_snap',
        width: 900,
        height: 1600,
        imagesLeft: 38,
        imagesTop: 382,
        imageWidth: 364,
        imageHeight: 265,
        imageGap: 14,
        valueLeft: 536,
        valueWidth: 214,
        valueTops: const [367, 540, 710, 875, 1046, 1214],
        valueHeight: 62,
        valueFontSize: 30,
        notesLeft: 620,
        notesTop: 1380,
        notesWidth: 250,
        notesFontSize: 21,
        phoneLeft: 104,
        phoneTop: 130,
        phoneWidth: 165,
        phoneFontSize: 24,
      );
    }

    return _PosterTemplateLayout(
      asset: _market == 'saudi'
          ? 'assets/template/new_SA_insta.jpeg'
          : 'assets/template/new_JOD_insta.jpeg',
      exportPrefix: _market == 'saudi' ? 'saudi_meta' : 'jordan_meta',
      width: 1080,
      height: 1350,
      imagesLeft: 42,
      imagesTop: 318,
      imageWidth: 520,
      imageHeight: 255,
      imageGap: 14,
      valueLeft: 688,
      valueWidth: 242,
      valueTops: const [300, 440, 576, 710, 843, 970],
      valueHeight: 52,
      valueFontSize: 30,
      notesLeft: 784,
      notesTop: 1188,
      notesWidth: 258,
      notesFontSize: 22,
      phoneLeft: 140,
      phoneTop: 1172,
      phoneWidth: 220,
      phoneFontSize: 24,
    );
  }

  _PosterEditorLayout get _activeEditorLayout {
    return _editorLayouts.putIfAbsent(
      _activeVariantKey,
      () => _createEditorLayout(_templateLayout),
    );
  }

  void _applyJordanMeta() {
    setState(() {
      _market = 'jordan';
      _platform = 'meta';
      _selectedElementId = null;
    });
  }

  void _applyJordanSnap() {
    setState(() {
      _market = 'jordan';
      _platform = 'snap';
      _selectedElementId = null;
    });
  }

  void _applySaudiMeta() {
    setState(() {
      _market = 'saudi';
      _platform = 'meta';
      _selectedElementId = null;
    });
  }

  void _applySaudiSnap() {
    setState(() {
      _market = 'saudi';
      _platform = 'snap';
      _selectedElementId = null;
    });
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '';
    }
    if (value is num) {
      if (value % 1 == 0) {
        return NumberFormat('#,###', 'en_US').format(value.toInt());
      }
      return NumberFormat('#,###.##', 'en_US').format(value);
    }
    final parsed = double.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }
    if (parsed % 1 == 0) {
      return NumberFormat('#,###', 'en_US').format(parsed.toInt());
    }
    return NumberFormat('#,###.##', 'en_US').format(parsed);
  }

  Future<void> _showLayoutHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editor Controls'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tap any element to select it.'),
              SizedBox(height: 8),
              Text('Drag elements to move them around the template.'),
              SizedBox(height: 8),
              Text('Drag the bottom-right handle to resize the selected item.'),
              SizedBox(height: 8),
              Text('Use the editor panel to change text, font size, weight, width, and alignment.'),
              SizedBox(height: 8),
              Text('Use Save to persist editor changes for the current poster.'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editImage(int index) async {
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
                          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(picked.path)}_${widget.poster['web_id']}',
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

    if (croppedFile == null) {
      return;
    }

    final imageField = 'image${index + 1}';

    try {
      widget.poster[imageField] = croppedFile.path;
      await PosterDbService.instance.updatePosterById(
        widget.poster['id'] as int,
        image1: index == 0 ? croppedFile.path : null,
        image2: index == 1 ? croppedFile.path : null,
        image3: index == 2 ? croppedFile.path : null,
      );

      if (!mounted) {
        return;
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image updated successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update image: $error')));
    }
  }

  Future<void> _saveEditorState() async {
    if (_saving || !_hasUnsavedEditorChanges) {
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        for (final entry in _editorLayouts.entries) entry.key: entry.value.toJson(),
      };

      await PosterDbService.instance.updatePosterById(
        widget.poster['id'] as int,
        editorState: payload,
      );

      widget.poster['editor_state'] = payload;

      if (!mounted) {
        return;
      }

      setState(() => _hasUnsavedEditorChanges = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Editor changes saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save editor changes: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _updatePosterTextField(String elementId) async {
    final currentValue = _rawFieldValue(elementId);
    final controller = TextEditingController(text: currentValue);

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${_labelForElementId(elementId)}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: elementId == 'notes' ? 6 : 1,
            decoration: InputDecoration(
              hintText: elementId == 'notes'
                  ? 'Use new lines or commas for multiple notes'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    try {
      final posterId = widget.poster['id'] as int;

      switch (elementId) {
        case 'type':
          widget.poster['type'] = result.trim();
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'type': result,
          });
          break;
        case 'model':
          widget.poster['model'] = result.trim();
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'model': result,
          });
          break;
        case 'price':
          final parsed = double.tryParse(result.trim());
          widget.poster['price'] = parsed;
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'price': parsed,
          });
          break;
        case 'distance_traveled':
          final parsed = double.tryParse(result.trim());
          widget.poster['distance_traveled'] = parsed;
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'distance_traveled': parsed,
          });
          break;
        case 'engine_size':
          widget.poster['engine_size'] = result.trim();
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'engine_size': result,
          });
          break;
        case 'location':
          widget.poster['location'] = result.trim();
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'location': result,
          });
          break;
        case 'phone_number':
          widget.poster['phone_number'] = result.trim();
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'phone_number': result,
          });
          break;
        case 'notes':
          final notes = result
              .split(RegExp(r'[\n,]+'))
              .map((note) => note.trim())
              .where((note) => note.isNotEmpty)
              .toList();
          widget.poster['notes'] = notes;
          await PosterDbService.instance.updatePosterDataById(posterId, {
            'notes': notes,
          });
          break;
      }

      if (!mounted) {
        return;
      }

      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Text updated successfully.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update text: $error')));
    }
  }

  Future<void> _exportAsImage() async {
    if (_exporting) {
      return;
    }

    setState(() => _exporting = true);

    try {
      if (_showEditorChrome) {
        setState(() => _showEditorChrome = false);
      }

      await Future<void>.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      final boundary =
          _exportKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Poster preview is not ready yet.');
      }

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Could not encode preview to PNG.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(p.join(dir.path, 'poster_tool_exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File(
        p.join(
          exportDir.path,
          '${_templateLayout.exportPrefix}_${widget.poster['web_id']}_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(pngBytes);

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Export Complete'),
            content: Text('Poster saved to:\n${file.path}'),
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
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to export: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _exporting = false;
          _showEditorChrome = true;
        });
      }
    }
  }

  Map<String, _PosterEditorLayout> _decodeEditorLayouts(dynamic rawEditorState) {
    final Map<String, dynamic> stateMap;

    if (rawEditorState is Map<String, dynamic>) {
      stateMap = rawEditorState;
    } else if (rawEditorState is Map) {
      stateMap = rawEditorState.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    } else if (rawEditorState is String && rawEditorState.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawEditorState);
        if (decoded is Map<String, dynamic>) {
          stateMap = decoded;
        } else if (decoded is Map) {
          stateMap = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        } else {
          return <String, _PosterEditorLayout>{};
        }
      } catch (_) {
        return <String, _PosterEditorLayout>{};
      }
    } else {
      return <String, _PosterEditorLayout>{};
    }

    final layouts = <String, _PosterEditorLayout>{};
    for (final variant in _supportedVariantKeys) {
      final template = _layoutForVariant(variant);
      final variantJson = stateMap[variant];
      layouts[variant] = _createEditorLayout(template, variantJson);
    }
    return layouts;
  }

  _PosterEditorLayout _createEditorLayout(
    _PosterTemplateLayout layout, [
    dynamic json,
  ]) {
    final defaults = _defaultElements(layout);
    final rawMap = json is Map<String, dynamic>
        ? json
        : json is Map
            ? json.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};

    final elements = <String, _PosterElement>{};
    for (final element in defaults) {
      final saved = rawMap[element.id];
      if (saved is Map<String, dynamic>) {
        elements[element.id] = element.merge(saved);
      } else if (saved is Map) {
        elements[element.id] = element.merge(
          saved.map((key, value) => MapEntry(key.toString(), value)),
        );
      } else {
        elements[element.id] = element;
      }
    }
    return _PosterEditorLayout(elements);
  }

  List<String> get _supportedVariantKeys => const [
        'jordan_meta',
        'jordan_snap',
        'saudi_meta',
        'saudi_snap',
      ];

  _PosterTemplateLayout _layoutForVariant(String variantKey) {
    final parts = variantKey.split('_');
    final market = parts.first;
    final platform = parts.last;

    if (platform == 'snap') {
      return _PosterTemplateLayout(
        asset: market == 'saudi'
            ? 'assets/template/new_SA_snap.jpeg'
            : 'assets/template/new_JOD_snap.jpeg',
        exportPrefix: market == 'saudi' ? 'saudi_snap' : 'jordan_snap',
        width: 900,
        height: 1600,
        imagesLeft: 38,
        imagesTop: 382,
        imageWidth: 364,
        imageHeight: 265,
        imageGap: 14,
        valueLeft: 536,
        valueWidth: 214,
        valueTops: const [367, 540, 710, 875, 1046, 1214],
        valueHeight: 62,
        valueFontSize: 30,
        notesLeft: 620,
        notesTop: 1380,
        notesWidth: 250,
        notesFontSize: 21,
        phoneLeft: 104,
        phoneTop: 130,
        phoneWidth: 165,
        phoneFontSize: 24,
      );
    }

    return _PosterTemplateLayout(
      asset: market == 'saudi'
          ? 'assets/template/new_SA_insta.jpeg'
          : 'assets/template/new_JOD_insta.jpeg',
      exportPrefix: market == 'saudi' ? 'saudi_meta' : 'jordan_meta',
      width: 1080,
      height: 1350,
      imagesLeft: 42,
      imagesTop: 318,
      imageWidth: 520,
      imageHeight: 255,
      imageGap: 14,
      valueLeft: 688,
      valueWidth: 242,
      valueTops: const [300, 440, 576, 710, 843, 970],
      valueHeight: 52,
      valueFontSize: 30,
      notesLeft: 784,
      notesTop: 1188,
      notesWidth: 258,
      notesFontSize: 22,
      phoneLeft: 140,
      phoneTop: 1172,
      phoneWidth: 220,
      phoneFontSize: 24,
    );
  }

  List<_PosterElement> _defaultElements(_PosterTemplateLayout layout) {
    return [
      for (var index = 0; index < 3; index++)
        _PosterElement(
          id: 'image${index + 1}',
          label: 'Image ${index + 1}',
          kind: _PosterElementKind.image,
          left: layout.imagesLeft,
          top: layout.imagesTop + (layout.imageHeight + layout.imageGap) * index,
          width: layout.imageWidth,
          height: layout.imageHeight,
          fontSize: 0,
          fontWeightValue: 400,
          fontFamily: 'Monda',
          textAlign: TextAlign.center,
          rtl: false,
          colorHex: '#FF000000',
        ),
      _PosterElement(
        id: 'type',
        label: 'Type',
        kind: _PosterElementKind.text,
        left: layout.valueLeft,
        top: layout.valueTops[0],
        width: layout.valueWidth,
        height: layout.valueHeight,
        fontSize: layout.valueFontSize,
        fontWeightValue: 600,
        fontFamily: 'Monda',
        textAlign: TextAlign.center,
        rtl: false,
        colorHex: '#FF000000',
      ),
      _PosterElement(
        id: 'model',
        label: 'Model',
        kind: _PosterElementKind.text,
        left: layout.valueLeft,
        top: layout.valueTops[1],
        width: layout.valueWidth,
        height: layout.valueHeight,
        fontSize: layout.valueFontSize,
        fontWeightValue: 600,
        fontFamily: 'Monda',
        textAlign: TextAlign.center,
        rtl: false,
        colorHex: '#FF000000',
      ),
      _PosterElement(
        id: 'price',
        label: 'Price',
        kind: _PosterElementKind.text,
        left: layout.valueLeft,
        top: layout.valueTops[2],
        width: layout.valueWidth,
        height: layout.valueHeight,
        fontSize: layout.valueFontSize,
        fontWeightValue: 700,
        fontFamily: 'Monda',
        textAlign: TextAlign.center,
        rtl: false,
        colorHex: '#FFFF0000',
      ),
      _PosterElement(
        id: 'distance_traveled',
        label: 'Distance',
        kind: _PosterElementKind.text,
        left: layout.valueLeft,
        top: layout.valueTops[3],
        width: layout.valueWidth,
        height: layout.valueHeight,
        fontSize: layout.valueFontSize,
        fontWeightValue: 600,
        fontFamily: 'Monda',
        textAlign: TextAlign.center,
        rtl: false,
        colorHex: '#FF000000',
      ),
      _PosterElement(
        id: 'engine_size',
        label: 'Engine',
        kind: _PosterElementKind.text,
        left: layout.valueLeft,
        top: layout.valueTops[4],
        width: layout.valueWidth,
        height: layout.valueHeight,
        fontSize: layout.valueFontSize,
        fontWeightValue: 600,
        fontFamily: 'Monda',
        textAlign: TextAlign.center,
        rtl: false,
        colorHex: '#FF000000',
      ),
      _PosterElement(
        id: 'location',
        label: 'Location',
        kind: _PosterElementKind.text,
        left: layout.valueLeft,
        top: layout.valueTops[5],
        width: layout.valueWidth,
        height: layout.valueHeight,
        fontSize: layout.valueFontSize,
        fontWeightValue: 600,
        fontFamily: 'Monda',
        textAlign: TextAlign.center,
        rtl: false,
        colorHex: '#FF000000',
      ),
      _PosterElement(
        id: 'notes',
        label: 'Notes',
        kind: _PosterElementKind.text,
        left: layout.notesLeft,
        top: layout.notesTop,
        width: layout.notesWidth,
        height: 140,
        fontSize: layout.notesFontSize,
        fontWeightValue: 600,
        fontFamily: 'GE_SS',
        textAlign: TextAlign.right,
        rtl: true,
        colorHex: '#FF000000',
      ),
      _PosterElement(
        id: 'phone_number',
        label: 'Phone',
        kind: _PosterElementKind.text,
        left: layout.phoneLeft,
        top: layout.phoneTop,
        width: layout.phoneWidth,
        height: 48,
        fontSize: layout.phoneFontSize,
        fontWeightValue: 900,
        fontFamily: 'Monda',
        textAlign: TextAlign.left,
        rtl: false,
        colorHex: '#FF111111',
      ),
    ];
  }

  void _markEditorDirty() {
    _hasUnsavedEditorChanges = true;
  }

  void _updateElement(
    String elementId,
    void Function(_PosterElement element) update,
  ) {
    final element = _activeEditorLayout.elements[elementId];
    if (element == null) {
      return;
    }

    setState(() {
      update(element);
      _clampElement(element, _templateLayout);
      _markEditorDirty();
    });
  }

  void _clampElement(_PosterElement element, _PosterTemplateLayout layout) {
    final minWidth = element.kind == _PosterElementKind.image ? 80.0 : 60.0;
    final minHeight = element.kind == _PosterElementKind.image ? 80.0 : 32.0;

    element.width = element.width.clamp(minWidth, layout.width);
    element.height = element.height.clamp(minHeight, layout.height);
    element.left = element.left.clamp(0.0, layout.width - element.width);
    element.top = element.top.clamp(0.0, layout.height - element.height);
  }

  String _displayValue(String elementId) {
    switch (elementId) {
      case 'type':
        return widget.poster['type']?.toString() ?? '';
      case 'model':
        return widget.poster['model']?.toString() ?? '';
      case 'price':
        if (widget.poster['price'] == null) {
          return '';
        }
        return _market == 'saudi'
            ? 'SAR ${_formatValue(widget.poster['price'])}'
            : '${_formatValue(widget.poster['price'])} JOD';
      case 'distance_traveled':
        return _formatValue(widget.poster['distance_traveled']);
      case 'engine_size':
        return widget.poster['engine_size']?.toString() ?? '';
      case 'location':
        return widget.poster['location']?.toString() ?? '';
      case 'notes':
        final notes = (widget.poster['notes'] as List?)?.cast<String>() ?? <String>[];
        return notes.join('\n');
      case 'phone_number':
        return widget.poster['phone_number']?.toString() ?? '';
      default:
        return '';
    }
  }

  String _rawFieldValue(String elementId) {
    switch (elementId) {
      case 'notes':
        final notes = (widget.poster['notes'] as List?)?.cast<String>() ?? <String>[];
        return notes.join('\n');
      case 'price':
      case 'distance_traveled':
        final value = widget.poster[elementId];
        return value?.toString() ?? '';
      default:
        return widget.poster[elementId]?.toString() ?? '';
    }
  }

  String _labelForElementId(String elementId) {
    return _activeEditorLayout.elements[elementId]?.label ?? elementId;
  }

  bool _canEditContent(_PosterElement element) {
    return element.kind == _PosterElementKind.text;
  }

  int _imageIndexFromElementId(String id) {
    return int.parse(id.replaceFirst('image', '')) - 1;
  }

  Alignment _alignmentForTextAlign(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left:
        return Alignment.centerLeft;
      case TextAlign.right:
        return Alignment.centerRight;
      case TextAlign.center:
      default:
        return Alignment.center;
    }
  }

  Color _colorFromHex(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final buffer = StringBuffer();
    if (normalized.length == 6) {
      buffer.write('FF');
    }
    buffer.write(normalized);
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final layout = _templateLayout;
    final editorLayout = _activeEditorLayout;
    final selectedElement = _selectedElementId == null
        ? null
        : editorLayout.elements[_selectedElementId!];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _hasUnsavedEditorChanges ? 'Poster Editor *' : 'Poster Editor',
        ),
        actions: [
          IconButton(
            tooltip: 'Editor help',
            onPressed: _showLayoutHelp,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: 'Save editor changes',
            onPressed: (_saving || !_hasUnsavedEditorChanges) ? null : _saveEditorState,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
          CustomIconBtn(
            text: 'JO',
            color: Colors.blue,
            toolTip: 'Jordan Meta layout',
            onPressed: _applyJordanMeta,
          ),
          CustomIconBtn(
            text: 'JO',
            color: Colors.amber,
            toolTip: 'Jordan Snap layout',
            onPressed: _applyJordanSnap,
          ),
          const SizedBox(width: 10),
          CustomIconBtn(
            text: 'SA',
            color: Colors.blue,
            toolTip: 'Saudi Meta layout',
            onPressed: _applySaudiMeta,
          ),
          CustomIconBtn(
            text: 'SA',
            color: Colors.amber,
            toolTip: 'Saudi Snap layout',
            onPressed: _applySaudiSnap,
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Export poster',
            onPressed: _exporting ? null : _exportAsImage,
            icon: _exporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedElementId = null),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _exportKey,
                      child: SizedBox(
                        width: layout.width,
                        height: layout.height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Image.asset(layout.asset, fit: BoxFit.cover),
                            ),
                            ...editorLayout.elements.values.map(
                              (element) => _buildEditableElement(
                                element,
                                selected: _showEditorChrome &&
                                    _selectedElementId == element.id,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildEditorPanel(selectedElement, layout),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableElement(
    _PosterElement element,
    {
    required bool selected,
  }) {
    return Positioned(
      left: element.left,
      top: element.top,
      width: element.width,
      height: element.height,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedElementId = element.id);
        },
        onDoubleTap: () {
          if (element.kind == _PosterElementKind.image) {
            _editImage(_imageIndexFromElementId(element.id));
          } else {
            _updatePosterTextField(element.id);
          }
        },
        onPanUpdate: (details) {
          _updateElement(element.id, (item) {
            item.left += details.delta.dx;
            item.top += details.delta.dy;
          });
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.move,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected ? Colors.orange : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildElementContent(element),
                ),
              ),
              if (selected)
                Positioned(
                  left: 6,
                  top: 6,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          element.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (selected)
                Positioned(
                  right: -10,
                  bottom: -10,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      _updateElement(element.id, (item) {
                        item.width += details.delta.dx;
                        item.height += details.delta.dy;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.open_in_full,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElementContent(_PosterElement element) {
    if (element.kind == _PosterElementKind.image) {
      final imagePath = widget.poster[element.id]?.toString();
      final hasImage =
          imagePath != null && imagePath.isNotEmpty && File(imagePath).existsSync();

      if (!hasImage) {
        return _brokenImageCard();
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
        ),
      );
    }

    final text = _displayValue(element.id);
    final style = TextStyle(
      fontSize: element.fontSize,
      color: _colorFromHex(element.colorHex),
      fontFamily: element.fontFamily,
      fontWeight: _fontWeightFromValue(element.fontWeightValue),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      alignment: _alignmentForTextAlign(element.textAlign),
      child: Directionality(
        textDirection: element.rtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Text(
          text,
          textAlign: element.textAlign,
          maxLines: element.id == 'notes' ? 5 : 2,
          overflow: TextOverflow.visible,
          style: style,
        ),
      ),
    );
  }

  Widget _brokenImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('Double tap to replace'),
        ],
      ),
    );
  }

  Widget _buildEditorPanel(
    _PosterElement? selectedElement,
    _PosterTemplateLayout layout,
  ) {
    if (selectedElement == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Select an element to edit it. Drag to move, use the corner handle to resize, then save your changes.',
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedElement.label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: selectedElement.kind == _PosterElementKind.image
                      ? () => _editImage(_imageIndexFromElementId(selectedElement.id))
                      : () => _updatePosterTextField(selectedElement.id),
                  icon: Icon(
                    selectedElement.kind == _PosterElementKind.image
                        ? Icons.image_outlined
                        : Icons.edit_outlined,
                  ),
                  label: Text(
                    selectedElement.kind == _PosterElementKind.image
                        ? 'Replace image'
                        : 'Edit text',
                  ),
                ),
                if (_canEditContent(selectedElement))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _displayValue(selectedElement.id),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
              ],
            ),
          ),
          _numberSlider(
            label: 'X',
            value: selectedElement.left,
            min: 0,
            max: layout.width - selectedElement.width,
            onChanged: (value) =>
                _updateElement(selectedElement.id, (item) => item.left = value),
          ),
          _numberSlider(
            label: 'Y',
            value: selectedElement.top,
            min: 0,
            max: layout.height - selectedElement.height,
            onChanged: (value) =>
                _updateElement(selectedElement.id, (item) => item.top = value),
          ),
          _numberSlider(
            label: 'Width',
            value: selectedElement.width,
            min: selectedElement.kind == _PosterElementKind.image ? 80 : 60,
            max: layout.width,
            onChanged: (value) =>
                _updateElement(selectedElement.id, (item) => item.width = value),
          ),
          _numberSlider(
            label: 'Height',
            value: selectedElement.height,
            min: selectedElement.kind == _PosterElementKind.image ? 80 : 32,
            max: layout.height,
            onChanged: (value) =>
                _updateElement(selectedElement.id, (item) => item.height = value),
          ),
          if (selectedElement.kind == _PosterElementKind.text)
            _numberSlider(
              label: 'Font size',
              value: selectedElement.fontSize,
              min: 10,
              max: 80,
              onChanged: (value) => _updateElement(
                selectedElement.id,
                (item) => item.fontSize = value,
              ),
            ),
          if (selectedElement.kind == _PosterElementKind.text)
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<int>(
                value: selectedElement.fontWeightValue,
                decoration: const InputDecoration(labelText: 'Font weight'),
                items: const [
                  DropdownMenuItem(value: 400, child: Text('400')),
                  DropdownMenuItem(value: 500, child: Text('500')),
                  DropdownMenuItem(value: 600, child: Text('600')),
                  DropdownMenuItem(value: 700, child: Text('700')),
                  DropdownMenuItem(value: 800, child: Text('800')),
                  DropdownMenuItem(value: 900, child: Text('900')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _updateElement(
                    selectedElement.id,
                    (item) => item.fontWeightValue = value,
                  );
                },
              ),
            ),
          if (selectedElement.kind == _PosterElementKind.text)
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: selectedElement.fontFamily,
                decoration: const InputDecoration(labelText: 'Font family'),
                items: const [
                  DropdownMenuItem(value: 'Monda', child: Text('Monda')),
                  DropdownMenuItem(value: 'GE_SS', child: Text('GE_SS')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _updateElement(
                    selectedElement.id,
                    (item) => item.fontFamily = value,
                  );
                },
              ),
            ),
          if (selectedElement.kind == _PosterElementKind.text)
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<TextAlign>(
                value: selectedElement.textAlign,
                decoration: const InputDecoration(labelText: 'Text align'),
                items: const [
                  DropdownMenuItem(
                    value: TextAlign.left,
                    child: Text('Left'),
                  ),
                  DropdownMenuItem(
                    value: TextAlign.center,
                    child: Text('Center'),
                  ),
                  DropdownMenuItem(
                    value: TextAlign.right,
                    child: Text('Right'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  _updateElement(
                    selectedElement.id,
                    (item) => item.textAlign = value,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _numberSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final safeMax = max < min ? min : max;
    final safeValue = value.clamp(min, safeMax);

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${safeValue.toStringAsFixed(0)}'),
          Slider(
            value: safeValue,
            min: min,
            max: safeMax == min ? min + 1 : safeMax,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  FontWeight _fontWeightFromValue(int value) {
    switch (value) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w400;
    }
  }
}

enum _PosterElementKind { image, text }

class _PosterEditorLayout {
  _PosterEditorLayout(this.elements);

  final Map<String, _PosterElement> elements;

  Map<String, dynamic> toJson() {
    return {
      for (final entry in elements.entries) entry.key: entry.value.toJson(),
    };
  }
}

class _PosterElement {
  _PosterElement({
    required this.id,
    required this.label,
    required this.kind,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.fontWeightValue,
    required this.fontFamily,
    required this.textAlign,
    required this.rtl,
    required this.colorHex,
  });

  final String id;
  final String label;
  final _PosterElementKind kind;
  double left;
  double top;
  double width;
  double height;
  double fontSize;
  int fontWeightValue;
  String fontFamily;
  TextAlign textAlign;
  bool rtl;
  String colorHex;

  _PosterElement merge(Map<String, dynamic> json) {
    return _PosterElement(
      id: id,
      label: label,
      kind: kind,
      left: (json['left'] as num?)?.toDouble() ?? left,
      top: (json['top'] as num?)?.toDouble() ?? top,
      width: (json['width'] as num?)?.toDouble() ?? width,
      height: (json['height'] as num?)?.toDouble() ?? height,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? fontSize,
      fontWeightValue: (json['fontWeightValue'] as num?)?.toInt() ?? fontWeightValue,
      fontFamily: json['fontFamily']?.toString() ?? fontFamily,
      textAlign: _textAlignFromStored(json['textAlign']?.toString()),
      rtl: json['rtl'] as bool? ?? rtl,
      colorHex: json['colorHex']?.toString() ?? colorHex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'fontSize': fontSize,
      'fontWeightValue': fontWeightValue,
      'fontFamily': fontFamily,
      'textAlign': _textAlignToStored(textAlign),
      'rtl': rtl,
      'colorHex': colorHex,
    };
  }

  static TextAlign _textAlignFromStored(String? raw) {
    switch (raw) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      case 'center':
      default:
        return TextAlign.center;
    }
  }

  static String _textAlignToStored(TextAlign value) {
    switch (value) {
      case TextAlign.left:
        return 'left';
      case TextAlign.right:
        return 'right';
      case TextAlign.center:
      default:
        return 'center';
    }
  }
}

class _PosterTemplateLayout {
  const _PosterTemplateLayout({
    required this.asset,
    required this.exportPrefix,
    required this.width,
    required this.height,
    required this.imagesLeft,
    required this.imagesTop,
    required this.imageWidth,
    required this.imageHeight,
    required this.imageGap,
    required this.valueLeft,
    required this.valueWidth,
    required this.valueTops,
    required this.valueHeight,
    required this.valueFontSize,
    required this.notesLeft,
    required this.notesTop,
    required this.notesWidth,
    required this.notesFontSize,
    required this.phoneLeft,
    required this.phoneTop,
    required this.phoneWidth,
    required this.phoneFontSize,
  });

  final String asset;
  final String exportPrefix;
  final double width;
  final double height;
  final double imagesLeft;
  final double imagesTop;
  final double imageWidth;
  final double imageHeight;
  final double imageGap;
  final double valueLeft;
  final double valueWidth;
  final List<double> valueTops;
  final double valueHeight;
  final double valueFontSize;
  final double notesLeft;
  final double notesTop;
  final double notesWidth;
  final double notesFontSize;
  final double phoneLeft;
  final double phoneTop;
  final double phoneWidth;
  final double phoneFontSize;
}
