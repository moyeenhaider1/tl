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
      final response = await _apiService.sendImageToHuggingFace(
        modelEndpoint: ApiConfig.ocrModel,
        imageFile: imageFile,
      );

      if (response is List && response.isNotEmpty) {
        if (response.first is Map<String, dynamic> &&
            response.first.containsKey('generated_text')) {
          return response.first['generated_text'] as String;
        } else {
          return response.first.toString();
        }
      } else if (response is Map<String, dynamic> &&
          response.containsKey('generated_text')) {
        return response['generated_text'] as String;
      } else if (response is String) {
        return response;
      }

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
