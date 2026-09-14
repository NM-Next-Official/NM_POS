import 'package:translator/translator.dart';

class DynamicTranslator {
  static final GoogleTranslator _translator = GoogleTranslator();

  // Cache to store translated values and avoid redundant network requests
  static final Map<String, String> _cache = {};

  // Active target language code (Default: 'en')
  static String _activeLanguageCode = 'en';

  static String get activeLanguageCode => _activeLanguageCode;

  /// Map display names (e.g., 'Bangla', 'Hindi') to standard ISO language codes
  static void setLanguage(String language) {
    switch (language.trim().toLowerCase()) {
      case 'bangla':
      case 'bengali':
      case 'bn':
        _activeLanguageCode = 'bn';
        break;
      case 'hindi':
      case 'hi':
        _activeLanguageCode = 'hi';
        break;
      case 'english':
      case 'en':
      default:
        _activeLanguageCode = 'en';
        break;
    }
  }

  /// Translates text on-the-fly using Google Translate API with caching
  static Future<String> translate(String text) async {
    final trimmedText = text.trim();

    // Return original text immediately if language is English or text is empty
    if (_activeLanguageCode == 'en' || trimmedText.isEmpty) {
      return text;
    }

    final String cacheKey = '$_activeLanguageCode:$trimmedText';

    // Check if translation exists in local cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final Translation translation = await _translator.translate(
        trimmedText,
        to: _activeLanguageCode,
      );

      // Save result in memory cache
      _cache[cacheKey] = translation.text;
      return translation.text;
    } catch (e) {
      // Return original text as fallback if API call fails
      return text;
    }
  }

  /// Clear memory cache when needed
  static void clearCache() {
    _cache.clear();
  }
}
