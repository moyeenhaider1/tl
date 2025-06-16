import 'package:camera/camera.dart';

abstract class StorageInterface {
  /// Uploads an image file and returns the public URL
  Future<String> uploadImage(XFile imageFile, String userId);

  /// Deletes an image by its URL
  Future<void> deleteImage(String imageUrl);

  /// Gets the storage provider name
  String get providerName;
}
