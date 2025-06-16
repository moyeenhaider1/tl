import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  Future<String> uploadImage(XFile imageFile, String userId) async {
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
      final XFile xCompressedFile = await _compressImage(imageFile);
      final File compressedFile = File(xCompressedFile.path);

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
  Future<XFile> _compressImage(XFile imageFile) async {
    final dir = await Directory.systemTemp.createTemp('travellens');
    final targetPath = '${dir.path}/${_uuid.v4()}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      quality: 85, // Adjust quality (1–100)
      minWidth: 1200,
      minHeight: 1200,
      keepExif: true,
      format: CompressFormat.jpeg,
    );

    if (result != null) return result;
    return imageFile; // Fallback if compression fails
  }
}
