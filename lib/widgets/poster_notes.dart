import 'package:flutter/material.dart';

class PosterNotes extends StatelessWidget {
  const PosterNotes({
    super.key,
    required this.notes,
    required this.notesTextSize,
  });

  final List<String> notes;
  final double notesTextSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 240,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF17652F),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'ملاحظات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: notesTextSize,
                    fontFamily: 'GE_SS_Medium',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Image.asset(
                  'assets/note.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: notes.isEmpty
                    ? [
                        Text(
                          'لا توجد ملاحظات',
                          style: TextStyle(
                            fontSize: notesTextSize - 4,
                            color: Colors.black54,
                            fontFamily: 'GE_SS',
                          ),
                        ),
                      ]
                    : notes
                        .map(
                          (note) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• $note',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: notesTextSize,
                                fontFamily: 'GE_SS',
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
