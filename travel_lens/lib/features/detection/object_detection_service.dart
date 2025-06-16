import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/services/api_config.dart';
import 'package:travel_lens/core/services/api_service.dart';
import 'package:travel_lens/data/models/detection_result.dart';

class ObjectDetectionService {
  final ApiService _apiService;

  ObjectDetectionService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<List<DetectedObject>> detectObjects(File imageFile) async {
    try {
      debugPrint(
          '[ObjectDetectionService] Using model endpoint: ${ApiConfig.objectDetectionModel}');
      // Debug API key presence (don't log the full key in production)
      final apiKeyPresent = ApiConfig.huggingFaceApiKey.isNotEmpty;
      final apiKeyFirstChars =
          apiKeyPresent && ApiConfig.huggingFaceApiKey.length > 5
              ? "${ApiConfig.huggingFaceApiKey.substring(0, 5)}..."
              : "missing";
      debugPrint(
          '[ObjectDetectionService] API key present: $apiKeyPresent (starts with $apiKeyFirstChars)');
      debugPrint(
          '[ObjectDetectionService] Full URL: ${ApiConfig.huggingFaceBaseUrl}/models/${ApiConfig.objectDetectionModel}');

      // Check if image file exists and is readable
      if (!await imageFile.exists()) {
        throw AppException('Image file does not exist: ${imageFile.path}');
      }

      // Check image file size
      final fileSize = await imageFile.length();
      debugPrint('[ObjectDetectionService] Image file size: $fileSize bytes');

      // Proceed with API call
      final response = await _apiService.sendImageToHuggingFace(
        modelEndpoint: ApiConfig.objectDetectionModel,
        imageFile: imageFile,
      );

      // Handle various response formats
      if (response is List) {
        return _parseDetectionResponse(response);
      } else if (response is Map<String, dynamic>) {
        debugPrint('[ObjectDetectionService] Got Map response: $response');
        // Some models return results in different formats
        if (response.containsKey('detections')) {
          return _parseDetectionResponse(response['detections']);
        }
      }

      // If we got here, the response format was unexpected
      debugPrint(
          '[ObjectDetectionService] Unexpected response format: $response');
      throw AppException('Invalid response format from object detection API');
    } catch (e) {
      debugPrint('Object detection error: $e');
      if (e is AppException) {
        rethrow;
      }
      throw AppException('Failed to detect objects: $e');
    }
  }

  List<DetectedObject> _parseDetectionResponse(List<dynamic> response) {
    try {
      final List<DetectedObject> detectedObjects = [];

      for (var item in response) {
        if (item is Map<String, dynamic>) {
          final label = item['label'] as String?;
          final score = item['score'] as double?;
          final box = item['box'] as Map<String, dynamic>?;

          if (label != null && score != null) {
            detectedObjects.add(DetectedObject(
              label: label,
              score: score,
              box: box,
            ));
          }
        }
      }

      return detectedObjects;
    } catch (e) {
      throw AppException('Error parsing detection results: $e');
    }
  }
}
