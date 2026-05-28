import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'platform_utils.dart';

class PickedMedia {
  const PickedMedia({
    required this.path,
    required this.isVideo,
  });

  final String path;
  final bool isVideo;
}

class AppMediaPicker {
  AppMediaPicker._();
  static final AppMediaPicker instance = AppMediaPicker._();

  final ImagePicker _imagePicker = ImagePicker();

  Future<PickedMedia?> pickPhotoFromGallery() async {
    if (isDesktopPlatform) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final file = result?.files.single;
      if (file?.path == null) return null;
      return PickedMedia(path: file!.path!, isVideo: false);
    }

    final x = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (x == null) return null;
    return PickedMedia(path: x.path, isVideo: false);
  }

  Future<PickedMedia?> pickVideoFromGallery() async {
    if (isDesktopPlatform) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      final file = result?.files.single;
      if (file?.path == null) return null;
      return PickedMedia(path: file!.path!, isVideo: true);
    }

    final x = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (x == null) return null;
    return PickedMedia(path: x.path, isVideo: true);
  }

  Future<PickedMedia?> capturePhoto() async {
    if (isDesktopPlatform) {
      return null;
    }
    final x = await _imagePicker.pickImage(source: ImageSource.camera);
    if (x == null) return null;
    return PickedMedia(path: x.path, isVideo: false);
  }

  Future<PickedMedia?> captureVideo() async {
    if (isDesktopPlatform) {
      return null;
    }
    final x = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (x == null) return null;
    return PickedMedia(path: x.path, isVideo: true);
  }

  String? desktopCaptureHint() {
    if (!isDesktopPlatform) return null;
    return 'Sur ordinateur Linux, utilise la galerie (fichiers). '
        'La caméra directe est disponible sur téléphone.';
  }
}
