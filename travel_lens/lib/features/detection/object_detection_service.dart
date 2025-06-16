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
      final response = await _apiService.sendImageToHuggingFace(
        modelEndpoint: ApiConfig.objectDetectionModel,
        imageFile: imageFile,
      );

      if (response is List) {
        return _parseDetectionResponse(response);
      }

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
