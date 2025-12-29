import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Represents a text block with its position for layout analysis
class _PositionedBlock {
  final TextBlock block;
  final int top;
  final int left;
  final int right;
  final int bottom;
  final int centerX;

  _PositionedBlock(this.block)
      : top = block.boundingBox.top.toInt(),
        left = block.boundingBox.left.toInt(),
        right = block.boundingBox.right.toInt(),
        bottom = block.boundingBox.bottom.toInt(),
        centerX = block.boundingBox.center.dx.toInt();
}

class OCRService {
  late final TextRecognizer _textRecognizer;

  OCRService() {
    try {
      _textRecognizer = TextRecognizer();
    } catch (e) {
      debugPrint('OCRService: failed to create TextRecognizer: $e');
      rethrow;
    }
  }

  /// Extract text from image with improved layout awareness
  Future<String> scanDocument(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('Image file not found at path: $path');
      }

      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      debugPrint('OCR Result: ${recognizedText.blocks.length} blocks found');

      if (recognizedText.blocks.isEmpty) {
        return '';
      }

      // Use layout-aware extraction
      final rawText = _extractWithLayout(recognizedText);
      _logTextStructure(rawText, 'OCR Raw Extraction');

      // Clean up garbage characters and invalid words
      final cleanedText = _cleanExtractedText(rawText);
      _logTextStructure(cleanedText, 'OCR After Cleaning');

