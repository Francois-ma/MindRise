import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindrise_mobile/core/widgets/mr_button.dart';

void main() {
  testWidgets('primary action button renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MRButton(label: 'Sign In', icon: Icons.login_rounded),
        ),
      ),
    );

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
  });
}
