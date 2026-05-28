import 'dart:io';
import 'package:file_selector/file_selector.dart';
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

  static const _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'heic',
    'bmp',
  ];

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

  bool _hasExtension(String path, List<String> exts) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return exts.contains(ext);
  }

  Future<PickedMedia?> pickPhotoFromGallery() async {
    if (isDesktopPlatform) {
      final file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'Images', extensions: _imageExtensions),
        ],
      );
      if (file == null) return null;
      if (!await File(file.path).exists()) {
        throw StateError('Le fichier sélectionné est introuvable.');
      }
      return PickedMedia(path: file.path, isVideo: false);
    }

    final x = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (x == null) return null;
    return PickedMedia(path: x.path, isVideo: false);
  }

  Future<PickedMedia?> pickVideoFromGallery() async {
    if (isDesktopPlatform) {
      final file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'Vidéos', extensions: _videoExtensions),
        ],
      );
      if (file == null) return null;
      if (!_hasExtension(file.path, _videoExtensions)) {
        throw const FormatException(
          'Format vidéo non supporté. Utilise mp4, mov, mkv, webm…',
        );
      }
      if (!await File(file.path).exists()) {
        throw StateError('Le fichier sélectionné est introuvable.');
      }
      return PickedMedia(path: file.path, isVideo: true);
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
