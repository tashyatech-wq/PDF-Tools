import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_toolkit/main.dart';

void main() {
  testWidgets('App launches to the Merge tab with all four tools in the nav bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PdfToolkitApp());

    expect(find.text('Merge PDF'), findsOneWidget);
    expect(find.text('Add PDFs'), findsOneWidget);

    for (final label in const ['Merge', 'Split', 'Compress', 'Unlock']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
