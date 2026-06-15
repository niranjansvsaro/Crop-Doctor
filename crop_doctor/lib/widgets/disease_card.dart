import 'package:flutter/material.dart';
import '../models/disease.dart';
import '../widgets/severity_badge.dart';

class DiseaseCard extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const DiseaseCard({
    super.key,
    required this.disease,
    required this.onTap,
  });

  IconData _getCropIcon() {
    switch (disease.cropType.toLowerCase()) {
      case 'rice':
        return Icons.grass;
      case 'wheat':
        return Icons.grain;
      case 'tomato':
        return Icons.circle_notifications; // fallback
      case 'cotton':
        return Icons.cloud_queue; // looks like cotton ball
      case 'maize':
        return Icons.agriculture;
      case 'sugarcane':
        return Icons.linear_scale;
      default:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white.withAlpha(20),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withAlpha(40), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              // Icon container with gradient
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2E7D32).withAlpha(180),
                      const Color(0xFF66BB6A).withAlpha(180),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getCropIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              // Disease Name & Crop Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          disease.cropType,
                          style: TextStyle(
                            color: Colors.green[300],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        SeverityBadge(severity: disease.severity, animate: false),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      disease.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      disease.scientificName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
