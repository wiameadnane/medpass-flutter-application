import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/language_detection_service.dart';

/// Translation service that handles premium/freemium restrictions
class TranslationService {
  static const Map<TranslateLanguage, String> _languageNames = {
    // Common languages
    TranslateLanguage.english: 'English',
    TranslateLanguage.french: 'French',
    TranslateLanguage.spanish: 'Spanish',
    TranslateLanguage.german: 'German',
    TranslateLanguage.arabic: 'Arabic',
    TranslateLanguage.chinese: 'Chinese',
    // Additional premium languages
    TranslateLanguage.portuguese: 'Portuguese',
    TranslateLanguage.italian: 'Italian',
    TranslateLanguage.russian: 'Russian',
    TranslateLanguage.japanese: 'Japanese',
    TranslateLanguage.korean: 'Korean',
    TranslateLanguage.hindi: 'Hindi',
    TranslateLanguage.dutch: 'Dutch',
    TranslateLanguage.turkish: 'Turkish',
    TranslateLanguage.polish: 'Polish',
    TranslateLanguage.vietnamese: 'Vietnamese',
    TranslateLanguage.thai: 'Thai',
    TranslateLanguage.indonesian: 'Indonesian',
    TranslateLanguage.greek: 'Greek',
    TranslateLanguage.hebrew: 'Hebrew',
    TranslateLanguage.swedish: 'Swedish',
    TranslateLanguage.romanian: 'Romanian',
    TranslateLanguage.czech: 'Czech',
    TranslateLanguage.ukrainian: 'Ukrainian',
    TranslateLanguage.bengali: 'Bengali',
    TranslateLanguage.urdu: 'Urdu',
  };

  /// All supported languages (sorted alphabetically by name)
  static const List<TranslateLanguage> allLanguages = [
    TranslateLanguage.arabic,
    TranslateLanguage.bengali,
    TranslateLanguage.chinese,
    TranslateLanguage.czech,
    TranslateLanguage.dutch,
    TranslateLanguage.english,
    TranslateLanguage.french,
    TranslateLanguage.german,
    TranslateLanguage.greek,
    TranslateLanguage.hebrew,
    TranslateLanguage.hindi,
    TranslateLanguage.indonesian,
    TranslateLanguage.italian,
    TranslateLanguage.japanese,
    TranslateLanguage.korean,
    TranslateLanguage.polish,
    TranslateLanguage.portuguese,
    TranslateLanguage.romanian,
    TranslateLanguage.russian,
    TranslateLanguage.spanish,
    TranslateLanguage.swedish,
    TranslateLanguage.thai,
    TranslateLanguage.turkish,
    TranslateLanguage.ukrainian,
    TranslateLanguage.urdu,
    TranslateLanguage.vietnamese,
  ];

  /// Get available source languages for the current user
  /// Free users: All languages (auto-detect works for any)
  /// Premium users: All languages
  static List<TranslateLanguage> getAvailableSourceLanguages(
      BuildContext context) {
    // All users can have any source language (auto-detected)
    return allLanguages;
  }

  /// Get available target languages for the current user
  /// Free users: Preferred language + English (or French if preferred is English)
  /// Premium users: All languages
  static List<TranslateLanguage> getAvailableTargetLanguages(
      BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final isPremium = userProvider.user?.isPremium ?? false;

    if (isPremium) {
      // Premium users can translate to all languages
      return allLanguages;
    } else {
      // Free users: preferred language + English (or French if preferred is English)
      final preferredCode = userProvider.user?.preferredLanguage ?? 'en';
      final preferredLang = LanguageDetectionService.codeToTranslateLanguage(preferredCode)
          ?? TranslateLanguage.english;

      final Set<TranslateLanguage> freeLanguages = {preferredLang};

      // Add English as fallback (or French if preferred is English)
      if (preferredLang == TranslateLanguage.english) {
        freeLanguages.add(TranslateLanguage.french);
      } else {
        freeLanguages.add(TranslateLanguage.english);
      }

      return freeLanguages.toList();
    }
  }

  /// Check if a language is premium-only for target translations for this user
  static bool isPremiumTargetLanguage(TranslateLanguage language, BuildContext context) {
    final availableTargets = getAvailableTargetLanguages(context);
    return !availableTargets.contains(language);
  }

  /// Legacy check - kept for compatibility
  static bool isPremiumTargetLanguageLegacy(TranslateLanguage language) {
    return language == TranslateLanguage.spanish ||
        language == TranslateLanguage.chinese ||
        language == TranslateLanguage.german ||
        language == TranslateLanguage.arabic;
  }

