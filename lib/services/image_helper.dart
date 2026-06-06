import 'dart:convert';

import 'package:image_picker/image_picker.dart';

/// Helper around image_picker. For Assignment 4 we only need the Photo Gallery
/// mode (the iOS simulator can't use the camera), so this just picks one image
/// from the gallery and hands it back as a base64 string that we store inline
/// in Firestore.
class ImageHelper {
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and returns it as base64, or null if the
  /// user backed out. The image is shrunk a bit so the base64 string stays well
  /// under the 1MB Firestore document limit.
  Future<String?> pickFromGalleryAsBase64() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 70,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }
}

