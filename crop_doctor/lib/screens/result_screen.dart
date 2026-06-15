import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_result.dart';
import '../providers.dart';
import '../services/translate_service.dart';
import '../widgets/severity_badge.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final ScanResult scan;

  const ResultScreen({
    super.key,
    required this.scan,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isSpeaking = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    ref.read(translateServiceProvider).stop();
    super.dispose();
  }

  Future<void> _toggleTts(String text, String language) async {
    final ttsService = ref.read(translateServiceProvider);
    if (_isSpeaking) {
      await ttsService.stop();
      _waveController.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      _waveController.repeat(reverse: true);
      await ttsService.speak(text, language);
    }
  }

  Future<void> _shareToWhatsapp(String language) async {
    final isEn = language.toLowerCase() == 'english';
    final disease =
        isEn ? widget.scan.diseaseNameEn : widget.scan.diseaseNameLocal;
    final treatment =
        isEn ? widget.scan.treatmentEn : widget.scan.treatmentLocal;

    final shareText = '🌿 *Crop Doctor Report* 🌿\n\n'
        '• *Crop Type:* ${widget.scan.cropType}\n'
        '• *Disease Detected:* $disease\n'
        '• *Severity Level:* ${widget.scan.severity}/5\n'
        '• *AI Confidence:* ${(widget.scan.confidence * 100).toStringAsFixed(0)}%\n\n'
        '🧪 *Treatment Instructions:*\n$treatment\n\n'
        'Sent using Crop Doctor App - Healthy Crops, Healthy Future.';

    final whatsappUrl =
        Uri.parse('whatsapp://send?text=${Uri.encodeComponent(shareText)}');
    final webUrl = Uri.parse(
        'https://api.whatsapp.com/send?text=${Uri.encodeComponent(shareText)}');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
    }
  }

  Color _getConfidenceColor(double conf) {
    if (conf >= 0.8) return const Color(0xFF66BB6A);
    if (conf >= 0.5) return const Color(0xFFFF9800);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isEn = language.toLowerCase() == 'english';

    final diseaseName =
        isEn ? widget.scan.diseaseNameEn : widget.scan.diseaseNameLocal;
    final symptomsText =
        'Leaf discoloration, spotting, and tissue damage characteristic of '
        '${widget.scan.cropType} pathogen infection.';
    final treatmentSteps =
        (isEn ? widget.scan.treatmentEn : widget.scan.treatmentLocal)
            .split('\n');
    const preventionText =
        'Keep fields clean. Apply recommended crop rotation cycles. '
        'Avoid nitrogen over-fertilization.';

    final confidenceColor = _getConfidenceColor(widget.scan.confidence);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Scan Diagnostics',
          style:
              GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Leaf Image ──────────────────────────────────────────
            Center(
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(55),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'scan_image_${widget.scan.id}',
                        child: widget.scan.imageUrl.startsWith('http')
                            ? Image.network(widget.scan.imageUrl,
                                fit: BoxFit.cover)
                            : widget.scan.imageUrl.isNotEmpty &&
                                    File(widget.scan.imageUrl).existsSync()
                                ? Image.file(File(widget.scan.imageUrl),
                                    fit: BoxFit.cover)
                                : Container(
                                    color: Colors.green[900],
                                    child: const Icon(Icons.eco,
                                        size: 80, color: Colors.white24),
                                  ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withAlpha(150),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.scan.cropType,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF66BB6A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 24),

            // ── Disease Header ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diseaseName,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SeverityBadge(severity: widget.scan.severity),
                    ],
                  ),
                ),
                // AI Confidence Circular Meter
                Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 65,
                          height: 65,
                          child: CircularProgressIndicator(
                            value: widget.scan.confidence,
                            strokeWidth: 6,
                            backgroundColor: Colors.white.withAlpha(20),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(confidenceColor),
                          ),
                        ),
                        Text(
                          '${(widget.scan.confidence * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: confidenceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TranslateService.get('confidence', language),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Symptoms ─────────────────────────────────────────────────
            Text(
              TranslateService.get('symptoms', language),
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Text(
                symptomsText,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),

            // ── Treatment Header + TTS ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslateService.get('treatment', language),
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => _toggleTts(
                      widget.scan.treatmentLocal.isNotEmpty
                          ? widget.scan.treatmentLocal
                          : widget.scan.treatmentEn,
                      language),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF66BB6A).withAlpha(80),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) => Icon(
                            _isSpeaking
                                ? Icons.volume_up
                                : Icons.volume_mute,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          TranslateService.get('read_treatment', language),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Treatment Step Cards ─────────────────────────────────────
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: treatmentSteps.length,
              itemBuilder: (context, index) {
                final step = treatmentSteps[index].trim();
                if (step.isEmpty) return const SizedBox.shrink();

                IconData stepIcon = Icons.eco_outlined;
                if (step.toLowerCase().contains('water') ||
                    step.toLowerCase().contains('irrigate')) {
                  stepIcon = Icons.water_drop_outlined;
                } else if (step.toLowerCase().contains('spray') ||
                    step.toLowerCase().contains('fungicide') ||
                    step.toLowerCase().contains('pesticide')) {
                  stepIcon = Icons.science_outlined;
                } else if (step.toLowerCase().contains('sun') ||
                    step.toLowerCase().contains('light')) {
                  stepIcon = Icons.light_mode_outlined;
                }

                return Card(
                  color: Colors.white.withAlpha(15),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withAlpha(20)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF66BB6A).withAlpha(40),
                      child: Icon(stepIcon, color: const Color(0xFF66BB6A)),
                    ),
                    title: Text(
                      step,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.3),
                    ),
                  ),
                ).animate().slideX(
                    begin: 0.1, duration: Duration(milliseconds: 300 * (index + 1)));
              },
            ),
            const SizedBox(height: 24),

            // ── Prevention Expandable Card ────────────────────────────────
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.shield_outlined,
                      color: Color(0xFF66BB6A)),
                  title: Text(
                    TranslateService.get('prevention', language),
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0),
                      child: Text(
                        preventionText,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── WhatsApp Share Button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => _shareToWhatsapp(language),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.share, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      TranslateService.get('share_whatsapp', language),
                      style: GoogleFonts.poppins(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