  /// Get display name for a language
  static String getLanguageName(TranslateLanguage language) {
    return _languageNames[language] ?? language.name;
  }

  /// Show upgrade dialog for premium features
  static Future<void> showUpgradeDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text(
          'Translation to additional languages is available with Premium subscription. '
          'Upgrade now to access all translation languages!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(context, '/billing');
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  /// Check if translation models are available and download if needed
  static Future<String?> ensureModelsDownloaded(
    TranslateLanguage sourceLanguage,
    TranslateLanguage targetLanguage,
  ) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      final sourceDownloaded =
          await modelManager.isModelDownloaded(sourceLanguage.bcpCode);
      final targetDownloaded =
          await modelManager.isModelDownloaded(targetLanguage.bcpCode);

      debugPrint('Source model downloaded: $sourceDownloaded');
      debugPrint('Target model downloaded: $targetDownloaded');

      if (!sourceDownloaded) {
        debugPrint('Downloading source language model: ${sourceLanguage.bcpCode}');
        await modelManager.downloadModel(sourceLanguage.bcpCode);
        debugPrint('Source model download completed');
      }

      if (!targetDownloaded) {
        debugPrint('Downloading target language model: ${targetLanguage.bcpCode}');
        await modelManager.downloadModel(targetLanguage.bcpCode);
        debugPrint('Target model download completed');
      }

      return null; // Success
    } catch (e) {
      debugPrint('Error downloading models: $e');
      return 'Failed to download translation models. Please check your internet connection and try again. Error: $e';
    }
  }

  /// Translate text with premium restrictions check
  /// This method preserves the original text layout (paragraphs, line breaks)
  static Future<String> translateText(
    BuildContext context,
    String text,
    TranslateLanguage sourceLanguage,
    TranslateLanguage targetLanguage,
  ) async {
    // Check if user is trying to use premium-only target language
    if (isPremiumTargetLanguage(targetLanguage, context)) {
      await showUpgradeDialog(context);
      throw Exception('Premium feature required');
    }

    // Ensure models are downloaded before translation
    final downloadError =
        await ensureModelsDownloaded(sourceLanguage, targetLanguage);
    if (downloadError != null) {
      throw Exception(downloadError);
    }

    OnDeviceTranslator? translator;
    try {
      translator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      // Preserve layout by translating paragraph by paragraph
      final translatedText = await _translatePreservingLayout(translator, text);
      return translatedText;
    } catch (e) {
      debugPrint('Translation error: $e');
      rethrow;
    } finally {
      try {
        await translator?.close();
      } catch (_) {}
    }
  }

  /// Translate text while preserving the original layout structure
  /// Splits by paragraphs, translates each, and reassembles
  static Future<String> _translatePreservingLayout(
    OnDeviceTranslator translator,
    String text,
  ) async {
    debugPrint("=== Translation Input ===");
    debugPrint("Text length: ${text.length}");
    final inputNewlines = "\n".allMatches(text).length;
    debugPrint("Newline count: $inputNewlines");
    debugPrint("First 200 chars: ${text.substring(0, text.length > 200 ? 200 : text.length)}");

    // Split by paragraph breaks (double newlines or more)
    final paragraphPattern = RegExp(r'\n\s*\n');
    final paragraphs = text.split(paragraphPattern);

    debugPrint('Paragraphs found: ${paragraphs.length}');

    final List<String> translatedParagraphs = [];

    for (int pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final paragraph = paragraphs[pIdx];

      if (paragraph.trim().isEmpty) {
        // Preserve empty paragraphs
        translatedParagraphs.add('');
        continue;
      }

      // Split paragraph into lines to preserve line breaks within paragraphs
      final lines = paragraph.split('\n');
      debugPrint('Paragraph $pIdx has ${lines.length} lines');

      final List<String> translatedLines = [];

      for (final line in lines) {
        if (line.trim().isEmpty) {
          // Preserve empty lines
          translatedLines.add('');
          continue;
        }

        // Translate the line
        try {
          final translatedLine = await translator.translateText(line.trim());
          translatedLines.add(translatedLine);
        } catch (e) {
          // If translation fails for a line, keep original
          debugPrint('Line translation failed: $e');
          translatedLines.add(line);
        }
      }

      // Rejoin lines within paragraph
      translatedParagraphs.add(translatedLines.join('\n'));
    }

    // Rejoin paragraphs with double newlines
    final result = translatedParagraphs.join("\n\n");

    debugPrint("=== Translation Output ===");
    debugPrint("Result length: ${result.length}");
    final outputNewlines = "\n".allMatches(result).length;
    debugPrint("Result newline count: $outputNewlines");

    return result;
  }
}
