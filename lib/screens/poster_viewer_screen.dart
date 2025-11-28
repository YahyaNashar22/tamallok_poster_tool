import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  double _posterWidth = 1080;
  double _posterHeight = 1080;
  double _posterPaddingTop = 4;
  double _logoHeight = 100;
  double _logoAyaSizedBoxHeight = 12;
  double _ayaWidth = 350;
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

  Future<void> _exportAsImage(String platform) async {
    if (_exporting) return;
    setState(() => _exporting = true);

    try {
      // fix styles: make `meta` a square 1:1 and `snap` a long 9:16
      if (platform == 'snap') {
        setState(() {
          // Snap layout: vertical 9:16 (typical story/snap size)
          _posterWidth = 1080;
          _posterHeight = 1920;
          _posterPaddingTop = 48;
          _logoHeight = 124;
          _logoAyaSizedBoxHeight = 32;
          _ayaWidth = 400;
          _ayaSizedBoxHeight = 48;
          _carImgWidth = 600;
          _carImgHeight = 304;
          _carInfoHeight = 948;
          _carInfoPaddingY = 16;
          _carInfoTextSize = 32;
          _carInfoIconSize = 24;
          notesTextSize = 32;
        });
      } else if (platform == 'meta') {
        setState(() {
          // Meta layout: square 1:1 (e.g. Instagram/Facebook square post)
          _posterWidth = 1080;
          _posterHeight = 1080;
          _posterPaddingTop = 4;
          _logoHeight = 100;
          _logoAyaSizedBoxHeight = 12;
          _ayaWidth = 350;
          _ayaSizedBoxHeight = 12;
          _carImgWidth = 540;
          _carImgHeight = 182;
          _carInfoHeight = 576;
          _carInfoPaddingY = 8;
          _carInfoTextSize = 24;
          _carInfoIconSize = 22;
          notesTextSize = 24;
        });
      }
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
        '${exportDir.path}/${platform}_poster_${DateTime.now().millisecondsSinceEpoch}.png',
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
                      icon: const Icon(Icons.facebook),
                      onPressed: () => _exportAsImage('meta'),
                      tooltip: "Save as Meta Image",
                    ),
                    IconButton(
                      icon: const Icon(Icons.snapchat),
                      onPressed: () => _exportAsImage('snap'),
                      tooltip: "Save as Snap Image",
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
                      Image.asset('assets/green_logo.png', height: _logoHeight),
                      SizedBox(height: _logoAyaSizedBoxHeight),
                      // Text(
                      //   "وَأَنْ تَصَدَّقُوا خَيْرٌ لَكُمْ إِنْ كُنْتُمْ تَعْلَمُونَ",
                      //   style: GoogleFonts.amiri(
                      //     fontSize: 48,
                      //     color: Colors.black87,
                      //   ),
                      //   textAlign: TextAlign.center,
                      // ),
                      Image.asset("assets/aya.png", width: _ayaWidth),
                      SizedBox(height: _ayaSizedBoxHeight),
                    ],
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Images
                      if (images.isNotEmpty)
                        Column(
                          children: images
                              .map(
                                (e) => Column(
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
                              "المسافة\n المقطوعة",
                              "${_formatValue(poster['distance_traveled'])} كم",
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: _carInfoTextSize, color: color),
                  ),
                ),

                Text(
                  " :$label",
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: _carInfoIconSize,
                    color: color,
                    fontWeight: FontWeight.w900,
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
