import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke — MaterialApp monta', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('AQUANAUTIX')),
        ),
      ),
    );
    expect(find.text('AQUANAUTIX'), findsOneWidget);
  });
}
