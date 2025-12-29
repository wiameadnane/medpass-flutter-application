import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Service to extract text from PDF files using OCR
class PdfExtractionService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from a PDF file
  /// Returns a map with 'text' and 'pageCount'
  Future<PdfExtractionResult> extractTextFromPdf(String pdfPath) async {
    PdfDocument? document;
    final List<String> pageTexts = [];

    try {
      debugPrint('Opening PDF: $pdfPath');

      // Open the PDF document
      document = await PdfDocument.openFile(pdfPath);
      final pageCount = document.pagesCount;
      debugPrint('PDF has $pageCount pages');

      // Extract text from each page
      for (int i = 1; i <= pageCount; i++) {
        debugPrint('Processing page $i of $pageCount...');

        final page = await document.getPage(i);

        try {
          // Render page to image at 2x resolution for better OCR
          final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.png,
          );

          if (pageImage == null) {
            debugPrint('Failed to render page $i');
            pageTexts.add('[Page $i: Failed to render]');
            continue;
          }

          // Save image to temp file for OCR
          final tempDir = await getTemporaryDirectory();
          final tempImagePath = '${tempDir.path}/pdf_page_$i.png';
          final tempFile = File(tempImagePath);
          await tempFile.writeAsBytes(pageImage.bytes);

          // Run OCR on the page image
          final inputImage = InputImage.fromFilePath(tempImagePath);
          final recognizedText = await _textRecognizer.processImage(inputImage);

          final pageText = recognizedText.text.trim();
          if (pageText.isNotEmpty) {
            pageTexts.add(pageText);
            debugPrint('Page $i: extracted ${pageText.length} characters');
          } else {
            debugPrint('Page $i: no text found');
          }

          // Clean up temp file
          try {
            await tempFile.delete();
          } catch (_) {}

        } finally {
          await page.close();
        }
      }

      // Combine all page texts
      final combinedText = pageTexts.join('\n\n--- Page Break ---\n\n');

      return PdfExtractionResult(
        text: combinedText,
        pageCount: pageCount,
        success: combinedText.isNotEmpty,
        error: combinedText.isEmpty ? 'No text could be extracted from the PDF' : null,
      );

    } catch (e, st) {
      debugPrint('PDF extraction error: $e');
      debugPrint(st.toString());
      return PdfExtractionResult(
        text: '',
        pageCount: 0,
        success: false,
        error: 'Failed to extract text: $e',
      );
    } finally {
      await document?.close();
    }
  }

  /// Extract text from PDF bytes (for files downloaded from network)
  Future<PdfExtractionResult> extractTextFromBytes(Uint8List bytes, String fileName) async {
    try {
      // Save bytes to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);

      // Extract text
      final result = await extractTextFromPdf(tempPath);

      // Clean up
      try {
        await tempFile.delete();
      } catch (_) {}

      return result;
    } catch (e) {
      return PdfExtractionResult(
        text: '',
        pageCount: 0,
        success: false,
        error: 'Failed to process PDF: $e',
      );
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await _textRecognizer.close();
    } catch (_) {}
  }
}

/// Result of PDF text extraction
class PdfExtractionResult {
  final String text;
  final int pageCount;
  final bool success;
  final String? error;

  PdfExtractionResult({
    required this.text,
    required this.pageCount,
    required this.success,
    this.error,
  });
}
