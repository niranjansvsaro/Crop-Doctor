import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter engine services are bound
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Supabase if URL and Keys are passed via --dart-define compiler options
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');

  if (supabaseUrl.isNotEmpty && supabaseUrl.startsWith('http')) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
      debugPrint("Supabase successfully initialized.");
    } catch (e) {
      debugPrint("Supabase initialization failed: $e");
    }
  } else {
    debugPrint("Supabase credentials not configured. App running in offline-first mode.");
  }

  // Load local preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CropDoctorApp(),
    ),
  );
}

class CropDoctorApp extends ConsumerWidget {
  const CropDoctorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    return MaterialApp(
      title: 'Crop Doctor 🌿',
      debugShowCheckedModeBanner: false,
      // Premium Futuristic Agriculture Theme (Dark mode by default)
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF66BB6A), // Emerald/Leaf Green
          secondary: Color(0xFF2E7D32), // Dark Green
          surface: Color(0xFF1E1E1E),
          error: Color(0xFFEF5350),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withAlpha(15),
          selectedColor: const Color(0xFF66BB6A),
          side: BorderSide(color: Colors.white.withAlpha(20)),
          labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
      ),
      home: onboardingCompleted ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
