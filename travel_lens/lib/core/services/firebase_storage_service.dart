import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/interfaces/storage_interface.dart';
import 'package:uuid/uuid.dart';

class FirebaseStorageService implements StorageInterface {
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  String get providerName => 'Firebase Storage';

  @override
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Log current user and timestamp for Firebase Storage
      debugPrint(
          '[$providerName] Starting upload for user: moyeenhaider1 at 2025-06-15 07:00:23 UTC');
      debugPrint('[$providerName] Target user folder: $userId');

      // Create a unique filename
      final String fileExtension = path.extension(imageFile.path);
      final String fileName = 'travel_lens_${_uuid.v4()}$fileExtension';
      final String filePath = 'images/$userId/$fileName';

      // Compress image before upload
      final File compressedFile = await _compressImage(imageFile);

      // Create the storage reference
      final ref = _storage.ref().child(filePath);

      // Upload file
      final uploadTask = ref.putFile(
        compressedFile,
        SettableMetadata(contentType: 'image/${fileExtension.substring(1)}'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up compressed file if different from original
      if (compressedFile.path != imageFile.path) {
        await compressedFile.delete();
      }

      debugPrint('[$providerName] Upload successful: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('[$providerName] Upload error: $e');
      throw AppException('Failed to upload image to $providerName: $e');
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      debugPrint(
          '[$providerName] Deleting image: $imageUrl at 2025-06-15 07:00:23 UTC');

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();

      debugPrint('[$providerName] Delete successful');
    } catch (e) {
      debugPrint('[$providerName] Delete error: $e');
      throw AppException('Failed to delete image from $providerName: $e');
    }
  }

  /// Compresses an image to reduce storage usage
  Future<File> _compressImage(File imageFile) async {
    try {
      // Read the file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return imageFile; // Return original if decoding fails
      }

      // Get original dimensions
      final width = image.width;
      final height = image.height;

      // Calculate new dimensions (maintaining aspect ratio)
      int targetWidth = width;
      int targetHeight = height;

      // Only resize if larger than 1200px on any dimension
      if (width > 1200 || height > 1200) {
        if (width > height) {
          targetWidth = 1200;
          targetHeight = (height * (1200 / width)).round();
        } else {
          targetHeight = 1200;
          targetWidth = (width * (1200 / height)).round();
        }
      }

      // Resize image
      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
      );

      // Compress with quality 85%
      final compressed = img.encodeJpg(resized, quality: 85);

      // Create a temp file for the compressed image
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/compressed_image.jpg');

      // Write compressed data to file
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      debugPrint('[$providerName] Image compression failed: $e');
      // Return original if compression fails
      return imageFile;
    }
  }
}
