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
import 'package:poster_tool/widgets/poster_footer.dart';
import 'package:poster_tool/widgets/poster_notes.dart';

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
  String _selectedLogo = 'assets/green_logo.png';
  bool _logoCentered = false;
  String _platform = 'meta';

  double _posterWidth = 1080;
  double _posterHeight = 1350;
  double _posterPaddingTop = 28;
  double _logoWidth = 178;
  double _logoAyaSizedBoxHeight = 18;
  double _ayaWidth = 420;
  double _ayaSizedBoxHeight = 26;
  double _carImgWidth = 420;
  double _carImgHeight = 260;
  double _carInfoHeight = 660;
  double _carInfoPaddingY = 8;
  double _carInfoTextSize = 24;
  double _carInfoIconSize = 22;
  double _notesTextSize = 24;
  double _contentGap = 64;
  double _detailsBoxWidth = 420;

  void _changePlatform(String platform) {
    if (platform == 'snap') {
      setState(() {
        _platform = 'snap';
        _posterWidth = 1080;
        _posterHeight = 1920;
        _posterPaddingTop = 34;
        _logoWidth = 210;
        _logoAyaSizedBoxHeight = 32;
        _ayaWidth = 534;
        _ayaSizedBoxHeight = 36;
        _carImgWidth = 500;
        _carImgHeight = 330;
        _carInfoHeight = 1020;
        _carInfoPaddingY = 16;
        _carInfoTextSize = 26;
        _carInfoIconSize = 24;
        _notesTextSize = 28;
        _contentGap = 52;
        _detailsBoxWidth = 420;
      });
      return;
    }

    setState(() {
      _platform = 'meta';
      _posterWidth = 1080;
      _posterHeight = 1350;
      _posterPaddingTop = 28;
      _logoWidth = 178;
      _logoAyaSizedBoxHeight = 18;
      _ayaWidth = 420;
      _ayaSizedBoxHeight = 26;
      _carImgWidth = 420;
      _carImgHeight = 260;
      _carInfoHeight = 660;
      _carInfoPaddingY = 8;
      _carInfoTextSize = 24;
      _carInfoIconSize = 22;
      _notesTextSize = 24;
      _contentGap = 64;
      _detailsBoxWidth = 420;
    });
  }

  void _applyJordanMeta() {
    _changePlatform('meta');
    _changeLogo('assets/green_logo.png');
  }

  void _applyJordanSnap() {
    _changePlatform('snap');
    _changeLogo('assets/green_logo.png');
  }

  void _applySaudiMeta() {
    _changePlatform('meta');
    _changeLogo('assets/sayaracom.png');
  }

  void _applySaudiSnap() {
    _changePlatform('snap');
    _changeLogo('assets/sayaracom.png');
  }

  void _changeLogo(String logo) {
    setState(() => _selectedLogo = logo);
  }

  void _toggleLogoAlignment() {
    setState(() => _logoCentered = !_logoCentered);
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
              Text('Tap any poster image to replace and crop it.'),
              SizedBox(height: 8),
              Text('Use JO/SA buttons to switch market branding.'),
              SizedBox(height: 8),
              Text('Blue buttons create Meta layouts and amber buttons create Snap layouts.'),
              SizedBox(height: 8),
              Text('Export saves a PNG into the app documents folder.'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image updated successfully.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update image: $error')),
      );
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

      final boundary = _exportKey.currentContext?.findRenderObject()
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
          '${_platform}_poster_${widget.poster['web_id']}_${DateTime.now().millisecondsSinceEpoch}.png',
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
    final imageFields = [
      poster['image1'],
      poster['image2'],
      poster['image3'],
    ];
    final hasAnyImage = imageFields.any(
      (image) => image != null && image.toString().isNotEmpty,
    );
    final notes = (poster['notes'] as List?)?.cast<String>() ?? <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poster Preview'),
        actions: [
          IconButton(
            tooltip: 'Preview help',
            onPressed: _showLayoutHelp,
            icon: const Icon(Icons.help_outline),
          ),
          IconButton(
            tooltip: _logoCentered ? 'Align logo left' : 'Center logo',
            onPressed: _toggleLogoAlignment,
            icon: Icon(
              _logoCentered
                  ? Icons.align_horizontal_left
                  : Icons.align_horizontal_center,
            ),
          ),
          const SizedBox(width: 12),
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
        child: LayoutBuilder(
              builder: (context, _) {
                return Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _exportKey,
                      child: Container(
                    width: _posterWidth,
                    height: _posterHeight,
                    padding: EdgeInsets.only(
                      left: 32,
                      top: _posterPaddingTop,
                      right: 24,
                      bottom: 24,
                    ),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/poster_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Align(
                              alignment: _logoCentered
                                  ? Alignment.center
                                  : Alignment.centerLeft,
                              child: Image.asset(_selectedLogo, width: _logoWidth),
                            ),
                            SizedBox(height: _logoAyaSizedBoxHeight),
                            Image.asset('assets/aya.png', width: _ayaWidth),
                            SizedBox(height: _ayaSizedBoxHeight),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (hasAnyImage)
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: imageFields.asMap().entries.map((entry) {
                                  final imagePath = entry.value?.toString();
                                  final hasImage = imagePath != null &&
                                      imagePath.isNotEmpty &&
                                      File(imagePath).existsSync();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
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
                                                        BorderRadius.circular(14),
                                                    child: Image.file(
                                                      File(imagePath),
                                                      width: _carImgWidth,
                                                      height: _carImgHeight,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return _brokenImageCard();
                                                      },
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: const EdgeInsets.all(8),
                                                    padding:
                                                        const EdgeInsets.all(6),
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
                                            : _brokenImageCard(),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (hasAnyImage) SizedBox(width: _contentGap),
                            SizedBox(
                              height: _carInfoHeight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _info(
                                    'النوع',
                                    poster['type']?.toString() ?? '',
                                    Image.asset(
                                      'assets/car.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  _info(
                                    'الموديل',
                                    poster['model']?.toString() ?? '',
                                    Image.asset(
                                      'assets/cars.png',
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  _info(
                                    'السعر',
                                    poster['price'] == null
                                        ? ''
                                        : '${_formatValue(poster['price'])} SAR',
                                    Image.asset(
                                      'assets/price.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                    color: Colors.red,
                                  ),
                                  _info(
                                    'المسافة المقطوعة',
                                    _formatValue(poster['distance_traveled']),
                                    Image.asset(
                                      'assets/speed.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  _info(
                                    'حجم المحرك',
                                    poster['engine_size']?.toString() ?? '',
                                    Image.asset(
                                      'assets/maximize.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  _info(
                                    'الموقع',
                                    poster['location']?.toString() ?? '',
                                    Image.asset(
                                      'assets/location.png',
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PosterFooter(
                              poster: poster,
                              fontSize: _carInfoIconSize,
                              selectedLogo: _selectedLogo,
                            ),
                            PosterNotes(
                              notes: notes,
                              notesTextSize: _notesTextSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  Widget _brokenImageCard() {
    return Container(
      width: _carImgWidth,
      height: _carImgHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(14),
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

  Widget _info(
    String label,
    String value,
    Widget icon, {
    Color color = Colors.black87,
  }) {
    return Container(
      width: _detailsBoxWidth,
      padding: EdgeInsets.only(
        left: 24,
        right: 32,
        top: _carInfoPaddingY,
        bottom: _carInfoPaddingY,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Row(
          children: [
            SizedBox(
              width: 142,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: _carInfoIconSize,
                      fontFamily: 'GE_SS_Medium',
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: _carInfoTextSize,
                        color: color,
                        fontFamily: 'Monda',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(width: 48, child: Center(child: icon)),
          ],
        ),
      ),
    );
  }
}
