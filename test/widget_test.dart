import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sms_auth_passenger_app/main.dart';
import 'package:sms_auth_passenger_app/screens/splash_screen.dart';

void main() {
  setUpAll(() {
    // Mock dotenv variables for testing
    dotenv.loadFromString(envString: 'SUPABASE_ANON_KEY=test_key');
  });

  testWidgets('App renders splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our SplashScreen is rendered.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pump and settle to let any timers/animations finish.
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });
}
