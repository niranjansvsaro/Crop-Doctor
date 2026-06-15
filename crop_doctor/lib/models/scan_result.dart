class ScanResult {
  final String id;
  final String farmerId;
  final String imageUrl;
  final String diseaseNameEn;
  final String diseaseNameLocal;
  final int severity;
  final double confidence;
  final double affectedAreaPct;
  final String treatmentEn;
  final String treatmentLocal;
  final String cropType;
  final String language;
  final double? gpsLat;
  final double? gpsLng;
  final String createdAt;

  ScanResult({
    required this.id,
    required this.farmerId,
    required this.imageUrl,
    required this.diseaseNameEn,
    required this.diseaseNameLocal,
    required this.severity,
    required this.confidence,
    required this.affectedAreaPct,
    required this.treatmentEn,
    required this.treatmentLocal,
    required this.cropType,
    required this.language,
    this.gpsLat,
    this.gpsLng,
    required this.createdAt,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // API returns list of treatments sometimes, or string
    String treatmentEnVal = '';
    if (json['treatment_steps'] is List) {
      treatmentEnVal = (json['treatment_steps'] as List).join('\n');
    } else {
      treatmentEnVal = json['treatment_en'] ?? json['treatment'] ?? '';
    }

    String treatmentLocalVal = '';
    if (json['treatment_steps_local'] is List) {
      treatmentLocalVal = (json['treatment_steps_local'] as List).join('\n');
    } else {
      treatmentLocalVal = json['treatment_local'] ?? '';
    }

    // Local results might have symptoms in JSON, we can append it or store it if needed
    return ScanResult(
      id: json['id'] as String? ?? '',
      farmerId: json['farmer_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      diseaseNameEn: json['disease_name'] ?? json['disease_name_en'] ?? 'Healthy',
      diseaseNameLocal: json['disease_name_local'] ?? 'Healthy',
      severity: json['severity'] as int? ?? 1,
      confidence: (json['confidence'] as num? ?? 0.0).toDouble(),
      affectedAreaPct: (json['affected_area_pct'] as num? ?? 0.0).toDouble(),
      treatmentEn: treatmentEnVal,
      treatmentLocal: treatmentLocalVal,
      cropType: json['crop_type'] as String? ?? 'Unknown',
      language: json['language'] as String? ?? 'English',
      gpsLat: json['gps_lat'] != null ? (json['gps_lat'] as num).toDouble() : null,
      gpsLng: json['gps_lng'] != null ? (json['gps_lng'] as num).toDouble() : null,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'image_url': imageUrl,
      'disease_name_en': diseaseNameEn,
      'disease_name_local': diseaseNameLocal,
      'severity': severity,
      'confidence': confidence,
      'affected_area_pct': affectedAreaPct,
      'treatment_en': treatmentEnEnClean,
      'treatment_local': treatmentLocalLocalClean,
      'crop_type': cropType,
      'language': language,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'created_at': createdAt,
    };
  }

  // Clean values for getters
  String get treatmentEnEnClean => treatmentEn;
  String get treatmentLocalLocalClean => treatmentLocal;

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    return ScanResult(
      id: map['id'] as String? ?? '',
      farmerId: map['farmer_id'] as String? ?? '',
      imageUrl: map['image_url'] as String? ?? '',
      diseaseNameEn: map['disease_name_en'] as String? ?? '',
      diseaseNameLocal: map['disease_name_local'] as String? ?? '',
      severity: map['severity'] as int? ?? 1,
      confidence: (map['confidence'] as num? ?? 0.0).toDouble(),
      affectedAreaPct: (map['affected_area_pct'] as num? ?? 0.0).toDouble(),
      treatmentEn: map['treatment_en'] as String? ?? '',
      treatmentLocal: map['treatment_local'] as String? ?? '',
      cropType: map['crop_type'] as String? ?? '',
      language: map['language'] as String? ?? '',
      gpsLat: map['gps_lat'] != null ? (map['gps_lat'] as num).toDouble() : null,
      gpsLng: map['gps_lng'] != null ? (map['gps_lng'] as num).toDouble() : null,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'image_url': imageUrl,
      'disease_name_en': diseaseNameEn,
      'disease_name_local': diseaseNameLocal,
      'severity': severity,
      'confidence': confidence,
      'affected_area_pct': affectedAreaPct,
      'treatment_en': treatmentEn,
      'treatment_local': treatmentLocal,
      'crop_type': cropType,
      'language': language,
      'gps_lat': gpsLat,
      'gps_lng': gpsLng,
      'created_at': createdAt,
    };
  }
}
