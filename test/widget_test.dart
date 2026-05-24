import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swarnakar_admin/widgets/section_card.dart';

void main() {
  testWidgets('SectionCard renders title and child',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SectionCard(title: 'Test Title', child: Text('Body')),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });
}
