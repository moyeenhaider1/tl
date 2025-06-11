class ApiConfig {
  // Hugging Face API
  static const String huggingFaceBaseUrl =
      'https://api-inference.huggingface.co/models';

  // This should be stored securely - for demonstration purposes only
  static const String huggingFaceApiKey = 'YOUR_HUGGING_FACE_API_KEY';

  // Model endpoints
  static const String objectDetectionModel = 'facebook/detr-resnet-50';
  static const String ocrModel = 'microsoft/trocr-base-printed';
  static const String translationModel = 'Helsinki-NLP/opus-mt-en-ROMANCE';
  static const String summarizationModel = 'facebook/bart-large-cnn';
  static const String questionAnsweringModel = 'deepset/roberta-base-squad2';

  // Wikipedia API
  static const String wikipediaBaseUrl = 'https://en.wikipedia.org/api/rest_v1';
}
