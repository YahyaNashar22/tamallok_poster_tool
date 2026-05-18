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

  bool _exporting = false;
  String _market = 'jordan';
  String _platform = 'meta';

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
        phoneTop: 1430,
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

  void _applyJordanMeta() {
    setState(() {
      _market = 'jordan';
      _platform = 'meta';
    });
  }

  void _applyJordanSnap() {
    setState(() {
      _market = 'jordan';
      _platform = 'snap';
    });
  }

  void _applySaudiMeta() {
    setState(() {
      _market = 'saudi';
      _platform = 'meta';
    });
  }

  void _applySaudiSnap() {
    setState(() {
      _market = 'saudi';
      _platform = 'snap';
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
          title: const Text('Preview Controls'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The new poster templates are used directly as the base design.',
              ),
              SizedBox(height: 8),
              Text('Tap any image slot to replace and crop it.'),
              SizedBox(height: 8),
              Text(
                'Use JO/SA buttons to switch market branding and Meta/Snap output.',
              ),
              SizedBox(height: 8),
              Text('Export saves the final PNG exactly as previewed.'),
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

  Future<void> _exportAsImage() async {
    if (_exporting) {
      return;
    }

    setState(() => _exporting = true);

    try {
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
        setState(() => _exporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.poster;
    final imageFields = [poster['image1'], poster['image2'], poster['image3']];
    final hasAnyImage = imageFields.any(
      (image) => image != null && image.toString().isNotEmpty,
    );
    final notes = (poster['notes'] as List?)?.cast<String>() ?? <String>[];
    final layout = _templateLayout;
    final values = [
      poster['type']?.toString() ?? '',
      poster['model']?.toString() ?? '',
      poster['price'] == null
          ? ''
          : (_market == 'saudi'
                ? 'SAR ${_formatValue(poster['price'])}'
                : '${_formatValue(poster['price'])} JOD'),
      _formatValue(poster['distance_traveled']),
      poster['engine_size']?.toString() ?? '',
      poster['location']?.toString() ?? '',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poster Preview'),
        actions: [
          IconButton(
            tooltip: 'Preview help',
            onPressed: _showLayoutHelp,
            icon: const Icon(Icons.help_outline),
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
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: RepaintBoundary(
              key: _exportKey,
              child: SizedBox(
                width: layout.width,
                height: layout.height,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(layout.asset, fit: BoxFit.cover),
                    ),
                    if (hasAnyImage)
                      Positioned(
                        left: layout.imagesLeft,
                        top: layout.imagesTop,
                        child: Column(
                          children: imageFields.asMap().entries.map((entry) {
                            final imagePath = entry.value?.toString();
                            final hasImage =
                                imagePath != null &&
                                imagePath.isNotEmpty &&
                                File(imagePath).existsSync();

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: entry.key == imageFields.length - 1
                                    ? 0
                                    : layout.imageGap,
                              ),
                              child: GestureDetector(
                                onTap: () => _editImage(entry.key),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: hasImage
                                      ? Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(imagePath),
                                                width: layout.imageWidth,
                                                height: layout.imageHeight,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Container(
                                              margin: const EdgeInsets.all(8),
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ],
                                        )
                                      : _brokenImageCard(layout),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ...values.asMap().entries.map(
                      (entry) => _templateValue(
                        layout,
                        top: layout.valueTops[entry.key],
                        value: entry.value,
                        color: entry.key == 2 ? Colors.red : Colors.black,
                      ),
                    ),
                    if (notes.isNotEmpty)
                      Positioned(
                        left: layout.notesLeft,
                        top: layout.notesTop,
                        width: layout.notesWidth,
                        child: Directionality(
                          textDirection: ui.TextDirection.rtl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: notes
                                .map(
                                  (note) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      note,
                                      textAlign: TextAlign.right,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontSize: layout.notesFontSize,
                                        fontFamily: 'GE_SS',
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    Positioned(
                      left: layout.phoneLeft,
                      top: layout.phoneTop,
                      width: layout.phoneWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          poster['phone_number']?.toString() ?? '',
                          style: TextStyle(
                            fontSize: layout.phoneFontSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF111111),
                            fontFamily: 'Monda',
                          ),
                        ),
                      ),
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

  Widget _brokenImageCard(_PosterTemplateLayout layout) {
    return Container(
      width: layout.imageWidth,
      height: layout.imageHeight,
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
          Text('Tap to replace'),
        ],
      ),
    );
  }

  Widget _templateValue(
    _PosterTemplateLayout layout, {
    required double top,
    required String value,
    required Color color,
  }) {
    return Positioned(
      left: layout.valueLeft,
      top: top,
      width: layout.valueWidth,
      height: layout.valueHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                value,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: layout.valueFontSize,
                  color: color,
                  fontFamily: 'Monda',
                  fontWeight: color == Colors.red
                      ? FontWeight.bold
                      : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
