import 'dart:convert';
import 'dart:io';
import 'dart:math';

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

        final url = '${ApiConfig.huggingFaceBaseUrl}/$modelEndpoint';

        // Read image file as bytes
        final bytes = await imageFile.readAsBytes();

        // Determine content type based on file extension
        final contentType = _getContentTypeFromFile(imageFile);

        // Prepare headers
        final headers = {
          'Authorization': 'Bearer ${ApiConfig.huggingFaceApiKey}',
          'Content-Type': contentType,
        };

        // Send request
        final response = await _client
            .post(
              Uri.parse(url),
              headers: headers,
              body: bytes,
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
