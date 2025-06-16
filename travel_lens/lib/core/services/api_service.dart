import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/services/api_config.dart';

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> sendImageToHuggingFace({
    required String modelEndpoint,
    required File imageFile,
    Map<String, dynamic>? options,
    int retries = ApiConfig.defaultRetries,
  }) async {
    int attempts = 0;
    late Exception lastException;

    while (attempts < retries) {
      try {
        attempts++;

        // Ensure properly formatted URL for Hugging Face Inference API
        // The correct format is: https://api-inference.huggingface.co/models/MODEL_ID
        final url = '${ApiConfig.huggingFaceBaseUrl}/models/$modelEndpoint';

        debugPrint('Sending request to HuggingFace: $url');

        // Read image file as bytes
        final bytes = await imageFile.readAsBytes();

        // Determine content type based on file extension
        final contentType = _getContentTypeFromFile(imageFile);

        // Prepare headers - ensure API key is properly formatted
        final apiKey = ApiConfig.huggingFaceApiKey.trim();
        final headers = {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': contentType,
        };

        // Log API request details (without exposing full API key)
        debugPrint('HuggingFace API request:');
        debugPrint('- URL: $url');
        debugPrint('- ContentType: $contentType');
        debugPrint('- ImageSize: ${bytes.length} bytes');
        debugPrint(
            '- API Key prefix: ${apiKey.substring(0, min(5, apiKey.length))}...');

        // Send request with more graceful timeout handling
        final response = await _client
            .post(
          Uri.parse(url),
          headers: headers,
          body: bytes,
        )
            .timeout(
          const Duration(seconds: ApiConfig.defaultTimeout),
          onTimeout: () {
            debugPrint(
                'HuggingFace API request timed out after ${ApiConfig.defaultTimeout} seconds');
            throw AppException(
                'API request timed out. Try with a smaller image or try again later.',
                code: 'timeout');
          },
        );

        // Check response
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 503) {
          // Model is loading
          final responseBody = json.decode(response.body);
          final estimatedTime =
              responseBody['estimated_time'] ?? ApiConfig.retryDelay;

          // Wait and retry
          await Future.delayed(Duration(seconds: min(estimatedTime, 20)));
          continue; // Retry without counting as an attempt
        } else {
          throw AppException(
            'API request failed: ${response.body}',
            code: response.statusCode.toString(),
          );
        }
      } on AppException catch (e) {
        lastException = e;
        // Exponential backoff
        if (attempts < retries) {
          await Future.delayed(
            Duration(seconds: ApiConfig.retryDelay * attempts),
          );
        }
      } catch (e) {
        lastException = AppException(
          'Error sending image to Hugging Face: $e',
        );
        // Exponential backoff
        if (attempts < retries) {
          await Future.delayed(
            Duration(seconds: ApiConfig.retryDelay * attempts),
          );
        }
      }
    }

    // All retries failed
    throw lastException;
  }

// Add this helper function to determine content type
  String _getContentTypeFromFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;

    switch (extension) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'webp':
        return 'image/webp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      default:
        throw AppException('Unsupported image format: .$extension');
    }
  }

  Future<dynamic> sendTextToHuggingFace({
    required String modelEndpoint,
    required String text,
    Map<String, dynamic>? options,
    int retries = ApiConfig.defaultRetries,
  }) async {
    int attempts = 0;
    late Exception lastException;

    while (attempts < retries) {
      try {
        attempts++;

        final url = '${ApiConfig.huggingFaceBaseUrl}/models/$modelEndpoint';

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
        final response = await _client
            .post(
              Uri.parse(url),
              headers: headers,
              body: body,
            )
            .timeout(const Duration(seconds: ApiConfig.defaultTimeout));

        // Check response
        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else if (response.statusCode == 503) {
          // Model is loading
          final responseBody = json.decode(response.body);
          final estimatedTime =
              responseBody['estimated_time'] ?? ApiConfig.retryDelay;

          // Wait and retry
          await Future.delayed(Duration(seconds: min(estimatedTime, 20)));
          continue; // Retry without counting as an attempt
        } else {
          throw AppException(
            'API request failed: ${response.body}',
            code: response.statusCode.toString(),
          );
        }
      } on AppException catch (e) {
        lastException = e;
        // Exponential backoff
        if (attempts < retries) {
          await Future.delayed(
            Duration(seconds: ApiConfig.retryDelay * attempts),
          );
        }
      } catch (e) {
        lastException = AppException(
          'Error sending text to Hugging Face: $e',
        );
        // Exponential backoff
        if (attempts < retries) {
          await Future.delayed(
            Duration(seconds: ApiConfig.retryDelay * attempts),
          );
        }
      }
    }

    // All retries failed
    throw lastException;
  }

  // Add method for HTTP GET requests with retry
  Future<dynamic> get(
    String url, {
    Map<String, String>? headers,
    int retries = ApiConfig.defaultRetries,
  }) async {
    int attempts = 0;
    late Exception lastException;

    while (attempts < retries) {
      try {
        attempts++;

        final response = await _client
            .get(
              Uri.parse(url),
              headers: headers,
            )
            .timeout(const Duration(seconds: ApiConfig.defaultTimeout));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        } else {
          throw AppException(
            'GET request failed: ${response.body}',
            code: response.statusCode.toString(),
          );
        }
      } on AppException catch (e) {
        lastException = e;
        if (attempts < retries) {
          await Future.delayed(
            Duration(seconds: ApiConfig.retryDelay * attempts),
          );
        }
      } catch (e) {
        lastException = AppException('Error in GET request: $e');
        if (attempts < retries) {
          await Future.delayed(
            Duration(seconds: ApiConfig.retryDelay * attempts),
          );
        }
      }
    }

    // All retries failed
    throw lastException;
  }
}
