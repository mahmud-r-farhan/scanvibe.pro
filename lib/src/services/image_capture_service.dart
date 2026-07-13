import 'package:image_picker/image_picker.dart';

enum ImageSourceKind { camera, gallery }

class CapturedImage {
  const CapturedImage({required this.path});

  final String path;
}

class ImageCaptureService {
  ImageCaptureService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<CapturedImage?> pick(ImageSourceKind source) async {
    final image = await _picker.pickImage(
      source: source == ImageSourceKind.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (image == null) {
      return null;
    }
    return CapturedImage(path: image.path);
  }
}
