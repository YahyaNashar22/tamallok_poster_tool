import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PosterFooter extends StatelessWidget {
  const PosterFooter({super.key, required this.poster});

  final Map<String, dynamic> poster;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Icon(
                Icons.phone_in_talk_outlined,
                size: 48,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
              Text(
                poster['phone_number'] ?? '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "سيارة كوم بالتعاون\nمع بيت التملك",
            style: GoogleFonts.amiri(
              fontSize: 32,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
