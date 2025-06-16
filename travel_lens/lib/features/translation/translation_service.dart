import 'package:flutter/foundation.dart';
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/services/api_service.dart';

class TranslationService {
  final ApiService _apiService;

  TranslationService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // Skip translation if target language is the same as source
      if ((sourceLanguage != 'auto' && sourceLanguage == targetLanguage) ||
          text.trim().isEmpty) {
        return text;
      }

      // Choose the appropriate model based on language pairs
      String modelEndpoint =
          _getTranslationModel(sourceLanguage, targetLanguage);

      // Prepare options if needed
      Map<String, dynamic> options = {};

      // For models that require specific format
      if (modelEndpoint.contains('m2m100') ||
          modelEndpoint.contains('nllb') ||
          modelEndpoint.contains('mbart')) {
        options = {
          'src_lang': sourceLanguage,
          'tgt_lang': targetLanguage,
        };
      }

      final response = await _apiService.sendTextToHuggingFace(
        modelEndpoint: modelEndpoint,
        text: text,
        options: options,
      );

      // Handle different response formats
      if (response is List && response.isNotEmpty) {
        if (response[0] is Map<String, dynamic> &&
            response[0].containsKey('translation_text')) {
          return response[0]['translation_text'];
        } else {
          return response[0].toString();
        }
      } else if (response is Map<String, dynamic>) {
        if (response.containsKey('translation_text')) {
          return response['translation_text'];
        } else if (response.containsKey('generated_text')) {
          return response['generated_text'];
        }
      }

      // Fallback
      return response.toString();
    } catch (e) {
      debugPrint('Translation error: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Translation failed: $e');
    }
  }

  String _getTranslationModel(String sourceLanguage, String targetLanguage) {
    // Auto-detect source language special case
    if (sourceLanguage == 'auto') {
      sourceLanguage = 'en'; // Default assumption for simplicity
    }

    // This is a simplified version - in a real app, you'd have mappings for many language pairs
    if (sourceLanguage == 'en' &&
        ['es', 'fr', 'it', 'pt', 'ca', 'ro'].contains(targetLanguage)) {
      return 'Helsinki-NLP/opus-mt-en-ROMANCE';
    } else if (['es', 'fr', 'it', 'pt', 'ca', 'ro'].contains(sourceLanguage) &&
        targetLanguage == 'en') {
      return 'Helsinki-NLP/opus-mt-ROMANCE-en';
    } else if (sourceLanguage == 'en' && targetLanguage == 'de') {
      return 'Helsinki-NLP/opus-mt-en-de';
    } else if (sourceLanguage == 'de' && targetLanguage == 'en') {
      return 'Helsinki-NLP/opus-mt-de-en';
    } else if (sourceLanguage == 'en' && targetLanguage == 'zh') {
      return 'Helsinki-NLP/opus-mt-en-zh';
    } else if (sourceLanguage == 'zh' && targetLanguage == 'en') {
      return 'Helsinki-NLP/opus-mt-zh-en';
    } else if (sourceLanguage == 'en' && targetLanguage == 'ja') {
      return 'Helsinki-NLP/opus-mt-en-jap';
    } else if (sourceLanguage == 'ja' && targetLanguage == 'en') {
      return 'Helsinki-NLP/opus-mt-jap-en';
    } else {
      // Default fallback to a multilingual model
      return 'facebook/m2m100_418M';
    }
  }

  // Get supported language pairs
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'en', 'name': 'English'},
      {'code': 'es', 'name': 'Spanish'},
      {'code': 'fr', 'name': 'French'},
      {'code': 'de', 'name': 'German'},
      {'code': 'it', 'name': 'Italian'},
      {'code': 'pt', 'name': 'Portuguese'},
      {'code': 'zh', 'name': 'Chinese'},
      {'code': 'ja', 'name': 'Japanese'},
      {'code': 'ar', 'name': 'Arabic'},
      {'code': 'ru', 'name': 'Russian'},
      {'code': 'hi', 'name': 'Hindi'},
    ];
  }
}
