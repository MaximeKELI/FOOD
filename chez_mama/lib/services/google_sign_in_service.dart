import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In wrapper. Requires `--dart-define=GOOGLE_WEB_CLIENT_ID=...`
/// (OAuth 2.0 Web client ID from Google Cloud Console).
class GoogleSignInService {
  GoogleSignInService._();

  static const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static bool get isConfigured => webClientId.isNotEmpty;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: webClientId.isEmpty ? null : webClientId,
    scopes: const ['email', 'profile'],
  );

  static Future<String?> signInAndGetIdToken() async {
    if (!isConfigured) return null;
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<void> signOut() async {
    if (!isConfigured) return;
    await _googleSignIn.signOut();
  }
}
