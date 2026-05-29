import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
}

bool get isMobilePlatform {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

/// Inline [video_player] works on Android, iOS, macOS and web — not Linux/Windows.
bool get supportsInlineVideo {
  if (kIsWeb) return true;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}
