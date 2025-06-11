import 'dart:io';

import 'package:travel_lens/core/services/api_config.dart';
import 'package:travel_lens/core/services/api_service.dart';

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

      // Handle different response formats from Hugging Face models
      List<dynamic> results;

      if (response is List) {
        // Response is already a list
        results = response as List<dynamic>;
      } else // Extract results from map - adjust key based on actual API response
      if (response.containsKey('results')) {
        results = response['results'] as List<dynamic>;
      } else if (response.containsKey('detections')) {
        results = response['detections'] as List<dynamic>;
      } else {
        // If we can't find expected keys, return empty list
        return [];
      }

      return results.map((item) {
        // Handle different object detection response formats
        if (item is Map<String, dynamic>) {
          // Handle standard format
          if (item.containsKey('label') &&
              item.containsKey('score') &&
              item.containsKey('box')) {
            return DetectedObject(
              label: item['label'],
              score: (item['score'] as num).toDouble(),
              box: BoundingBox(
                xMin: (item['box']['xmin'] as num).toDouble(),
                yMin: (item['box']['ymin'] as num).toDouble(),
                xMax: (item['box']['xmax'] as num).toDouble(),
                yMax: (item['box']['ymax'] as num).toDouble(),
              ),
            );
          }
          // Alternative format (adjust based on actual API response)
          else if (item.containsKey('class') &&
              item.containsKey('confidence') &&
              item.containsKey('bbox')) {
            return DetectedObject(
              label: item['class'],
              score: (item['confidence'] as num).toDouble(),
              box: BoundingBox(
                xMin: (item['bbox'][0] as num).toDouble(),
                yMin: (item['bbox'][1] as num).toDouble(),
                xMax: (item['bbox'][2] as num).toDouble(),
                yMax: (item['bbox'][3] as num).toDouble(),
              ),
            );
          }
        }

        // Fallback for unexpected item format
        return DetectedObject(
          label: 'Unknown',
          score: 0.0,
          box: BoundingBox(xMin: 0, yMin: 0, xMax: 0, yMax: 0),
        );
      }).toList();
    } catch (e) {
      throw Exception('Object detection failed: $e');
    }
  }
}

class DetectedObject {
  final String label;
  final double score;
  final BoundingBox box;

  DetectedObject({
    required this.label,
    required this.score,
    required this.box,
  });
}

class BoundingBox {
  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  BoundingBox({
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
  });
}
