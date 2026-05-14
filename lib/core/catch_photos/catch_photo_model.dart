// lib/core/catch_photos/catch_photo_model.dart

import 'package:latlong2/latlong.dart';

enum CatchPrivacy { public, friends, private }

extension CatchPrivacyX on CatchPrivacy {
  String get value => name; // 'public' | 'friends' | 'private'
  static CatchPrivacy from(String? v) => switch (v) {
        'friends' => CatchPrivacy.friends,
        'private' => CatchPrivacy.private,
        _ => CatchPrivacy.public,
      };
}

class CatchPhoto {
  final String id;
  final String userId;
  final LatLng location;
  final String photoUrl;
  final String? species;
  final double? weightKg;
  final double? lengthCm;
  final String? lureType;
  final String? technique;
  final String? notes;
  final CatchPrivacy privacy;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? username;

  const CatchPhoto({
    required this.id,
    required this.userId,
    required this.location,
    required this.photoUrl,
    this.species,
    this.weightKg,
    this.lengthCm,
    this.lureType,
    this.technique,
    this.notes,
    required this.privacy,
    required this.createdAt,
    this.avatarUrl,
    this.username,
  });

  double get latitude => location.latitude;
  double get longitude => location.longitude;

  static Map<String, dynamic>? _userProfilesMap(Map<String, dynamic> j) {
    final v = j['user_profiles'];
    if (v is Map<String, dynamic>) return v;
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    return null;
  }

  factory CatchPhoto.fromJson(Map<String, dynamic> j) {
    final LatLng loc;
    final locVal = j['location'];
    if (locVal is Map<String, dynamic> && locVal['coordinates'] is List) {
      final coords = (locVal['coordinates'] as List).cast<num>();
      loc = LatLng(coords[1].toDouble(), coords[0].toDouble());
    } else if (j['lat'] != null && j['lng'] != null) {
      loc = LatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());
    } else {
      throw FormatException('catch_photos: falta geometry (location) ou lat/lng');
    }
    final up = _userProfilesMap(j);
    return CatchPhoto(
      id: j['id'] as String,
      userId: j['user_id'] as String,
      location: loc,
      photoUrl: j['photo_url'] as String,
      species: j['species'] as String?,
      weightKg: (j['weight_kg'] as num?)?.toDouble(),
      lengthCm: (j['length_cm'] as num?)?.toDouble(),
      lureType: j['lure_type'] as String?,
      technique: j['technique'] as String?,
      notes: j['notes'] as String?,
      privacy: CatchPrivacyX.from(j['privacy'] as String?),
      createdAt: DateTime.parse(j['created_at'] as String),
      avatarUrl: up?['avatar_url'] as String?,
      username: up?['username'] as String?,
    );
  }

  /// PostgREST: geometry via trigger `trg_set_catch_location` a partir de lat/lng.
  Map<String, dynamic> toInsert({required String userId}) => {
        'user_id': userId,
        'lat': location.latitude,
        'lng': location.longitude,
        'photo_url': photoUrl,
        if (species != null) 'species': species,
        if (weightKg != null) 'weight_kg': weightKg,
        if (lengthCm != null) 'length_cm': lengthCm,
        if (lureType != null) 'lure_type': lureType,
        if (technique != null) 'technique': technique,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'privacy': privacy.value,
      };

  CatchPhoto copyWith({
    CatchPrivacy? privacy,
    String? avatarUrl,
    String? username,
  }) =>
      CatchPhoto(
        id: id,
        userId: userId,
        location: location,
        photoUrl: photoUrl,
        species: species,
        weightKg: weightKg,
        lengthCm: lengthCm,
        lureType: lureType,
        technique: technique,
        notes: notes,
        privacy: privacy ?? this.privacy,
        createdAt: createdAt,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        username: username ?? this.username,
      );
}
