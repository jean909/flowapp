import 'package:flutter/material.dart';
import 'dart:math';

class TextPostWidget extends StatelessWidget {
  final String text;
  final double height;
  final double? fontSize;
  final EdgeInsets? padding;

  const TextPostWidget({
    super.key,
    required this.text,
    this.height = 400,
    this.fontSize,
    this.padding,
  });

  Color _getRandomGradientColor() {
    final colors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Pink
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Orange
      [const Color(0xFF30cfd0), const Color(0xFF330867)], // Teal
    ];
    
    final random = Random(text.hashCode); // Consistent color per text
    return colors[random.nextInt(colors.length)][0];
  }

  Color _getSecondGradientColor() {
    final colors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
    ];
    
    final random = Random(text.hashCode);
    return colors[random.nextInt(colors.length)][1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_getRandomGradientColor(), _getSecondGradientColor()],
        ),
      ),
      child: Center(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(32),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize ?? _getFontSize(text),
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 10,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  double _getFontSize(String text) {
    if (text.length < 50) return 32;
    if (text.length < 100) return 28;
    if (text.length < 150) return 24;
    return 20;
  }
}
