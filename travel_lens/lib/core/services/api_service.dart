import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:travel_lens/core/errors/api_exception.dart';
import 'package:travel_lens/core/services/api_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> sendImageToHuggingFace({
    required String modelEndpoint,
    required File imageFile,
    Map<String, dynamic>? options,
  }) async {
    try {
      final url = '${ApiConfig.huggingFaceBaseUrl}/$modelEndpoint';

      // Read image file as bytes
      final bytes = await imageFile.readAsBytes();

      // Prepare headers
      final headers = {
        'Authorization': 'Bearer ${ApiConfig.huggingFaceApiKey}',
        'Content-Type': 'application/octet-stream',
      };

      // Send request
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );

      // Check response
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 503) {
        // Model is loading
        final responseBody = json.decode(response.body);
        final estimatedTime = responseBody['estimated_time'] ?? 20;

        // Wait and retry
        await Future.delayed(Duration(seconds: estimatedTime));
        return sendImageToHuggingFace(
          modelEndpoint: modelEndpoint,
          imageFile: imageFile,
          options: options,
        );
      } else {
        throw ApiException(
          code: response.statusCode,
          message: 'API request failed: ${response.body}',
        );
      }
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Error sending image to Hugging Face: $e',
      );
    }
  }

  Future<Map<String, dynamic>> sendTextToHuggingFace({
    required String modelEndpoint,
    required String text,
    Map<String, dynamic>? options,
  }) async {
    try {
      final url = '${ApiConfig.huggingFaceBaseUrl}/$modelEndpoint';

      // Prepare headers
      final headers = {
        'Authorization': 'Bearer ${ApiConfig.huggingFaceApiKey}',
        'Content-Type': 'application/json',
      };

      // Prepare body
      final body = json.encode({
        'inputs': text,
        'options': options ?? {},
      });

      // Send request
      final response = await _client.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      // Check response
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 503) {
        // Model is loading
        final responseBody = json.decode(response.body);
        final estimatedTime = responseBody['estimated_time'] ?? 20;

        // Wait and retry
        await Future.delayed(Duration(seconds: estimatedTime));
        return sendTextToHuggingFace(
          modelEndpoint: modelEndpoint,
          text: text,
          options: options,
        );
      } else {
        throw ApiException(
          code: response.statusCode,
          message: 'API request failed: ${response.body}',
        );
      }
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Error sending text to Hugging Face: $e',
      );
    }
  }

  Future<Map<String, dynamic>> getWikipediaInfo(String title) async {
    try {
      final url = '${ApiConfig.wikipediaBaseUrl}/page/summary/$title';

      final response = await _client.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
          code: response.statusCode,
          message: 'Wikipedia API request failed: ${response.body}',
        );
      }
    } catch (e) {
      throw ApiException(
        code: 500,
        message: 'Error fetching Wikipedia info: $e',
      );
    }
  }
}
