import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chez_mama/auth/auth_service.dart';
import 'package:chez_mama/api/api_config.dart';
import 'package:chez_mama/main.dart';
import 'package:chez_mama/providers/auth_provider.dart';

void main() {
  testWidgets('App boots (smoke test)', (WidgetTester tester) async {
    ApiConfig.overrideBaseUrl = 'http://127.0.0.1:8000';
    await ApiConfig.init();
    final auth = AuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: const ChezMamaApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
