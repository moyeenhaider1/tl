import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/services/api_config.dart';
import 'package:travel_lens/core/services/api_service.dart';

class OcrService {
  final ApiService _apiService;

  OcrService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<String> extractText(File imageFile) async {
    try {
      // Check if API key is properly configured
      if (ApiConfig.huggingFaceApiKey == 'YOUR_HUGGINGFACE_API_KEY' ||
          ApiConfig.huggingFaceApiKey.isEmpty) {
        throw AppException(
          'Hugging Face API key not configured. Please set up your API key in the environment variables.',
          code: 'api_key_missing',
        );
      }

      debugPrint(
          '[OcrService] Starting OCR with primary model: ${ApiConfig.ocrModel}');
      debugPrint('[OcrService] Image path: ${imageFile.path}');

      // Check if image exists
      if (!await imageFile.exists()) {
        throw AppException('Image file does not exist: ${imageFile.path}');
      }

      // Check file size (avoid sending very large files)
      final fileSize = await imageFile.length();
      if (fileSize > 1024 * 1024 * 5) {
        // 5MB limit
        debugPrint('[OcrService] Warning: Image is large ($fileSize bytes)');
      } else {
        debugPrint('[OcrService] Image size: $fileSize bytes');
      } // Try primary model first, then fallbacks
      final modelsToTry = [ApiConfig.ocrModel, ...ApiConfig.ocrFallbackModels];
      String lastError = '';

      for (int i = 0; i < modelsToTry.length; i++) {
        final model = modelsToTry[i];
        try {
          debugPrint(
              '[OcrService] Trying model ${i + 1}/${modelsToTry.length}: $model');

          // Log API URL being used
          const apiUrl = '${ApiConfig.huggingFaceBaseUrl}/models';
          debugPrint('[OcrService] API URL: $apiUrl/$model');

          // Extract text with current model
          final response = await _apiService.sendImageToHuggingFace(
            modelEndpoint: model,
            imageFile: imageFile,
          );

          debugPrint(
              '[OcrService] Response received from $model: ${response.runtimeType}');

          final extractedText = _parseOcrResponse(response, model);
          if (extractedText.isNotEmpty) {
            debugPrint(
                '[OcrService] Successfully extracted text using model: $model');
            return extractedText;
          } else {
            debugPrint('[OcrService] Model $model returned empty text');
          }
        } catch (e) {
          lastError = e.toString();
          debugPrint('[OcrService] Model $model failed: $e');

          // If it's a 404 error, continue to next model
          if (e is AppException && e.code == '404') {
            debugPrint(
                '[OcrService] Model $model not available, trying next...');
            continue;
          }

          // For other errors, if this is the last model, rethrow
          if (i == modelsToTry.length - 1) {
            rethrow;
          }
          // Continue to next model for other errors too
          continue;
        }
      }

      // All models either failed or returned empty text
      debugPrint('[OcrService] All models exhausted. Last error: $lastError');

      // Return a more user-friendly error message
      throw AppException(
        'OCR service temporarily unavailable. Please try again later or check your internet connection.',
        code: 'ocr_unavailable',
      );
    } catch (e) {
      debugPrint('OCR error: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Failed to extract text: $e');
    }
  }

  String _parseOcrResponse(dynamic response, String modelName) {
    if (response is List && response.isNotEmpty) {
      if (response.first is Map<String, dynamic> &&
          response.first.containsKey('generated_text')) {
        return response.first['generated_text'] as String;
      } else {
        return response.first.toString();
      }
    } else if (response is Map<String, dynamic>) {
      debugPrint(
          '[OcrService] Response keys for $modelName: ${response.keys.toList()}');
      if (response.containsKey('generated_text')) {
        return response['generated_text'] as String;
      } else if (response.containsKey('text')) {
        return response['text'] as String;
      }
      // For debugging, log the response structure
      debugPrint(
          '[OcrService] Unknown response format for $modelName: $response');
      return '';
    } else if (response is String) {
      return response;
    }

    debugPrint(
        '[OcrService] Unsupported response type for $modelName: ${response.runtimeType}');
    return '';
  }
}
