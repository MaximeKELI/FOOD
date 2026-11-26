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

/// Inline [video_player] works on Android / iOS / macOS / web.
///
/// Linux: media_kit/libmpv crashes the process (`m_config_cache_from_shadow`)
/// when creating EGL video outputs — keep false and use external playback.
/// Windows: media_kit is OK when libs are present.
bool get supportsInlineVideo {
  if (kIsWeb) return true;
  if (Platform.isLinux) return false;
  return Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows;
}
