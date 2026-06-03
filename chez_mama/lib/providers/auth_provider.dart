import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';

/// Riverpod bridge over the existing [AuthService] (ChangeNotifier).
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('Override in main() with ProviderScope');
});

final authReadyProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).ready;
});

final isAuthedProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isAuthed;
});

final isSellerProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isSeller;
});

/// Bottom-nav tab index for [AppShell] (Riverpod-managed shell state).
final shellTabIndexProvider = StateProvider<int>((ref) => 0);
