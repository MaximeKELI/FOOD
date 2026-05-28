import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
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

  static const _videoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
    'mpeg',
    'mpg',
    '3gp',
    'wmv',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  bool _isVideoPath(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return _videoExtensions.contains(ext);
  }

  Future<PickedMedia?> pickPhotoFromGallery() async {
    if (isDesktopPlatform) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'],
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null) return null;
      return PickedMedia(path: path, isVideo: false);
    }

    final x = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (x == null) return null;
    return PickedMedia(path: x.path, isVideo: false);
  }

  Future<PickedMedia?> pickVideoFromGallery() async {
    if (isDesktopPlatform) {
      // FileType.video is often too strict on Linux GTK — try custom then any.
      var result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _videoExtensions,
        allowMultiple: false,
        dialogTitle: 'Choisir une vidéo',
      );
      if (result == null || result.files.isEmpty) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          dialogTitle: 'Choisir une vidéo',
        );
      }
      final path = result?.files.single.path;
      if (path == null) return null;

      if (!_isVideoPath(path)) {
        throw FormatException(
          'Format non supporté. Utilise: ${_videoExtensions.join(', ')}',
        );
      }

      final file = File(path);
      if (!await file.exists()) {
        throw StateError('Le fichier sélectionné est introuvable.');
      }

      return PickedMedia(path: path, isVideo: true);
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
    return 'Sur ordinateur, choisis une vidéo via « Vidéo (galerie) ». '
        'La caméra directe est disponible sur téléphone.';
  }
}
