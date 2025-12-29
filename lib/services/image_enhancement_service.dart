import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service for enhancing document images before OCR processing.
/// Applies contrast and sharpening to improve text recognition accuracy.
class ImageEnhancementService {
  /// Sharpening convolution kernel
  /// This kernel enhances edges and makes text more crisp
  static const List<int> _sharpenKernel = [
    0, -1, 0,
    -1, 5, -1,
    0, -1, 0,
  ];

  /// Enhance a document image for better OCR results.
  ///
  /// Applies:
  /// - Contrast enhancement (makes text stand out from background)
  /// - Sharpening filter (makes text edges crisp)
  ///
  /// Returns a new enhanced image file.
  static Future<File> enhanceDocument(File inputFile) async {
    try {
      // Read the input file
      final Uint8List bytes = await inputFile.readAsBytes();

      // Decode the image (runs in isolate for performance)
      img.Image? image = await compute(_decodeImage, bytes);

      if (image == null) {
        debugPrint('ImageEnhancementService: Failed to decode image');
        return inputFile; // Return original if decoding fails
      }

      // Apply enhancements (runs in isolate for performance)
      final enhancedImage = await compute(_applyEnhancements, image);

      // Encode the enhanced image
      final Uint8List outputBytes = await compute(_encodeImage, enhancedImage);

      // Save to a new file
      final String outputPath = _generateOutputPath(inputFile.path);
      final File outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      debugPrint('ImageEnhancementService: Enhanced image saved to $outputPath');
      return outputFile;
    } catch (e, st) {
      debugPrint('ImageEnhancementService: Enhancement failed: $e');
      debugPrint(st.toString());
      // Return original file if enhancement fails
      return inputFile;
    }
  }

  /// Decode image bytes to Image object (runs in isolate)
  static img.Image? _decodeImage(Uint8List bytes) {
    return img.decodeImage(bytes);
  }

  /// Apply all enhancements to the image (runs in isolate)
  static img.Image _applyEnhancements(img.Image image) {
    // Step 1: Apply contrast enhancement
    // Value > 100 increases contrast, making text stand out more
    img.Image enhanced = img.contrast(image, contrast: 130);

    // Step 2: Apply sharpening convolution
    // This makes text edges more defined and crisp
    enhanced = img.convolution(
      enhanced,
      filter: _sharpenKernel,
      div: 1,
      offset: 0,
    );

    return enhanced;
  }

  /// Encode image to JPEG bytes (runs in isolate)
  static Uint8List _encodeImage(img.Image image) {
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  /// Generate output path for enhanced image
  static String _generateOutputPath(String inputPath) {
    final lastDot = inputPath.lastIndexOf('.');
    if (lastDot == -1) {
      return '${inputPath}_enhanced.jpg';
    }
    final basePath = inputPath.substring(0, lastDot);
    return '${basePath}_enhanced.jpg';
  }

  /// Clean up temporary enhanced images
  static Future<void> cleanupEnhancedImage(File? enhancedFile) async {
    if (enhancedFile != null && enhancedFile.path.contains('_enhanced')) {
      try {
        if (await enhancedFile.exists()) {
          await enhancedFile.delete();
          debugPrint('ImageEnhancementService: Cleaned up ${enhancedFile.path}');
        }
      } catch (e) {
        debugPrint('ImageEnhancementService: Cleanup failed: $e');
      }
    }
  }
}
