import 'dart:io';

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

      // Handle different response formats
      if (response is List) {
        // Process list response format
        if (response.isNotEmpty) {
          // Extract text from each item and join
          List<String> textSegments = [];

          // Option 3: Using indexed loop
          for (int i = 0; i < response.length; i++) {
            var item = response[i];
            if (item is Map<String, dynamic> && item.containsKey('text')) {
              textSegments.add(item['text'].toString());
            }
          }

          return textSegments.join('\n');
        }
        return ''; // Empty response
      } else // Process map response format
      if (response.containsKey('generated_text')) {
        return response['generated_text'].toString();
      } else if (response.containsKey('text')) {
        return response['text'].toString();
      }

      // Fallback: convert entire response to string
      return response.toString();
    } catch (e) {
      throw Exception('OCR extraction failed: $e');
    }
  }
}
