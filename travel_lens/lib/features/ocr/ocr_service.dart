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
      debugPrint('[OcrService] Starting OCR with model: ${ApiConfig.ocrModel}');
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
      }

      // Log API URL being used
      const apiUrl =
          '${ApiConfig.huggingFaceBaseUrl}/models/${ApiConfig.ocrModel}';
      debugPrint('[OcrService] API URL: $apiUrl');

      // Extract text with current model
      final response = await _apiService.sendImageToHuggingFace(
        modelEndpoint: ApiConfig.ocrModel,
        imageFile: imageFile,
      );

      debugPrint('[OcrService] Response received: ${response.runtimeType}');

      if (response is List && response.isNotEmpty) {
        if (response.first is Map<String, dynamic> &&
            response.first.containsKey('generated_text')) {
          return response.first['generated_text'] as String;
        } else {
          return response.first.toString();
        }
      } else if (response is Map<String, dynamic>) {
        debugPrint('[OcrService] Response keys: ${response.keys.toList()}');
        if (response.containsKey('generated_text')) {
          return response['generated_text'] as String;
        } else if (response.containsKey('text')) {
          return response['text'] as String;
        }
        // Return all map content as fallback
        return response.toString();
      } else if (response is String) {
        return response;
      }

      debugPrint('[OcrService] Empty or unsupported response format');
      return '';
    } catch (e) {
      debugPrint('OCR error: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Failed to extract text: $e');
    }
  }
}
