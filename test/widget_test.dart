import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:art_generator/main.dart';

void main() {
  testWidgets('Art Generator initial UI test', (WidgetTester tester) async {
    // Build the Art Generator app and trigger a frame.
    await tester.pumpWidget(ArtGeneratorApp());

    // Verify that the initial UI elements are present.
    expect(find.text('AI Art Generator'), findsOneWidget);
    expect(find.text('Enter a description for the artwork'), findsOneWidget);
    expect(find.text('Generate Artwork'), findsOneWidget);

    // Verify no artwork is displayed initially.
    expect(find.byType(Image), findsNothing);
  });
}
