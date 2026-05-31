import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chez_mama/widgets/empty_state_view.dart';

void main() {
  testWidgets('EmptyStateView shows title and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            title: 'Empty',
            subtitle: 'Nothing here',
            actionLabel: 'Retry',
            onAction: () => tapped = true,
            wrapInCard: false,
          ),
        ),
      ),
    );

    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });
}
