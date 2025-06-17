import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // Hugging Face API
  static const String huggingFaceBaseUrl =
      'https://api-inference.huggingface.co'; // Removed trailing slash

  // Get API key from environment variables
  static String get huggingFaceApiKey =>
      dotenv.env['HUGGINGFACE_API_KEY'] ?? 'YOUR_HUGGINGFACE_API_KEY';

  // Model endpoints
  static const String objectDetectionModel = 'facebook/detr-resnet-50';
  // Use a more reliable OCR model that's widely available
  static const String ocrModel = 'microsoft/trocr-base-printed';
  // Fallback OCR models in case the primary one fails - using more reliable models
  static const List<String> ocrFallbackModels = [
    'microsoft/trocr-base-printed',
    'microsoft/trocr-large-printed', // Larger version, may be slower but more accurate
    'microsoft/trocr-base-stage1', // Stage 1 model
    'microsoft/trocr-base-handwritten', // Handwritten version as last resort
  ];
  static const String translationModel = 'Helsinki-NLP/opus-mt-en-ROMANCE';
  static const String summarizationModel = 'facebook/bart-large-cnn';

  // Wikipedia API
  static const String wikipediaBaseUrl = 'https://en.wikipedia.org/api/rest_v1';

  // Request parameters
  static const int defaultTimeout = 45; // seconds - increased for slow models
  static const int defaultRetries = 3;
  static const int retryDelay = 2; // seconds
}
