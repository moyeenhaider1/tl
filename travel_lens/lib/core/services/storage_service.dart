import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:travel_lens/core/interfaces/storage_interface.dart';
import 'package:travel_lens/core/services/cloudinary_storage_service.dart';
import 'package:travel_lens/core/services/firebase_storage_service.dart';

enum StorageProvider { firebase, cloudinary }

class StorageService {
  static StorageInterface? _instance;
  static StorageProvider? _currentProvider;

  /// Get the current storage provider instance
  static StorageInterface get instance {
    if (_instance == null) {
      _initializeFromEnvironment();
    }
    return _instance!;
  }

  /// Initialize storage provider based on environment variables
  static void _initializeFromEnvironment() {
    final useFirebase =
        dotenv.env['USE_FIREBASE_STORAGE']?.toLowerCase() == 'true';
    final useCloudinary =
        dotenv.env['USE_CLOUDINARY_STORAGE']?.toLowerCase() == 'true';

    debugPrint('=== Storage Provider Selection ===');
    debugPrint('Current user: moyeenhaider1');
    debugPrint('Current time: 2025-06-15 07:00:23 UTC');
    debugPrint('USE_FIREBASE_STORAGE: $useFirebase');
    debugPrint('USE_CLOUDINARY_STORAGE: $useCloudinary');

    if (useFirebase && useCloudinary) {
      debugPrint('⚠️  Both providers enabled, defaulting to Cloudinary');
      setProvider(StorageProvider.cloudinary);
    } else if (useFirebase) {
      debugPrint('✅ Using Firebase Storage');
      setProvider(StorageProvider.firebase);
    } else if (useCloudinary) {
      debugPrint('✅ Using Cloudinary');
      setProvider(StorageProvider.cloudinary);
    } else {
      debugPrint('⚠️  No provider specified, defaulting to Firebase Storage');
      setProvider(StorageProvider.firebase);
    }

    debugPrint('Active provider: ${_instance!.providerName}');
    debugPrint('================================');
  }

  /// Set storage provider programmatically
  static void setProvider(StorageProvider provider) {
    debugPrint(
        'Switching storage provider to: $provider for user: moyeenhaider3 at 2025-06-15 07:00:23 UTC');

    switch (provider) {
      case StorageProvider.firebase:
        _instance = FirebaseStorageService();
        _currentProvider = StorageProvider.firebase;
        break;
      case StorageProvider.cloudinary:
        _instance = CloudinaryStorageService();
        _currentProvider = StorageProvider.cloudinary;
        break;
    }

    debugPrint('Storage provider switched to: ${_instance!.providerName}');
  }

  /// Get current provider type
  static StorageProvider get currentProvider {
    if (_currentProvider == null) {
      _initializeFromEnvironment();
    }
    return _currentProvider!;
  }

  /// Upload an image and return the public URL
  Future<String> uploadImage(XFile imageFile, String userId) async {
    try {
      debugPrint(
          'Uploading image for user: $userId (current: moyeenhaider1) at 2025-06-15 07:00:23 UTC');
      debugPrint('Using provider: ${instance.providerName}');
      return await instance.uploadImage(imageFile, userId);
    } catch (e) {
      debugPrint('Storage service upload failed: $e');
      rethrow;
    }
  }

  /// Delete an image by URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      debugPrint('Deleting image: $imageUrl at 2025-06-15 07:00:23 UTC');
      debugPrint('Using provider: ${instance.providerName}');
      await instance.deleteImage(imageUrl);
    } catch (e) {
      debugPrint('Storage service delete failed: $e');
      rethrow;
    }
  }

  /// Get current provider name
  String get providerName => instance.providerName;

  /// Check if using Firebase Storage
  static bool get isUsingFirebase =>
      currentProvider == StorageProvider.firebase;

  /// Check if using Cloudinary
  static bool get isUsingCloudinary =>
      currentProvider == StorageProvider.cloudinary;

  /// Switch to Firebase Storage
  static void switchToFirebase() {
    setProvider(StorageProvider.firebase);
  }

  /// Switch to Cloudinary
  static void switchToCloudinary() {
    setProvider(StorageProvider.cloudinary);
  }

  /// Get provider statistics
  static Map<String, dynamic> getProviderInfo() {
    return {
      'current_provider': instance.providerName,
      'provider_type': currentProvider.toString(),
      'user': 'moyeenhaider3',
      'timestamp': '2025-06-15 07:00:23 UTC',
      'firebase_enabled':
          dotenv.env['USE_FIREBASE_STORAGE']?.toLowerCase() == 'true',
      'cloudinary_enabled':
          dotenv.env['USE_CLOUDINARY_STORAGE']?.toLowerCase() == 'true',
    };
  }
}
