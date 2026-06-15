import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crop_doctor/main.dart';
import 'package:crop_doctor/providers.dart';

void main() {
  testWidgets('Crop Doctor App Smoke Test', (WidgetTester tester) async {
    // Initialize SharedPreferences with mock values for onboarding
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': false,
    });

    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const CropDoctorApp(),
      ),
    );

    // Verify Onboarding Screen title loaded correctly
    expect(find.textContaining('Welcome to Crop Doctor'), findsOneWidget);
  });
}
