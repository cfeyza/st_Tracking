import 'package:flutter_test/flutter_test.dart';

import 'package:student_tracking_app/main.dart';

void main() {
  testWidgets('shows the login screen when logged out', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentTrackingApp());
    await tester.pumpAndSettle();

    expect(find.text('Öğrenci Takip Uygulaması'), findsOneWidget);
    expect(find.text('Giriş yap'), findsOneWidget);
    expect(find.text('Hesabınız yok mu? Kayıt olun'), findsOneWidget);
  });
}
