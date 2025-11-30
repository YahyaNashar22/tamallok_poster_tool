import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:poster_tool/widgets/custom_icon_btn.dart';
import 'package:poster_tool/widgets/poster_footer.dart';
import 'package:poster_tool/widgets/poster_notes.dart';
import 'package:intl/intl.dart';

class PosterViewerScreen extends StatefulWidget {
  final Map<String, dynamic> poster;

  const PosterViewerScreen({super.key, required this.poster});

  @override
  State<PosterViewerScreen> createState() => _PosterViewerScreenState();
}

class _PosterViewerScreenState extends State<PosterViewerScreen> {
  final GlobalKey _exportKey = GlobalKey();
  bool _exporting = false;

  String _selectedLogo = 'assets/green_logo.png';
  bool _logoCentered = true;
  String _platform = 'meta';

  double _posterWidth = 1080;
  double _posterHeight = 1080;
  double _posterPaddingTop = 4;
  double _logoHeight = 50;
  double _logoAyaSizedBoxHeight = 24;
  double _ayaWidth = 250;
  double _ayaSizedBoxHeight = 12;
  double _carImgWidth = 540;
  double _carImgHeight = 182;
  double _carInfoHeight = 576;
  double _carInfoPaddingY = 8;
  double _carInfoTextSize = 24;
  double _carInfoIconSize = 22;
  double notesTextSize = 24;

