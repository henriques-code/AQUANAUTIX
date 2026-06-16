// lib/core/catch_photos/catch_photo_repository.dart

import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_bootstrap.dart';
import 'catch_photo_model.dart';

class CatchPhotoRepository {
  static const _table = 'catch_photos';
  static const _bucket = 'catch-photos';

  SupabaseClient? get _db => supabaseClientOrNull;

  String? get _uid => _db?.auth.currentSession?.user.id;

  static double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const d = Distance();
    return d.as(LengthUnit.Kilometer, LatLng(lat1, lon1), LatLng(lat2, lon2));
  }

  /// Fotos públicas num raio, com username e avatar (merge `user_profiles`).
  Future<List<CatchPhoto>> fetchNearby({
    required double lat,
    required double lng,
    double radiusKm = 100,
  }) async {
    final client = supabaseClientOrNull;
    if (client == null) return [];

    final rows = await client
        .from(_table)
        .select()
        .eq('privacy', 'public')
        .order('created_at', ascending: false)
        .limit(200);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return [];

    final userIds = list.map((e) => e['user_id'] as String).toSet().toList();
    final profilesById = <String, Map<String, dynamic>>{};
    if (userIds.isNotEmpty) {
      final prof = await client.from('user_profiles').select('id, username, avatar_url').inFilter('id', userIds);
      for (final r in (prof as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final id = m['id'] as String?;
        if (id != null) profilesById[id] = m;
      }
    }

    final out = <CatchPhoto>[];
    for (final raw in list) {
      final map = Map<String, dynamic>.from(raw);
      final uid = map['user_id'] as String;
      final p = profilesById[uid];
      if (p != null) {
        map['user_profiles'] = <String, dynamic>{
          'username': p['username'],
          'avatar_url': p['avatar_url'],
        };
      }
      final photo = CatchPhoto.fromJson(map);
      if (_distanceKm(lat, lng, photo.latitude, photo.longitude) <= radiusKm) {
        out.add(photo);
      }
    }
    return out.length > 100 ? out.sublist(0, 100) : out;
  }

  Future<List<CatchPhoto>> fetchMine() async {
    final db = _db;
    if (db == null) return [];
    final uid = _uid;
    if (uid == null) return [];
    final rows = await db
        .from(_table)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return (rows as List).cast<Map<String, dynamic>>().map(CatchPhoto.fromJson).toList();
  }

  Future<String> uploadPhoto(XFile file) async {
    final db = _db;
    if (db == null) throw Exception('Supabase não disponível');
    final uid = _uid;
    if (uid == null) throw Exception('Não autenticado');
    final ext = file.name.split('.').last.toLowerCase();
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await db.storage.from(_bucket).uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(contentType: 'image/$ext'),
        );
    return db.storage.from(_bucket).getPublicUrl(path);
  }

  Future<CatchPhoto> create({
    required LatLng location,
    required XFile photoFile,
    String? species,
    double? weightKg,
    String? lureType,
    String? technique,
    String? notes,
    CatchPrivacy privacy = CatchPrivacy.public,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Não autenticado');

    final db = _db;
    if (db == null) throw Exception('Supabase não disponível');

    final photoUrl = await uploadPhoto(photoFile);

    final draft = CatchPhoto(
      id: '',
      userId: uid,
      location: location,
      photoUrl: photoUrl,
      species: species,
      weightKg: weightKg,
      lengthCm: null,
      lureType: lureType,
      technique: technique,
      notes: notes,
      privacy: privacy,
      createdAt: DateTime.now(),
    );

    final row = await db.from(_table).insert(draft.toInsert(userId: uid)).select().single();

    return CatchPhoto.fromJson(row);
  }

  Future<void> changePrivacy(String id, CatchPrivacy privacy) async {
    final db = _db;
    if (db == null) return;
    await db.from(_table).update({'privacy': privacy.value}).eq('id', id);
  }

  Future<void> delete(String id) async {
    final db = _db;
    if (db == null) return;
    await db.from(_table).delete().eq('id', id);
  }
}
