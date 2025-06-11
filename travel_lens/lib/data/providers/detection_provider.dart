import 'dart:io';
import 'package:flutter/foundation.dart';

class DetectionProvider extends ChangeNotifier {
  bool _isProcessing = false;
  String? _detectedObject;
  String? _extractedText;
  String? _translatedText;
  String? _summary;
  File? _capturedImage;
  
  bool get isProcessing => _isProcessing;
  String? get detectedObject => _detectedObject;
  String? get extractedText => _extractedText;
  String? get translatedText => _translatedText;
  String? get summary => _summary;
  File? get capturedImage => _capturedImage;
  
  Future<void> processImage(File imageFile) async {
    try {
      _isProcessing = true;
      _capturedImage = imageFile;
      notifyListeners();
      
      // Mock image processing sequence - will replace with actual API calls
      await Future.delayed(const Duration(seconds: 1));
      _detectedObject = "Eiffel Tower";
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 1));
      _extractedText = "Tour Eiffel - Construite en 1889";
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 1));
      _translatedText = "Eiffel Tower - Built in 1889";
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 1));
      _summary = "The Eiffel Tower is a wrought-iron lattice tower on the Champ de Mars in Paris. It is named after Gustave Eiffel, whose company designed and built the tower for the 1889 World's Fair.";
      notifyListeners();
      
    } catch (e) {
      // Handle errors
      _detectedObject = null;
      _extractedText = null;
      _translatedText = null;
      _summary = null;
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }
  
  void reset() {
    _isProcessing = false;
    _detectedObject = null;
    _extractedText = null;
    _translatedText = null;
    _summary = null;
    _capturedImage = null;
    notifyListeners();
  }
}