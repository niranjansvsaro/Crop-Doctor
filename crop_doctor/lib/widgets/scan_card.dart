import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../models/scan_result.dart';
import '../widgets/severity_badge.dart';

class ScanCard extends StatelessWidget {
  final ScanResult scan;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final String language;

  const ScanCard({
    super.key,
    required this.scan,
    required this.onTap,
    required this.onDelete,
    required this.language,
  });

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHealthy = scan.diseaseNameEn.toLowerCase().contains('healthy') || scan.severity == 1;
    final displayName = language.toLowerCase() == 'english' ? scan.diseaseNameEn : scan.diseaseNameLocal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(60),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha(40),
                  Colors.white.withAlpha(10),
                ],
              ),
            ),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Leaf image thumbnail
                    Hero(
                      tag: 'scan_image_${scan.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[800],
                          child: scan.imageUrl.startsWith('http')
                              ? Image.network(
                                  scan.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white54,
                                  ),
                                )
                              : scan.imageUrl.isNotEmpty && File(scan.imageUrl).existsSync()
                                  ? Image.file(
                                      File(scan.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white54,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.eco,
                                      color: Colors.green,
                                      size: 36,
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Scan Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[800]?.withAlpha(80),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  scan.cropType,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(scan.createdAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayName,
                            style: TextStyle(
                              color: isHealthy ? const Color(0xFF81C784) : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SeverityBadge(severity: scan.severity, animate: false),
                              const SizedBox(width: 8),
                              Text(
                                "${(scan.confidence * 100).toStringAsFixed(0)}% Match",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Buttons (e.g. Delete)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
