// Basic smoke test for LMS app.

import 'package:flutter_test/flutter_test.dart';
import 'package:lms_app/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const LmsApp());
    expect(find.text('LMS App'), findsOneWidget);
  });
}