  String _formatValue(dynamic value) {
    if (value == null) return '';

    // if it's a string, try to parse it
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        if (parsed % 1 == 0) {
          return NumberFormat('#,###', 'en_US').format(parsed.toInt());
        }
        return NumberFormat('#,###.##', 'en_US').format(parsed);
      }
      return value; // not numeric string
    }

    // if it's numeric
    if (value is num) {
      if (value % 1 == 0) {
        return NumberFormat('#,###', 'en_US').format(value.toInt());
      }
      return NumberFormat('#,###.##', 'en_US').format(value);
    }

    return value.toString();
  }

  void _changeLogo(String logo) {
    setState(() {
      _selectedLogo = logo;
    });
  }

  void _toggleLogoAlignment() {
    setState(() {
      _logoCentered = !_logoCentered;
    });
  }

  void _jordanMeta() {
    _changePlatform('meta');
    _changeLogo("assets/green_logo2.png");
  }

  void _jordanSnap() {
    _changePlatform('snap');
    _changeLogo("assets/green_logo2.png");
  }

  void _saudiMeta() {
    _changePlatform('meta');
    _changeLogo("assets/green_logo.png");
  }

  void _saudiSnap() {
    _changePlatform('snap');
    _changeLogo("assets/green_logo.png");
  }

  void _changePlatform(String platform) {
    // fix styles: make `meta` a square 1:1 and `snap` a long 9:16

    if (platform == 'snap') {
      setState(() {
        // Snap layout: vertical 9:16 (typical story/snap size)
        _platform = 'snap';
        _posterWidth = 1080;
        _posterHeight = 1920;
        _posterPaddingTop = 0;
        _logoHeight = 75;
        _logoAyaSizedBoxHeight = 32;
        _ayaWidth = 250;
        _ayaSizedBoxHeight = 0;
        _carImgWidth = 600;
        _carImgHeight = 390;
        _carInfoHeight = 1180;
        _carInfoPaddingY = 16;
        _carInfoTextSize = 26;
        _carInfoIconSize = 24;
        notesTextSize = 28;
      });
    } else if (platform == 'meta') {
      setState(() {
        // Meta layout: square 1:1 (e.g. Instagram/Facebook square post)
        _platform = 'meta';
        _posterWidth = 1080;
        _posterHeight = 1080;
        _posterPaddingTop = 4;
        _logoHeight = 50;
        _logoAyaSizedBoxHeight = 24;
        _ayaWidth = 250;
        _ayaSizedBoxHeight = 12;
        _carImgWidth = 300;
        _carImgHeight = 200;
        _carInfoHeight = 600;
        _carInfoPaddingY = 8;
        _carInfoTextSize = 24;
        _carInfoIconSize = 22;
        notesTextSize = 24;
      });
    }
  }

  Future<void> _exportAsImage() async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      // Wait for the UI to rebuild with the new size
      await Future.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      RenderRepaintBoundary boundary =
          _exportKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/poster_tool');
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
      }

      final file = File(
        '${exportDir.path}/${_platform}_poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Exported to: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to export: $e')));
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.poster;

    final List<String> images = [
      poster['image1'],
      poster['image2'],
      poster['image3'],
    ].where((e) => e != null && e.isNotEmpty).cast<String>().toList();

    final notes = (poster['notes'] is String)
        ? List<String>.from(jsonDecode(poster['notes']))
        : (poster['notes'] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Poster Viewer"),
        actions: [
          _exporting
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _logoCentered
                            ? Icons.align_horizontal_center
                            : Icons.align_horizontal_left,
                      ),
                      onPressed: () => _toggleLogoAlignment(),
                      tooltip: "Logo Alignment",
                    ),
                    const SizedBox(width: 24),
                    CustomIconBtn(
                      text: 'JO',
                      color: Colors.blue,
                      toolTip: "Jordan Meta",
                      onPressed: _jordanMeta,
                    ),
                    CustomIconBtn(
                      text: 'JO',
                      color: Colors.amber,
                      toolTip: "Jordan Snap",
                      onPressed: _jordanSnap,
                    ),
                    const SizedBox(width: 24),
                    CustomIconBtn(
                      text: 'SA',
                      color: Colors.blue,
                      toolTip: "Saudi Meta",
                      onPressed: _saudiMeta,
                    ),
                    CustomIconBtn(
                      text: 'SA',
                      color: Colors.amber,
                      toolTip: "Saudi Snap",
                      onPressed: _saudiSnap,
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: _exportAsImage,
                      tooltip: "Generate Image",
                    ),
                  ],
                ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: RepaintBoundary(
            key: _exportKey,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/poster_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              width: _posterWidth,
              height: _posterHeight,
              padding: EdgeInsets.only(
                left: 32,
                top: _posterPaddingTop,
                bottom: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Header
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: _logoCentered
                            ? Alignment.center
                            : Alignment.centerLeft,
                        child: Image.asset(_selectedLogo, height: _logoHeight),
                      ),
                      SizedBox(height: _logoAyaSizedBoxHeight),
                      Image.asset("assets/aya.png", width: _ayaWidth),
                      SizedBox(height: _ayaSizedBoxHeight),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Images
                      if (images.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: images
                              .map(
                                (e) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,

                                  children: [
                                    Image.file(
                                      File(e),
                                      width: _carImgWidth,
                                      height: _carImgHeight,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: _carImgWidth,
                                              height: _carImgHeight,
                                              color: Colors.grey.shade300,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              )
                              .toList(),
                        ),

                      // Details
                      SizedBox(
                        height: _carInfoHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _info(
                              "النوع",
                              poster['type'],
                              Image.asset(
                                "assets/car.png",
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            _info(
                              "الموديل",
                              poster['model'],
                              Image.asset(
                                "assets/cars.png",
                                width: 48,
                                height: 48,
                                fit: BoxFit.contain,
                              ),
                            ),
                            _info(
                              "السعر",
                              "${_formatValue(poster['price'])} SAR",
                              Image.asset(
                                "assets/price.png",
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                              color: Colors.red,
                            ),
                            _info(
                              "المسافة المقطوعة",
                              "${_formatValue(poster['distance_traveled'])} ",
                              Image.asset(
                                "assets/speed.png",
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            _info(
                              "حجم المحرك",
                              poster['engine_size'],
                              Image.asset(
                                "assets/maximize.png",
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            _info(
                              "الموقع",
                              poster['location'],
                              Image.asset(
                                "assets/location.png",
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

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PosterFooter(poster: poster),
                      PosterNotes(notes: notes, notesTextSize: notesTextSize),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(
    String label,
    String? value,
    Widget icon, {
    Color color = Colors.black87,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      width: 420,
      padding: EdgeInsets.only(
        left: 24,
        right: 48,
        top: _carInfoPaddingY,
        bottom: _carInfoPaddingY,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icon,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    "$value ",
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: _carInfoTextSize,
                      color: color,
                      fontFamily: 'Monda',
                    ),
                  ),
                ),

                Text(
                  " : $label",
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontSize: _carInfoIconSize,
                    fontFamily: 'Monda',
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
