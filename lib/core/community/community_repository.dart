import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_bootstrap.dart';
import 'community_post.dart';

class CommunityRepository {
  static const _posts     = 'community_posts';
  static const _reactions = 'community_reactions';
  static const _bucket    = 'community-photos';
  static const _pageSize  = 20;
  static const _cols = '''
    *,
    user_profiles!inner(username, tier, avatar_url),
    community_reactions(user_id)
  ''';

  SupabaseClient get _db => supabaseClientOrNull!;

  Future<List<CommunityPost>> fetchFeed({
    String? country,
    int offset = 0,
  }) async {
    List<dynamic> rows;
    if (country != null) {
      rows = await _db
          .from(_posts)
          .select(_cols)
          .eq('country', country)
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);
    } else {
      rows = await _db
          .from(_posts)
          .select(_cols)
          .order('created_at', ascending: false)
          .range(offset, offset + _pageSize - 1);
    }
    final uid = _db.auth.currentSession?.user.id;
    return rows
        .cast<Map<String, dynamic>>()
        .map((j) => CommunityPost.fromJson(j, currentUserId: uid))
        .toList();
  }

  Future<void> toggleLike(String postId) async {
    final uid = _db.auth.currentSession?.user.id;
    if (uid == null) return;
    final existing = await _db
        .from(_reactions)
        .select()
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    if (existing != null) {
      await _db.from(_reactions)
          .delete()
          .eq('post_id', postId)
          .eq('user_id', uid);
    } else {
      await _db.from(_reactions)
          .insert({'post_id': postId, 'user_id': uid});
    }
  }

  Future<String> uploadPhoto(XFile file) async {
    final ext  = file.name.split('.').last.toLowerCase();
    final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from(_bucket).uploadBinary(
      path,
      await file.readAsBytes(),
      fileOptions: FileOptions(contentType: 'image/$ext'),
    );
    return _db.storage.from(_bucket).getPublicUrl(path);
  }

  Future<CommunityPost> createPost({
    required String zoneLabel,
    required String photoUrl,
    required String species,
    double? weightKg,
    String? technique,
    String? caption,
    int? oracleScore,
    bool isLegal = true,
    required String country,
  }) async {
    final uid = _db.auth.currentSession?.user.id;
    if (uid == null) throw Exception('Not authenticated');
    final row = await _db.from(_posts).insert({
      'user_id':      uid,
      'zone_label':   zoneLabel,
      'photo_url':    photoUrl,
      'species':      species,
      if (weightKg != null)    'weight_kg':    weightKg,
      if (technique != null)   'technique':    technique,
      if (caption != null)     'caption':      caption,
      if (oracleScore != null) 'oracle_score': oracleScore,
      'is_legal': isLegal,
      'country':  country,
    }).select(_cols).single();
    return CommunityPost.fromJson(row, currentUserId: uid);
  }
}
