import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/api_service.dart';
import 'services/supabase_service.dart';
import 'services/translate_service.dart';
import 'models/scan_result.dart';

// SharedPreferences provider (overridden in main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// App Language state provider
final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});

class LanguageNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  LanguageNotifier(this._prefs) : super(_prefs.getString('selected_language') ?? 'English');

  Future<void> setLanguage(String lang) async {
    await _prefs.setString('selected_language', lang);
    state = lang;
  }
}

// Farmer Name state provider
final farmerNameProvider = StateNotifierProvider<FarmerNameNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FarmerNameNotifier(prefs);
});

class FarmerNameNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  FarmerNameNotifier(this._prefs) : super(_prefs.getString('farmer_name') ?? '');

  Future<void> setName(String name) async {
    await _prefs.setString('farmer_name', name);
    state = name;
  }
}

// Farmer Phone state provider
final farmerPhoneProvider = StateNotifierProvider<FarmerPhoneNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FarmerPhoneNotifier(prefs);
});

class FarmerPhoneNotifier extends StateNotifier<String> {
  final SharedPreferences _prefs;

  FarmerPhoneNotifier(this._prefs) : super(_prefs.getString('farmer_phone') ?? '');

  Future<void> setPhone(String phone) async {
    await _prefs.setString('farmer_phone', phone);
    state = phone;
  }
}

// Service Providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final translateServiceProvider = Provider<TranslateService>((ref) => TranslateService());
final supabaseServiceProvider = Provider<SupabaseService>((ref) => SupabaseService());

// Database Scans History state provider
final historyProvider = StateNotifierProvider<HistoryNotifier, List<ScanResult>>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return HistoryNotifier(supabaseService);
});

class HistoryNotifier extends StateNotifier<List<ScanResult>> {
  final SupabaseService _supabaseService;
  final DatabaseService _db = DatabaseService.instance;

  HistoryNotifier(this._supabaseService) : super([]) {
    loadScans();
  }

  Future<void> loadScans() async {
    final list = await _db.getScans();
    state = list;
    
    // Auto-sync unsynced scans in background if Supabase is available
    if (_supabaseService.isAvailable) {
      // Find local unsynced scans (image url doesn't start with http, or we just sync them)
      final unsynced = list.where((scan) => !scan.imageUrl.startsWith('http')).toList();
      if (unsynced.isNotEmpty) {
        _supabaseService.syncOfflineScans(unsynced, (syncedScan) async {
          // Callback after successful cloud backup:
          // In real setup, we would update the SQLite row with the public image_url
          // For simplicity, we just log it. If needed, we can write an update db routine.
        });
      }
    }
  }

  Future<void> searchScans(String query) async {
    if (query.isEmpty) {
      await loadScans();
      return;
    }
    final list = await _db.searchScans(query);
    state = list;
  }

  Future<void> addScan(ScanResult scan) async {
    await _db.insertScan(scan);
    // If online, sync to cloud
    if (_supabaseService.isAvailable) {
      String? cloudUrl;
      if (scan.imageUrl.isNotEmpty) {
        cloudUrl = await _supabaseService.uploadImage(scan.imageUrl, scan.farmerId, scan.id);
      }
      await _supabaseService.backupScan(scan, cloudImageUrl: cloudUrl);
    }
    await loadScans();
  }

  Future<void> deleteScan(String id) async {
    await _db.deleteScan(id);
    await loadScans();
  }

  Future<void> clearHistory() async {
    await _db.clearHistory();
    state = [];
  }
}
