import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class TextToImageService {
  static final List<Color> backgroundColors = [
    const Color(0xFF667eea), // Purple
    const Color(0xFFf093fb), // Pink
    const Color(0xFF4facfe), // Blue
    const Color(0xFF43e97b), // Green
    const Color(0xFFfa709a), // Orange
    const Color(0xFF30cfd0), // Teal
    const Color(0xFFFF6B6B), // Red
    const Color(0xFF4ECDC4), // Turquoise
  ];

  static Future<File> generateTextImage({
    required String text,
    required Color backgroundColor,
    int width = 1080,
    int height = 1080,
  }) async {
    // Create a widget to render
    final widget = Container(
      width: width.toDouble(),
      height: height.toDouble(),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            backgroundColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: _getFontSize(text),
              fontWeight: FontWeight.bold,
              height: 1.3,
              shadows: [
                Shadow(
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );

    // Convert widget to image
    final repaintBoundary = RepaintBoundary(child: widget);
    final renderRepaintBoundary = RenderRepaintBoundary();
    
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    
    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: renderRepaintBoundary,
      child: repaintBoundary,
    ).attachToRenderTree(buildOwner);
    
    buildOwner.buildScope(rootElement);
    pipelineOwner.rootNode = renderRepaintBoundary;
    renderRepaintBoundary.layout(const BoxConstraints(
      minWidth: 0,
      maxWidth: double.infinity,
      minHeight: 0,
      maxHeight: double.infinity,
    ));
    
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await renderRepaintBoundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
      throw Exception('Failed to convert image to byte data. Please try again.');
    }
    
    final buffer = byteData.buffer.asUint8List();

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/text_post_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);

    return file;
  }

  static double _getFontSize(String text) {
    if (text.length < 50) return 48;
    if (text.length < 100) return 40;
    if (text.length < 150) return 32;
    return 28;
  }
}
