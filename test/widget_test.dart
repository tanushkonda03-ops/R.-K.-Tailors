// Basic smoke test for the Tailor app.

import 'package:flutter_test/flutter_test.dart';

import 'package:tailor/main.dart';

void main() {
  testWidgets('Language selection screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const TailorApp());
    
    // Pump frames to let the entrance animations run
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that language options are displayed
    expect(find.text('Choose Your Language'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
  });
}
