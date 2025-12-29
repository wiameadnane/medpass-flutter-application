import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

/// Emergency contact model for additional contacts (premium feature)
class EmergencyContact {
  final String name;
  final String phone;
  final String? relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String?,
    );
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final double? height; // in cm
  final double? weight; // in kg
  final String? nationality;
  final String? gender;
  final bool isPremium;
  final String preferredLanguage; // 'en', 'fr', 'ar', 'es', 'de', 'zh'
  final DateTime createdAt;

  // Usage tracking for free users
  final int monthlyScanCount;
  final DateTime? lastScanResetDate;

  // Emergency & Critical Info (primary contact - available for all users)
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;

  // Additional emergency contacts (premium only)
  final List<EmergencyContact> additionalEmergencyContacts;

  final List<String> allergies;
  final List<String> medicalConditions;
  final List<String> currentMedications;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.dateOfBirth,
    this.bloodType,
    this.height,
    this.weight,
    this.nationality,
    this.gender,
    this.isPremium = false,
    this.preferredLanguage = 'en',
    DateTime? createdAt,
    this.monthlyScanCount = 0,
    this.lastScanResetDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    List<EmergencyContact>? additionalEmergencyContacts,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
  })  : createdAt = createdAt ?? DateTime.now(),
        additionalEmergencyContacts = additionalEmergencyContacts ?? [],
        allergies = allergies ?? [],
        medicalConditions = medicalConditions ?? [],
        currentMedications = currentMedications ?? [];

  // Check if user has critical info filled
  bool get hasCriticalInfo =>
      bloodType != null ||
      allergies.isNotEmpty ||
      emergencyContactPhone != null;

  // Get allergies as formatted string
  String get allergiesDisplay =>
      allergies.isEmpty ? 'None' : allergies.join(', ');

  // Get conditions as formatted string
  String get conditionsDisplay =>
      medicalConditions.isEmpty ? 'None' : medicalConditions.join(', ');

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get formattedDateOfBirth {
    if (dateOfBirth == null) return '';
    return '${dateOfBirth!.day.toString().padLeft(2, '0')}/${dateOfBirth!.month.toString().padLeft(2, '0')}/${dateOfBirth!.year}';
  }

  String get formattedHeight {
    if (height == null) return '';
    return '${height!.toInt()} cm';
  }

  String get formattedWeight {
    if (weight == null) return '';
    return '${weight!.toInt()} Kg';
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? dateOfBirth,
    String? bloodType,
    double? height,
    double? weight,
    String? nationality,
    String? gender,
    bool? isPremium,
    String? preferredLanguage,
    DateTime? createdAt,
    int? monthlyScanCount,
    DateTime? lastScanResetDate,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    List<EmergencyContact>? additionalEmergencyContacts,
    List<String>? allergies,
    List<String>? medicalConditions,
    List<String>? currentMedications,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      nationality: nationality ?? this.nationality,
      gender: gender ?? this.gender,
      isPremium: isPremium ?? this.isPremium,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      monthlyScanCount: monthlyScanCount ?? this.monthlyScanCount,
      lastScanResetDate: lastScanResetDate ?? this.lastScanResetDate,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      additionalEmergencyContacts: additionalEmergencyContacts ?? this.additionalEmergencyContacts,
      allergies: allergies ?? this.allergies,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      currentMedications: currentMedications ?? this.currentMedications,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'date_of_birth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'blood_type': bloodType,
      'height': height,
      'weight': weight,
      'country_of_origin': nationality,
      'gender': gender,
      'is_premium': isPremium,
      'preferred_language': preferredLanguage,
      'created_at': Timestamp.fromDate(createdAt),
      'monthly_scan_count': monthlyScanCount,
      'last_scan_reset_date': lastScanResetDate != null ? Timestamp.fromDate(lastScanResetDate!) : null,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'additional_emergency_contacts': additionalEmergencyContacts.map((c) => c.toJson()).toList(),
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'current_medications': currentMedications,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? dob;
    final dobVal = json['date_of_birth'] ?? json['dateOfBirth'];
    if (dobVal != null) {
      if (dobVal is Timestamp) dob = dobVal.toDate();
      else if (dobVal is String) dob = DateTime.tryParse(dobVal);
    }

    DateTime created = DateTime.now();
    final createdVal = json['created_at'] ?? json['createdAt'];
    if (createdVal != null) {
      if (createdVal is Timestamp) created = createdVal.toDate();
      else if (createdVal is String) created = DateTime.tryParse(createdVal) ?? created;
    }

    // Parse last scan reset date
    DateTime? lastScanReset;
    final scanResetVal = json['last_scan_reset_date'] ?? json['lastScanResetDate'];
    if (scanResetVal != null) {
      if (scanResetVal is Timestamp) lastScanReset = scanResetVal.toDate();
      else if (scanResetVal is String) lastScanReset = DateTime.tryParse(scanResetVal);
    }

    String idVal = json['id'] ?? json['uid'] ?? (json['documentId'] ?? '');
    String fullNameVal = json['full_name'] ?? json['fullName'] ?? '';
    String emailVal = json['email'] ?? '';

    double? h;
    final hVal = json['height'] ?? json['height_cm'];
    if (hVal is int) h = hVal.toDouble();
    else if (hVal is double) h = hVal;

    double? w;
    final wVal = json['weight'] ?? json['weight_kg'];
    if (wVal is int) w = wVal.toDouble();
    else if (wVal is double) w = wVal;

    // Parse list fields
    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    // Parse additional emergency contacts
    List<EmergencyContact> parseEmergencyContacts(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value
            .whereType<Map<String, dynamic>>()
            .map((e) => EmergencyContact.fromJson(e))
            .toList();
      }
      return [];
    }

    return UserModel(
      id: idVal as String,
      fullName: fullNameVal as String,
      email: emailVal as String,
      phoneNumber: (json['phone_number'] ?? json['phoneNumber']) as String?,
      profileImageUrl: (json['profile_image_url'] ?? json['profileImageUrl']) as String?,
      dateOfBirth: dob,
      bloodType: (json['blood_type'] ?? json['bloodType']) as String?,
      height: h,
      weight: w,
      nationality: (json['country_of_origin'] ?? json['nationality']) as String?,
      gender: (json['gender']) as String?,
      isPremium: (json['is_premium'] ?? json['isPremium']) as bool? ?? false,
      preferredLanguage: (json['preferred_language'] ?? json['preferredLanguage']) as String? ?? 'en',
      createdAt: created,
      monthlyScanCount: (json['monthly_scan_count'] ?? json['monthlyScanCount']) as int? ?? 0,
      lastScanResetDate: lastScanReset,
      emergencyContactName: (json['emergency_contact_name'] ?? json['emergencyContactName']) as String?,
      emergencyContactPhone: (json['emergency_contact_phone'] ?? json['emergencyContactPhone']) as String?,
      emergencyContactRelation: (json['emergency_contact_relation'] ?? json['emergencyContactRelation']) as String?,
      additionalEmergencyContacts: parseEmergencyContacts(json['additional_emergency_contacts'] ?? json['additionalEmergencyContacts']),
      allergies: parseStringList(json['allergies']),
      medicalConditions: parseStringList(json['medical_conditions'] ?? json['medicalConditions']),
      currentMedications: parseStringList(json['current_medications'] ?? json['currentMedications']),
    );
  }

  // Demo user for testing
  static UserModel get demoUser => UserModel(
        id: '21101001',
        fullName: 'Israa Aqdora',
        email: 'israaaqdora@outlook.fr',
        phoneNumber: '0693339086',
        dateOfBirth: DateTime(2003, 11, 19),
        bloodType: 'O+',
        height: 157,
        weight: 61,
        nationality: 'Moroccan',
        gender: 'Female',
        isPremium: false,
        preferredLanguage: 'fr',
        emergencyContactName: 'Ahmed Aqdora',
        emergencyContactPhone: '+212 612 345 678',
        emergencyContactRelation: 'Father',
        allergies: ['Penicillin', 'Peanuts'],
        medicalConditions: ['Asthma'],
        currentMedications: ['Ventolin inhaler'],
      );

  // Supported languages with display names
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'fr': 'Français',
    'ar': 'العربية',
    'es': 'Español',
    'de': 'Deutsch',
    'zh': '中文',
  };

  // Get display name for preferred language
  String get preferredLanguageDisplay =>
      supportedLanguages[preferredLanguage] ?? 'English';

  /// Generates emergency info string for QR code (offline-readable)
  /// Contains only non-confidential emergency information
  String get emergencyQrData {
    final buffer = StringBuffer();

    buffer.writeln('EMERGENCY MEDICAL INFO');
    buffer.writeln('=======================');
    buffer.writeln('Name: $fullName');

    if (bloodType != null && bloodType!.isNotEmpty) {
      buffer.writeln('Blood Type: $bloodType');
    }

    if (age != null) {
      buffer.writeln('Age: $age years');
    }

    buffer.writeln('');

    if (allergies.isNotEmpty) {
      buffer.writeln('ALLERGIES:');
      for (final allergy in allergies) {
        buffer.writeln('  - $allergy');
      }
      buffer.writeln('');
    }

    if (medicalConditions.isNotEmpty) {
      buffer.writeln('CONDITIONS:');
      for (final condition in medicalConditions) {
        buffer.writeln('  - $condition');
      }
      buffer.writeln('');
    }

    if (currentMedications.isNotEmpty) {
      buffer.writeln('MEDICATIONS:');
      for (final medication in currentMedications) {
        buffer.writeln('  - $medication');
      }
      buffer.writeln('');
    }

    if (emergencyContactName != null || emergencyContactPhone != null) {
      buffer.writeln('EMERGENCY CONTACT:');
      if (emergencyContactName != null) {
        buffer.write('  $emergencyContactName');
        if (emergencyContactRelation != null) {
          buffer.write(' ($emergencyContactRelation)');
        }
        buffer.writeln('');
      }
      if (emergencyContactPhone != null) {
        buffer.writeln('  Tel: $emergencyContactPhone');
      }
    }

    buffer.writeln('');
    buffer.writeln('Generated by MedPass');

    return buffer.toString();
  }

  /// Check if user has enough emergency info to generate a useful QR code
  bool get hasEmergencyQrData =>
      bloodType != null ||
      allergies.isNotEmpty ||
      medicalConditions.isNotEmpty ||
      currentMedications.isNotEmpty ||
      emergencyContactPhone != null;
}
