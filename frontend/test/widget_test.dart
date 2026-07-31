import 'package:flutter_test/flutter_test.dart';

import 'package:student_tracking_app/main.dart';

void main() {
  testWidgets('shows the login screen when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentTrackingApp());
    await tester.pumpAndSettle();

    expect(find.text('Student Tracking App'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}
