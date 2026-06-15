import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers.dart';
import '../services/translate_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(farmerNameProvider);
    _phoneController.text = ref.read(farmerPhoneProvider);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and phone cannot be empty")),
      );
      return;
    }

    await ref.read(farmerNameProvider.notifier).setName(name);
    await ref.read(farmerPhoneProvider.notifier).setPhone(phone);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    }
  }

  void _showLanguageSelector(BuildContext context, String currentLang) {
    final languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Kannada'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF222222),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Switch Language",
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...languages.map((lang) {
                final isSelected = currentLang == lang;
                return ListTile(
                  title: Text(lang, style: const TextStyle(color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF66BB6A)) : null,
                  onTap: () {
                    ref.read(languageProvider.notifier).setLanguage(lang);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _clearDatabaseHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Text("Clear Scan History", style: TextStyle(color: Colors.white)),
        content: const Text("This will permanently erase all local scans. This action cannot be undone.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Clear All", style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              ref.read(historyProvider.notifier).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scan history cleared")),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Details Card
          Card(
            color: Colors.white.withAlpha(15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withAlpha(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Edit Farmer Profile",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: TranslateService.get('enter_name', language),
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(50))),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF66BB6A))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: TranslateService.get('enter_phone', language),
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(50))),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF66BB6A))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Save Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Setting Controls Card
          Card(
            color: Colors.white.withAlpha(15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withAlpha(20)),
            ),
            child: Column(
              children: [
                // Language tile
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.blueAccent),
                  title: Text(
                    TranslateService.get('select_language', language),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(language, style: const TextStyle(color: Colors.white70)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                  onTap: () => _showLanguageSelector(context, language),
                ),
                Divider(color: Colors.white.withAlpha(20), height: 1),

                // Notifications switch
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active, color: Colors.amberAccent),
                  title: const Text("Outbreak Notifications", style: TextStyle(color: Colors.white)),
                  value: _notificationsEnabled,
                  activeThumbColor: const Color(0xFF66BB6A),
                  onChanged: (val) {
                    setState(() {
                      _notificationsEnabled = val;
                    });
                  },
                ),
                Divider(color: Colors.white.withAlpha(20), height: 1),

                // Feedback button
                ListTile(
                  leading: const Icon(Icons.feedback_outlined, color: Colors.purpleAccent),
                  title: const Text("Send App Feedback", style: TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                  onTap: () {
                    // Feedback text field dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF222222),
                        title: const Text("Submit Feedback", style: TextStyle(color: Colors.white)),
                        content: const TextField(
                          style: TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Tell us how to improve...",
                            hintStyle: TextStyle(color: Colors.white38),
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
                            onPressed: () => Navigator.pop(context),
                          ),
                          TextButton(
                            child: const Text("Submit", style: TextStyle(color: Color(0xFF66BB6A))),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Thank you for your feedback!")),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Database Controls Card
          Card(
            color: Colors.white.withAlpha(15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withAlpha(20)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              title: const Text("Clear Local Cache", style: TextStyle(color: Colors.redAccent)),
              subtitle: const Text("Remove all diagnostic records", style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: _clearDatabaseHistory,
            ),
          ),
        ],
      ),
    );
  }
}
