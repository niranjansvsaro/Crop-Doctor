class Disease {
  final String id;
  final String cropType;
  final String name;
  final String scientificName;
  final int severity;
  final String severityLabel;
  final String symptoms;
  final List<String> treatment;
  final String prevention;
  final String imageAsset;

  Disease({
    required this.id,
    required this.cropType,
    required this.name,
    required this.scientificName,
    required this.severity,
    required this.severityLabel,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.imageAsset,
  });

  factory Disease.fromJson(Map<String, dynamic> json) {
    return Disease(
      id: json['id'] as String? ?? '',
      cropType: json['crop_type'] as String? ?? '',
      name: json['name'] as String? ?? '',
      scientificName: json['scientific_name'] as String? ?? '',
      severity: json['severity'] as int? ?? 1,
      severityLabel: json['severity_label'] as String? ?? 'Mild',
      symptoms: json['symptoms'] as String? ?? '',
      treatment: List<String>.from(json['treatment'] ?? []),
      prevention: json['prevention'] as String? ?? '',
      imageAsset: json['image_asset'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'crop_type': cropType,
      'name': name,
      'scientific_name': scientificName,
      'severity': severity,
      'severity_label': severityLabel,
      'symptoms': symptoms,
      'treatment': treatment,
      'prevention': prevention,
      'image_asset': imageAsset,
    };
  }

  factory Disease.fromMap(Map<String, dynamic> map) {
    return Disease.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }
}
