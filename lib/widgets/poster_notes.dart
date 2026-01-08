import 'package:flutter/material.dart';

class PosterNotes extends StatelessWidget {
  const PosterNotes({
    super.key,
    required this.notes,
    required this.notesTextSize,
  });

  final dynamic notes;
  final double notesTextSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 0, top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: Color(0XFF17652f),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "ملاحظات",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: notesTextSize,
                    fontFamily: 'GE_SS_Medium',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 16),
                Image.asset(
                  "assets/note.png",
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ...notes.map(
                  (note) => Text(
                    note,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 28, fontFamily: 'GE_SS'),
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
