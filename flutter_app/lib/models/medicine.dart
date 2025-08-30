class Medicine {
  final int? id;
  final String brandName;
  final String genericName;
  final String strength;
  final String manufacturer;
  final String uses;
  final String sideEffects;
  final String warnings;
  final String? imageUrl;
  final String? barcode;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    this.id,
    required this.brandName,
    required this.genericName,
    required this.strength,
    required this.manufacturer,
    required this.uses,
    required this.sideEffects,
    required this.warnings,
    this.imageUrl,
    this.barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'],
      brandName: map['brand_name'] ?? '',
      genericName: map['generic_name'] ?? '',
      strength: map['strength'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      uses: map['uses'] ?? '',
      sideEffects: map['side_effects'] ?? '',
      warnings: map['warnings'] ?? '',
      imageUrl: map['image_url'],
      barcode: map['barcode'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand_name': brandName,
      'generic_name': genericName,
      'strength': strength,
      'manufacturer': manufacturer,
      'uses': uses,
      'side_effects': sideEffects,
      'warnings': warnings,
      'image_url': imageUrl,
      'barcode': barcode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Medicine copyWith({
    int? id,
    String? brandName,
    String? genericName,
    String? strength,
    String? manufacturer,
    String? uses,
    String? sideEffects,
    String? warnings,
    String? imageUrl,
    String? barcode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      brandName: brandName ?? this.brandName,
      genericName: genericName ?? this.genericName,
      strength: strength ?? this.strength,
      manufacturer: manufacturer ?? this.manufacturer,
      uses: uses ?? this.uses,
      sideEffects: sideEffects ?? this.sideEffects,
      warnings: warnings ?? this.warnings,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Medicine(id: $id, brandName: $brandName, genericName: $genericName, strength: $strength, manufacturer: $manufacturer)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medicine && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MedicineSearchResult {
  final Medicine medicine;
  final double confidenceScore;
  final String matchedText;

  MedicineSearchResult({
    required this.medicine,
    required this.confidenceScore,
    required this.matchedText,
  });

  factory MedicineSearchResult.fromMap(Map<String, dynamic> map) {
    return MedicineSearchResult(
      medicine: Medicine.fromMap(map['medicine']),
      confidenceScore: map['confidence_score']?.toDouble() ?? 0.0,
      matchedText: map['matched_text'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicine': medicine.toMap(),
      'confidence_score': confidenceScore,
      'matched_text': matchedText,
    };
  }
}

class OCRResult {
  final String extractedText;
  final double confidence;
  final List<TextBlock> textBlocks;

  OCRResult({
    required this.extractedText,
    required this.confidence,
    required this.textBlocks,
  });
}

class TextBlock {
  final String text;
  final double confidence;
  final List<Offset> boundingBox;

  TextBlock({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });
}

class Offset {
  final double x;
  final double y;

  Offset(this.x, this.y);
}
