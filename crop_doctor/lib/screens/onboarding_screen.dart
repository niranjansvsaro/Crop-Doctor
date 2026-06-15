import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../providers.dart';
import '../services/translate_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _cameraGranted = false;
  bool _locationGranted = false;

  final List<String> _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Kannada',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;
    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _locationGranted = locationStatus.isGranted;
    });
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() => _cameraGranted = status.isGranted);
  }

  Future<void> _requestLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      try {
        await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
      } catch (_) {}
    }
    setState(() => _locationGranted = status.isGranted);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(farmerNameProvider.notifier)
        .setName(_nameController.text.trim());
    await ref
        .read(farmerPhoneProvider.notifier)
        .setPhone(_phoneController.text.trim());

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  InputDecoration _fieldDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF66BB6A)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      );

  Widget _buildCard({required Widget child}) => Card(
        color: Colors.white.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        child: Padding(padding: const EdgeInsets.all(16.0), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B5E20), Color(0xFF121212)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 30),

                  // App Branding
                  Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Text(
                        'Crop Doctor 🌿',
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF66BB6A),
                          shadows: const [
                            Shadow(color: Color(0xFF2E7D32), blurRadius: 15),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    TranslateService.get(
                        'onboarding_subtitle', selectedLanguage),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // ── Language Card ───────────────────────────────────────
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslateService.get(
                              'select_language', selectedLanguage),
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _languages.map((lang) {
                            final isSelected = selectedLanguage == lang;
                            return ChoiceChip(
                              label: Text(
                                lang,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFF66BB6A),
                              backgroundColor: Colors.white.withAlpha(20),
                              onSelected: (selected) {
                                if (selected) {
                                  ref
                                      .read(languageProvider.notifier)
                                      .setLanguage(lang);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Profile Card ────────────────────────────────────────
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farmer Profile',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: _fieldDecoration(TranslateService.get(
                              'enter_name', selectedLanguage)),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.phone,
                          decoration: _fieldDecoration(TranslateService.get(
                              'enter_phone', selectedLanguage)),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Phone number is required'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Permissions Card ────────────────────────────────────
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Required Permissions',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          leading: Icon(Icons.camera_alt,
                              color: _cameraGranted
                                  ? const Color(0xFF66BB6A)
                                  : Colors.grey),
                          title: Text(
                            TranslateService.get(
                                'camera_permission', selectedLanguage),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          trailing: _cameraGranted
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF66BB6A))
                              : TextButton(
                                  onPressed: _requestCamera,
                                  child: const Text('Allow',
                                      style: TextStyle(
                                          color: Color(0xFF66BB6A)))),
                        ),
                        ListTile(
                          leading: Icon(Icons.location_on,
                              color: _locationGranted
                                  ? const Color(0xFF66BB6A)
                                  : Colors.grey),
                          title: Text(
                            TranslateService.get(
                                'location_permission', selectedLanguage),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          trailing: _locationGranted
                              ? const Icon(Icons.check_circle,
                                  color: Color(0xFF66BB6A))
                              : TextButton(
                                  onPressed: _requestLocation,
                                  child: const Text('Allow',
                                      style: TextStyle(
                                          color: Color(0xFF66BB6A)))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Get Started ─────────────────────────────────────────
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      shadowColor:
                          const Color(0xFF66BB6A).withAlpha(100),
                      elevation: 8,
                    ),
                    child: Text(
                      TranslateService.get(
                          'get_started', selectedLanguage),
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
