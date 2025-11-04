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

  Future<void> _exportAsImage() async {
    try {
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
        '${exportDir.path}/poster_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Exported to: ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Failed to export: $e')));
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
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAsImage,
            tooltip: "Save as Instagram Image",
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
                  image: AssetImage('assets/stone_texture_background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              width: 900,
              height: 1600,
              padding: const EdgeInsets.only(left: 32, top: 48, bottom: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Header
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "سيارة كوم",
                        style: GoogleFonts.amiri(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "SAYARA COM",
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "وَأَنْ تَصَدَّقُوا خَيْرٌ لَكُمْ إِنْ كُنْتُمْ تَعْلَمُونَ",
                        style: GoogleFonts.amiri(
                          fontSize: 48,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
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
                                      width: 424,
                                      height: 292,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 424,
                                              height: 292,
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
                        height: 890,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _info(
                              "النوع",
                              poster['type'],
                              FaIcon(FontAwesomeIcons.car, size: 32),
                            ),
                            _info(
                              "الموديل",
                              poster['model'],
                              FaIcon(FontAwesomeIcons.carOn, size: 32),
                            ),
                            _info(
                              "السعر",
                              "${_formatValue(poster['price'])} SAR",
                              FaIcon(FontAwesomeIcons.moneyBill1Wave, size: 32),
                              color: Colors.red,
                            ),
                            _info(
                              "المسافة\n المقطوعة",
                              "${_formatValue(poster['distance_traveled'])} كم",
                              FaIcon(FontAwesomeIcons.road, size: 32),
                            ),
                            _info(
                              "حجم المحرك",
                              poster['engine_size'],
                              FaIcon(FontAwesomeIcons.expand, size: 32),
                            ),
                            _info(
                              "الموقع",
                              poster['location'],
                              FaIcon(FontAwesomeIcons.locationDot, size: 32),
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
                      PosterNotes(notes: notes),
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
    FaIcon icon, {
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
      padding: const EdgeInsets.only(left: 24, right: 48, top: 16, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          icon,
          Text(
            "$value ",
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 32, color: color),
          ),
          Text(
            " :$label",
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
