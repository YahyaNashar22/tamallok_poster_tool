import 'package:flutter/material.dart';

class CustomIconBtn extends StatelessWidget {
  final String text;
  final Color color;
  final String toolTip;
  final VoidCallback onPressed;
  const CustomIconBtn({
    super.key,
    required this.text,
    required this.color,
    required this.toolTip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: toolTip,
      icon: CircleAvatar(
        radius: 12,
        backgroundColor: color,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
