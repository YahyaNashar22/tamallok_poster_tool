import 'package:flutter/material.dart';

class PosterFooter extends StatelessWidget {
  const PosterFooter({super.key, required this.poster});

  final Map<String, dynamic> poster;

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
        Text(
          "سيارة كوم بالتعاون\nمع بيت التملك",
          style: TextStyle(
            fontSize: 28,
            color: Colors.black,
            fontFamily: 'Monda',
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.right,
        ),
        const SizedBox(height: 12),
        Text(
          "#${poster['id'].toString()}",
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }
}
