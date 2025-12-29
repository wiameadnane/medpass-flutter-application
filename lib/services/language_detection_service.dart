import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Service to detect the language of text
class LanguageDetectionService {
  LanguageIdentifier? _languageIdentifier;

  /// Map from BCP-47 language codes to TranslateLanguage
  static const Map<String, TranslateLanguage> _bcpToTranslateLanguage = {
    'en': TranslateLanguage.english,
    'fr': TranslateLanguage.french,
    'ar': TranslateLanguage.arabic,
    'es': TranslateLanguage.spanish,
    'de': TranslateLanguage.german,
    'zh': TranslateLanguage.chinese,
  };

  /// Map from TranslateLanguage to display names
  static const Map<TranslateLanguage, String> languageNames = {
    TranslateLanguage.english: 'English',
    TranslateLanguage.french: 'French',
    TranslateLanguage.arabic: 'Arabic',
    TranslateLanguage.spanish: 'Spanish',
    TranslateLanguage.german: 'German',
    TranslateLanguage.chinese: 'Chinese',
  };

  /// Map from user preferred language code to TranslateLanguage
  static TranslateLanguage? codeToTranslateLanguage(String code) {
    return _bcpToTranslateLanguage[code];
  }

  /// Get language code from TranslateLanguage
  static String translateLanguageToCode(TranslateLanguage lang) {
    return _bcpToTranslateLanguage.entries
        .firstWhere((e) => e.value == lang, orElse: () => const MapEntry('en', TranslateLanguage.english))
        .key;
  }

  /// Detect the language of the given text
  /// Returns the detected TranslateLanguage or null if detection fails
  Future<TranslateLanguage?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return null;

    try {
      _languageIdentifier ??= LanguageIdentifier(confidenceThreshold: 0.5);

      final String languageCode = await _languageIdentifier!.identifyLanguage(text);

      if (languageCode == 'und') {
        // Undetermined - try to identify possible languages
        final possibleLanguages = await _languageIdentifier!.identifyPossibleLanguages(text);
        if (possibleLanguages.isNotEmpty) {
          final bestMatch = possibleLanguages.first;
          return _bcpToTranslateLanguage[bestMatch.languageTag];
        }
        return null;
      }

      return _bcpToTranslateLanguage[languageCode];
    } catch (e) {
      debugPrint('Language detection error: $e');
      return null;
    }
  }

  /// Get display name for a TranslateLanguage
  static String getLanguageName(TranslateLanguage language) {
    return languageNames[language] ?? language.name;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _languageIdentifier?.close();
    _languageIdentifier = null;
  }
}
