import 'package:flutter/material.dart';

class PosterFooter extends StatelessWidget {
  const PosterFooter({
    super.key,
    required this.poster,
    required this.fontSize,
    required this.selectedLogo,
  });

  final Map<String, dynamic> poster;
  final double fontSize;
  final String selectedLogo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              "assets/phone.png",
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 6),
            Text(
              poster['phone_number'] ?? '',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedLogo == "assets/sayaracom.png")
          Text(
            "سيارة كوم بالتعاون\nمع بيت التملك",
            style: TextStyle(
              fontSize: fontSize,
              color: Colors.black,
              fontFamily: 'GE_SS_Medium',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        const SizedBox(height: 12),
        Text(
          "#${poster['web_id'].toString()}",
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