      return cleanedText;
    } catch (e, st) {
      debugPrint('OCRService.scanDocument failed: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }

  /// Characters that indicate garbage if found in a word
  static final RegExp _garbagePattern = RegExp(
    r'[\x00-\x1F\x7F-\x9F\uFFFD\uE000-\uF8FF]+',
  );

  /// Pattern for words that are just random symbols (no letters)
  static final RegExp _symbolOnlyPattern = RegExp(
    r'^[^a-zA-Z\u00C0-\u00FF]+$',
  );

  /// Clean extracted text by removing words with garbage characters
  String _cleanExtractedText(String text) {
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    for (final line in lines) {
      final cleanedLine = _cleanLine(line);
      cleanedLines.add(cleanedLine);
    }

    // Remove excessive blank lines (more than 2 in a row)
    final result = cleanedLines.join('\n');
    return result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  /// Clean a single line by filtering out garbage words
  String _cleanLine(String line) {
    if (line.trim().isEmpty) return line;

    // Split line into words by spaces, keeping track of spaces
    final words = line.split(' ');
    final cleanedWords = <String>[];

    for (final word in words) {
      if (word.isEmpty) {
        // Preserve empty strings (multiple spaces)
        cleanedWords.add(word);
        continue;
      }

      // Check if word is valid
      if (_isValidWord(word)) {
        cleanedWords.add(word);
      } else {
        debugPrint("Filtered garbage word: $word");
      }
    }

    return cleanedWords.join(' ');
  }

  /// Check if a word is valid (no garbage characters)
  bool _isValidWord(String word) {
    // Empty or whitespace-only is valid
    if (word.trim().isEmpty) return true;

    // Check for garbage characters (control chars, private use area)
    if (_garbagePattern.hasMatch(word)) {
      return false;
    }

    // Single character that's just a symbol (not a letter/number) - remove
    if (word.length == 1 && RegExp(r'[^a-zA-Z0-9]').hasMatch(word)) {
      return false;
    }

    // Word is all symbols/numbers with no letters - suspicious if long
    if (word.length > 3 && _symbolOnlyPattern.hasMatch(word)) {
      // Allow pure numbers (dates, measurements like 140/90, 12.5)
      if (!RegExp(r'^[\d.,/\-:]+$').hasMatch(word)) {
        return false;
      }
    }

    // Check for excessive repeated characters (likely garbage)
    if (_hasExcessiveRepeats(word)) {
      return false;
    }

    // Check for random character sequences (consonant clusters that are impossible)
    if (_isImpossibleSequence(word)) {
      return false;
    }

    return true;
  }

  /// Check for excessive repeated characters (e.g., "aaaaaaa")
  bool _hasExcessiveRepeats(String word) {
    if (word.length < 4) return false;

    int repeatCount = 1;
    for (int i = 1; i < word.length; i++) {
      if (word[i].toLowerCase() == word[i - 1].toLowerCase()) {
        repeatCount++;
        if (repeatCount >= 4) return true;
      } else {
        repeatCount = 1;
      }
    }
    return false;
  }

  /// Check for impossible character sequences (likely OCR errors)
  bool _isImpossibleSequence(String word) {
    if (word.length < 4) return false;

    // Count consonants in a row (more than 5 is suspicious for most languages)
    final consonants = RegExp(r'[bcdfghjklmnpqrstvwxzBCDFGHJKLMNPQRSTVWXZ]');
    int consonantStreak = 0;
    int maxConsonantStreak = 0;

    for (int i = 0; i < word.length; i++) {
      if (consonants.hasMatch(word[i])) {
        consonantStreak++;
        if (consonantStreak > maxConsonantStreak) {
          maxConsonantStreak = consonantStreak;
        }
      } else {
        consonantStreak = 0;
      }
    }

    // More than 5 consonants in a row is very unlikely
    if (maxConsonantStreak > 5) return true;

    return false;
  }

  /// Extract text preserving reading order and layout structure
  String _extractWithLayout(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return '';

    // Convert blocks to positioned blocks
    final positionedBlocks = recognizedText.blocks
        .map((block) => _PositionedBlock(block))
        .toList();

    // Detect if document has multiple columns
    final columns = _detectColumns(positionedBlocks);
    debugPrint('Detected ${columns.length} column(s)');

    final StringBuffer result = StringBuffer();

    if (columns.length > 1) {
      // Multi-column layout: process column by column, top to bottom
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final columnBlocks = columns[colIndex];
        // Sort by vertical position within column
        columnBlocks.sort((a, b) => a.top.compareTo(b.top));

        for (final posBlock in columnBlocks) {
          _appendBlockText(result, posBlock.block);
        }

        // Add extra spacing between columns
        if (colIndex < columns.length - 1) {
          result.write('\n\n---\n\n');
        }
      }
    } else {
      // Single column: sort by vertical position, then horizontal
      positionedBlocks.sort((a, b) {
        // Group blocks that are on roughly the same line (within 20px)
        final lineDiff = (a.top - b.top).abs();
        if (lineDiff < 20) {
          return a.left.compareTo(b.left);
        }
        return a.top.compareTo(b.top);
      });

      int? lastBottom;
      for (final posBlock in positionedBlocks) {
        // Add extra line break if there's a significant gap
        if (lastBottom != null) {
          final gap = posBlock.top - lastBottom;
          if (gap > 30) {
            result.write('\n'); // Paragraph break
          }
        }
        _appendBlockText(result, posBlock.block);
        lastBottom = posBlock.bottom;
      }
    }

    return result.toString().trim();
  }

  /// Detect columns in the document based on x-position clustering
  List<List<_PositionedBlock>> _detectColumns(List<_PositionedBlock> blocks) {
    if (blocks.length < 2) {
      return [blocks];
    }

    // Get document width from rightmost block
    final maxRight = blocks.map((b) => b.right).reduce(max);
    final minLeft = blocks.map((b) => b.left).reduce(min);
    final docWidth = maxRight - minLeft;

    // If document is narrow, likely single column
    if (docWidth < 400) {
      return [blocks];
    }

    // Analyze x-positions to find column boundaries
    // Sort blocks by centerX
    final sortedByX = List<_PositionedBlock>.from(blocks)
      ..sort((a, b) => a.centerX.compareTo(b.centerX));

    // Look for significant gaps in x-positions
    final List<int> gaps = [];
    for (int i = 1; i < sortedByX.length; i++) {
      final gap = sortedByX[i].left - sortedByX[i - 1].right;
      if (gap > docWidth * 0.1) {
        // Gap > 10% of doc width
        gaps.add((sortedByX[i].left + sortedByX[i - 1].right) ~/ 2);
      }
    }

    if (gaps.isEmpty) {
      return [blocks]; // No significant gaps, single column
    }

    // Split blocks into columns based on gaps
    final List<List<_PositionedBlock>> columns = [];
    gaps.insert(0, minLeft - 1);
    gaps.add(maxRight + 1);

    for (int i = 0; i < gaps.length - 1; i++) {
      final leftBound = gaps[i];
      final rightBound = gaps[i + 1];
      final columnBlocks = blocks
          .where((b) => b.centerX > leftBound && b.centerX < rightBound)
          .toList();
      if (columnBlocks.isNotEmpty) {
        columns.add(columnBlocks);
      }
    }

    // Sort columns left to right
    columns.sort(
        (a, b) => a.first.left.compareTo(b.first.left));

    return columns.isEmpty ? [blocks] : columns;
  }

  /// Append block text with proper line handling
  void _appendBlockText(StringBuffer buffer, TextBlock block) {
    for (final line in block.lines) {
      buffer.writeln(line.text);
    }
    buffer.write('\n');
  }

  /// Debug method to log extracted text structure
  void _logTextStructure(String text, String label) {
    debugPrint("=== $label ===");
    debugPrint("Total length: ${text.length}");
    final newlineCount = "\n".allMatches(text).length;
    debugPrint("Newline count: $newlineCount");

    final lines = text.split("\n");
    debugPrint("Lines: ${lines.length}");

    for (int i = 0; i < lines.length && i < 10; i++) {
      debugPrint("  Line $i: ${lines[i]}");
    }
    if (lines.length > 10) {
      debugPrint("  ... and ${lines.length - 10} more lines");
    }
  }

  /// Translate text from French to English
  Future<String> translateResult(String text) async {
    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.french,
      targetLanguage: TranslateLanguage.english,
    );
    final translation = await translator.translateText(text);
    await translator.close();
    return translation;
  }

  /// Generate a professional medical PDF with improved layout
  Future<File> generateMedicalPdf(
    File imageFile,
    String originalText,
    String translatedText, {
    String sourceLanguage = 'Original',
    String targetLanguage = 'Translated',
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final imageBytes = imageFile.readAsBytesSync();

    final hasTranslation = translatedText.isNotEmpty &&
        translatedText != 'No translation available';

    // ===== PAGE 1: Full-page scanned document =====
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Compact header
            _buildPdfHeader(dateStr, timeStr),
            pw.SizedBox(height: 12),

            // Full-size scanned image
            pw.Expanded(
              child: pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(
                    pw.MemoryImage(imageBytes),
                    fit: pw.BoxFit.contain,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 8),

            // Footer
            _buildPdfFooter(1, hasTranslation ? 3 : 2),
          ],
        ),
      ),
    );

    // ===== PAGE 2: Original Text =====
    _addTextPage(
      pdf,
      title: 'Extracted Text',
      subtitle: sourceLanguage,
      content: originalText,
      pageNumber: 2,
      totalPages: hasTranslation ? 3 : 2,
      accentColor: PdfColors.blue700,
      dateStr: dateStr,
      timeStr: timeStr,
    );

    // ===== PAGE 3: Translation (if available) =====
    if (hasTranslation) {
      _addTextPage(
        pdf,
        title: 'Translation',
        subtitle: targetLanguage,
        content: translatedText,
        pageNumber: 3,
        totalPages: 3,
        accentColor: PdfColors.teal700,
        dateStr: dateStr,
        timeStr: timeStr,
        showDisclaimer: true,
      );
    }

    // Save the file
    final output = await getApplicationDocumentsDirectory();
    final file = File(
      "${output.path}/medpass_scan_${DateTime.now().millisecondsSinceEpoch}.pdf",
    );
    return await file.writeAsBytes(await pdf.save());
  }

  /// Build PDF header
  pw.Widget _buildPdfHeader(String dateStr, String timeStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColors.blue800, PdfColors.teal600],
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Med-Pass',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Medical Document',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                dateStr,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                timeStr,
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build PDF footer
  pw.Widget _buildPdfFooter(int pageNumber, int totalPages) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Generated by Med-Pass',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
        pw.Text(
          'Page $pageNumber of $totalPages',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ],
    );
  }

  /// Add a text content page to the PDF
  void _addTextPage(
    pw.Document pdf, {
    required String title,
    required String subtitle,
    required String content,
    required int pageNumber,
    required int totalPages,
    required PdfColor accentColor,
    required String dateStr,
    required String timeStr,
    bool showDisclaimer = false,
  }) {
    // Split content into chunks for multi-page support
    final lines = content.split('\n');
    const linesPerPage = 45; // Approximate lines that fit on a page

    int currentPage = pageNumber;
    for (int i = 0; i < lines.length; i += linesPerPage) {
      final pageLines = lines.skip(i).take(linesPerPage).join('\n');
      final isFirstChunk = i == 0;
      final isLastChunk = i + linesPerPage >= lines.length;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Section header (only on first chunk)
              if (isFirstChunk) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: accentColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        title,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Text(
                          subtitle,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
              ],

              // Text content
              pw.Expanded(
                child: pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColors.grey200),
                  ),
                  child: pw.Text(
                    pageLines,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      lineSpacing: 1.5,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
              ),

              // Disclaimer (only on last page with translation)
              if (showDisclaimer && isLastChunk) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.amber50,
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColors.amber200),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '⚠',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Text(
                          'This translation was generated using AI. Please verify important medical information with a qualified healthcare professional.',
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: PdfColors.amber900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 8),
              _buildPdfFooter(currentPage, totalPages),
            ],
          ),
        ),
      );
      currentPage++;
    }
  }

  /// Dispose recognizer when done
  Future<void> dispose() async {
    try {
      await _textRecognizer.close();
    } catch (_) {}
  }
}
