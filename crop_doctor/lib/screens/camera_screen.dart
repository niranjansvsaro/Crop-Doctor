import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import '../providers.dart';
import '../models/scan_result.dart';
import 'result_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}


class _CameraScreenState extends ConsumerState<CameraScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  XFile? _imageFile;
  bool _flashOn = false;

  late AnimationController _scanAnimationController;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint("No cameras available.");
        return;
      }
      
      _cameraController = CameraController(
        _cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      if (_flashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _flashOn = !_flashOn;
      });
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_isCameraInitialized || _cameraController!.value.isTakingPicture) return;
    
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _imageFile = image;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error capturing image: $e")),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: $e")),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;
    
    setState(() {
      _isAnalyzing = true;
    });
    _scanAnimationController.repeat(reverse: true);

    try {
      // Get location coordinates if enabled
      double? lat;
      double? lng;
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );
        lat = position.latitude;
        lng = position.longitude;
      } catch (_) {
        // Location failed, fallback to null
      }

      final language = ref.read(languageProvider);
      final farmerId = ref.read(farmerPhoneProvider); // Use phone number as unique farmer id
      final apiService = ref.read(apiServiceProvider);

      // Perform backend detection
      final ScanResult result = await apiService.detectDisease(
        imagePath: _imageFile!.path,
        language: language,
        farmerId: farmerId.isNotEmpty ? farmerId : "offline_farmer",
        latitude: lat,
        longitude: lng,
      );

      // Save locally to database
      // The detectDisease call returns a ScanResult.
      // But image_url is returned as a cloud URL. We can store a local reference to our picked image 
      // so it remains viewable offline! This is a smart offline-first touch.
      final scanToSave = ScanResult(
        id: result.id,
        farmerId: result.farmerId,
        imageUrl: _imageFile!.path, // Use local path on device for instant offline reloading
        diseaseNameEn: result.diseaseNameEn,
        diseaseNameLocal: result.diseaseNameLocal,
        severity: result.severity,
        confidence: result.confidence,
        affectedAreaPct: result.affectedAreaPct,
        treatmentEn: result.treatmentEn,
        treatmentLocal: result.treatmentLocal,
        cropType: result.cropType,
        language: result.language,
        gpsLat: lat,
        gpsLng: lng,
        createdAt: result.createdAt,
      );

      // Add to list and database
      await ref.read(historyProvider.notifier).addScan(scanToSave);

      if (mounted) {
        // Stop animations and navigate to results
        _scanAnimationController.stop();
        setState(() => _isAnalyzing = false);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(scan: scanToSave),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _scanAnimationController.stop();
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[800],
            content: Text("Analysis failed: ${e.toString().replaceAll("Exception: ", "")}"),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Loading / Analyzing State View
    if (_isAnalyzing) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image preview under the scanner
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        Image.file(
                          File(_imageFile!.path),
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                        // Semi transparent dark cover
                        Container(color: Colors.black.withAlpha(80)),
                        // Glowing laser line animation
                        AnimatedBuilder(
                          animation: _scanAnimationController,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimationController.value * 250,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF66BB6A).withAlpha(200),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              // Rotating scanner icon
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                strokeWidth: 5,
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 1.seconds),
              const SizedBox(height: 24),
              Text(
                "AI Detecting Disease...",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "Uploading compressed leaf photo and connecting to NVIDIA NIM Vision AI...",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Photo Preview State View (Taken but not analyzed yet)
    if (_imageFile != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _imageFile = null),
          ),
          title: Text("Preview Photo", style: GoogleFonts.poppins(color: Colors.white)),
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.only(left: 32, right: 32, bottom: 40),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => setState(() => _imageFile = null),
                      child: const Text("Retake", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _analyzeImage,
                      child: const Text("Analyze", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Live Camera View / Capture Mode
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Viewport camera preview
          _isCameraInitialized && _cameraController != null
              ? Center(
                  child: AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 64),
                      const SizedBox(height: 16),
                      const Text(
                        "Camera not available.",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library, color: Color(0xFF66BB6A)),
                        label: const Text("Select from Gallery", style: TextStyle(color: Color(0xFF66BB6A))),
                      ),
                    ],
                  ),
                ),

          // Future UI/HUD Scan Overlay (Grid lines + Frame)
          if (_isCameraInitialized)
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withAlpha(100),
                    width: 40,
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid overlays
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          2, (index) => const VerticalDivider(color: Colors.white24, width: 1)),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                          2, (index) => const Divider(color: Colors.white24, height: 1)),
                    ),
                    // Capture frames corner indicators
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF66BB6A), width: 2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Header Controls
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  "Center the Leaf",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _flashOn ? Icons.flash_on : Icons.flash_off,
                      color: _flashOn ? Colors.amber : Colors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
              ],
            ),
          ),

          // Footer Controls (Trigger + Gallery)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    onPressed: _pickFromGallery,
                  ),
                ),
                // Shutter button
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Flip camera button placeholder or empty to balance row spacing
                const SizedBox(width: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
