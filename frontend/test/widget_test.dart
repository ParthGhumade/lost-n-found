import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('App smoke test loads LoginPage', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    expect(find.text('Campus Lost & Found'), findsOneWidget);
    expect(find.text('Quick Test Login (test / test@123)'), findsOneWidget);
  });
}
