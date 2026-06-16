import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../models/scan_result.dart';

class ApiService {
  final Dio _dio = Dio();
  
  // Replace this with your actual Vercel backend URL in production
  // Under Android Emulator, 10.0.2.2 points to local machine's localhost
  static const String baseUrl = "https://crop-doctor-jjla.vercel.app"; 

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 35);
    _dio.options.receiveTimeout = const Duration(seconds: 35);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Compresses the image file on device to keep the upload payload below 500KB
  Future<List<int>?> _compressImage(String filePath) async {
    final file = File(filePath);
    final int originalSize = await file.length();
    
    // If it's already under 500KB, skip heavy compression
    if (originalSize <= 500 * 1024) {
      return await file.readAsBytes();
    }

    // Compress using flutter_image_compress
    final result = await FlutterImageCompress.compressWithFile(
      filePath,
      minWidth: 1024,
      minHeight: 1024,
      quality: 80,
    );

    return result;
  }

  /// Sends the base64 image along with metadata to the FastAPI backend for disease detection
  Future<ScanResult> detectDisease({
    required String imagePath,
    required String language,
    required String farmerId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final compressedBytes = await _compressImage(imagePath);
      if (compressedBytes == null) {
        throw Exception("Failed to read and compress image file.");
      }

      final String base64Image = base64Encode(compressedBytes);

      final response = await _dio.post(
        "$baseUrl/api/detect",
        data: {
          "image_base64": base64Image,
          "language": language.toLowerCase(),
          "farmer_id": farmerId,
          "gps_lat": latitude,
          "gps_lng": longitude,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return ScanResult.fromJson(data);
      } else {
        throw Exception("Server error (${response.statusCode}): ${response.statusMessage}");
      }
    } on DioException catch (e) {
      String errorMessage = "Network request failed.";
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = "Connection timed out. Please check your internet connection.";
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Server is taking too long to respond. Please try again.";
      } else if (e.response != null) {
        errorMessage = "Server error: ${e.response?.data['detail'] ?? e.message}";
      } else {
        errorMessage = "Connection error: ${e.message}";
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception("An unexpected error occurred: $e");
    }
  }
}


