import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/data/models/detection_result.dart';
import 'package:travel_lens/features/detection/object_detection_service.dart';
import 'package:travel_lens/features/information/wikipedia_service.dart';
import 'package:travel_lens/features/ocr/ocr_service.dart';
import 'package:travel_lens/features/translation/translation_service.dart';

enum ProcessingStatus {
  idle,
  detecting,
  extracting,
  translating,
  summarizing,
  completed,
  error
}

class DetectionProvider extends ChangeNotifier {
  // Services
  final ObjectDetectionService _objectDetectionService;
  final OcrService _ocrService;
  final TranslationService _translationService;
  final WikipediaService _wikipediaService;

  // State variables
  File? _capturedImage;
  String? _detectedObject;
  List<DetectedObject>? _detectedObjects;
  String? _extractedText;
  String? _translatedText;
  String? _summary;
  String? _errorMessage;
  ProcessingStatus _status = ProcessingStatus.idle;
  double _progressValue = 0.0;

  // Getters
  File? get capturedImage => _capturedImage;
  String? get detectedObject => _detectedObject;
  List<DetectedObject>? get detectedObjects => _detectedObjects;
  String? get extractedText => _extractedText;
  String? get translatedText => _translatedText;
  String? get summary => _summary;
  String? get errorMessage => _errorMessage;
  ProcessingStatus get status => _status;
  double get progressValue => _progressValue;
  bool get isProcessing =>
      _status != ProcessingStatus.idle &&
      _status != ProcessingStatus.completed &&
      _status != ProcessingStatus.error;

  DetectionProvider({
    ObjectDetectionService? objectDetectionService,
    OcrService? ocrService,
    TranslationService? translationService,
    WikipediaService? wikipediaService,
  })  : _objectDetectionService =
            objectDetectionService ?? ObjectDetectionService(),
        _ocrService = ocrService ?? OcrService(),
        _translationService = translationService ?? TranslationService(),
        _wikipediaService = wikipediaService ?? WikipediaService();

  Future<void> processImage(File image, {String targetLanguage = 'en'}) async {
    try {
      _reset();
      _capturedImage = image;
      notifyListeners();

      // Step 1: Object Detection
      await _detectObjects();

      // Step 2: OCR
      await _extractText();

      // Step 3: Translation (if needed)
      if (_extractedText != null && _extractedText!.isNotEmpty) {
        await _translateText(targetLanguage);
      }

      // Step 4: Get additional information about detected object
      if (_detectedObject != null) {
        await _getObjectInformation();
      }

      _status = ProcessingStatus.completed;
      _progressValue = 1.0;
      notifyListeners();
    } on AppException catch (e) {
      _handleError(e.message);
    } catch (e) {
      _handleError('An unexpected error occurred: $e');
    }
  }

  Future<void> _detectObjects() async {
    try {
      _status = ProcessingStatus.detecting;
      _progressValue = 0.25;
      notifyListeners();

      _detectedObjects =
          await _objectDetectionService.detectObjects(_capturedImage!);

      if (_detectedObjects != null && _detectedObjects!.isNotEmpty) {
        // Sort by confidence score
        _detectedObjects!.sort((a, b) => b.score.compareTo(a.score));

        // Take the highest confidence object as the main detected object
        _detectedObject = _detectedObjects!.first.label;
      } else {
        _detectedObject = 'Unknown object';
      }
    } catch (e) {
      throw AppException('Failed to detect objects: $e');
    }
  }

  Future<void> _extractText() async {
    try {
      _status = ProcessingStatus.extracting;
      _progressValue = 0.5;
      notifyListeners();

      final extractedText = await _ocrService.extractText(_capturedImage!);
      _extractedText = extractedText.trim().isNotEmpty ? extractedText : null;
    } catch (e) {
      throw AppException('Failed to extract text: $e');
    }
  }

  Future<void> _translateText(String targetLanguage) async {
    try {
      _status = ProcessingStatus.translating;
      _progressValue = 0.75;
      notifyListeners();

      // Auto-detect source language or use a default
      const sourceLanguage = 'auto';

      _translatedText = await _translationService.translate(
        text: _extractedText!,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    } catch (e) {
      // Don't throw here, just make translation null
      _translatedText = null;
      debugPrint('Translation failed: $e');
    }
  }

  Future<void> _getObjectInformation() async {
    try {
      _status = ProcessingStatus.summarizing;
      _progressValue = 0.9;
      notifyListeners();

      _summary = await _wikipediaService.getInformation(_detectedObject!);
    } catch (e) {
      // Don't throw here, just make summary null
      _summary = null;
      debugPrint('Information retrieval failed: $e');
    }
  }

  void _handleError(String message) {
    _status = ProcessingStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _reset() {
    _detectedObjects = null;
    _detectedObject = null;
    _extractedText = null;
    _translatedText = null;
    _summary = null;
    _errorMessage = null;
    _status = ProcessingStatus.idle;
    _progressValue = 0.0;
  }

  void resetResults() {
    _reset();
    _capturedImage = null;
    notifyListeners();
  }

  void retryProcessing({String targetLanguage = 'en'}) {
    if (_capturedImage != null) {
      processImage(_capturedImage!, targetLanguage: targetLanguage);
    }
  }
}
