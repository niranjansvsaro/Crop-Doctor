import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/scan_result.dart';

class SupabaseService {
  final SupabaseClient? _client;

  SupabaseService() : _client = _initClient();

  static SupabaseClient? _initClient() {
    try {
      return Supabase.instance.client;
    } catch (e) {
      return null;
    }
  }

  bool get isAvailable => _client != null;

  /// Uploads local scan image file to Supabase storage bucket `leaf-scans`
  Future<String?> uploadImage(String filePath, String farmerId, String scanId) async {
    final client = _client;
    if (client == null) return null;
    
    try {
      final file = File(filePath);
      final filename = '$farmerId/$scanId.jpg';
      
      // Upload to bucket
      await client.storage.from('leaf-scans').upload(
        filename,
        file,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // Get public URL
      final String publicUrl = client.storage.from('leaf-scans').getPublicUrl(filename);
      return publicUrl;
    } catch (e) {
      debugPrint("Supabase upload failed: $e");
      return null;
    }
  }

  /// Backs up a scan record to Supabase database table `scans`
  Future<bool> backupScan(ScanResult scan, {String? cloudImageUrl}) async {
    final client = _client;
    if (client == null) return false;

    try {
      final scanMap = scan.toMap();
      // If we uploaded the image separately, update the image_url field
      if (cloudImageUrl != null) {
        scanMap['image_url'] = cloudImageUrl;
      }

      await client.from('scans').upsert(scanMap).select();
      return true;
    } catch (e) {
      debugPrint("Supabase database insert failed: $e");
      return false;
    }
  }

  /// Syncs all unsynced scans from SQLite database
  Future<void> syncOfflineScans(List<ScanResult> unsyncedScans, Function(ScanResult) onSyncSuccess) async {
    if (unsyncedScans.isEmpty) return;

    for (var scan in unsyncedScans) {
      try {
        String? cloudUrl;
        
        // If image_url is a local path (starts with / or has C:\), upload it
        if (!scan.imageUrl.startsWith('http') && scan.imageUrl.isNotEmpty) {
          cloudUrl = await uploadImage(scan.imageUrl, scan.farmerId, scan.id);
        } else {
          cloudUrl = scan.imageUrl;
        }

        final success = await backupScan(scan, cloudImageUrl: cloudUrl);
        if (success) {
          // Trigger callback to update local database record
          onSyncSuccess(scan);
        }
      } catch (e) {
        debugPrint("Failed to sync scan ${scan.id}: $e");
      }
    }
  }
}
