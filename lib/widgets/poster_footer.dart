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
    final phone = poster['phone_number']?.toString() ?? '';
    final webId = poster['web_id']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/phone.png',
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 6),
            Text(
              phone,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedLogo == 'assets/sayaracom.png')
          const Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'سيارة كوم بالتعاون\nمع بيت التملك',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black,
                fontFamily: 'GE_SS_Medium',
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        if (selectedLogo == 'assets/sayaracom.png') const SizedBox(height: 12),
        Text(
          '#$webId',
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: fontSize),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
