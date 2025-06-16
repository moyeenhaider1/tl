import 'dart:io';

abstract class StorageInterface {
  /// Uploads an image file and returns the public URL
  Future<String> uploadImage(File imageFile, String userId);

  /// Deletes an image by its URL
  Future<void> deleteImage(String imageUrl);

  /// Gets the storage provider name
  String get providerName;
}
