import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../supabase_bootstrap.dart';
import 'community_post.dart';
import 'community_repository.dart';

@immutable
class CommunityState {
  final List<CommunityPost> posts;
  final bool loading;
  final String? error;

  const CommunityState({
    this.posts = const [],
    this.loading = false,
    this.error,
  });

  CommunityState copyWith({
    List<CommunityPost>? posts,
    bool? loading,
    String? error,
  }) =>
      CommunityState(
        posts:   posts   ?? this.posts,
        loading: loading ?? this.loading,
        error:   error,
      );
}

class CommunityStore {
  CommunityStore._();
  static final instance = CommunityStore._();

  final value = ValueNotifier<CommunityState>(const CommunityState());
  final _repo = CommunityRepository();

  Future<void> loadFeed({String? country}) async {
    if (!isSupabaseConfigured) return;
    value.value = value.value.copyWith(loading: true);
    try {
      final posts = await _repo.fetchFeed(country: country);
      value.value = CommunityState(posts: posts);
    } catch (e) {
      value.value = value.value.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> toggleLike(String postId) async {
    if (!isSupabaseConfigured) return;
    final posts = List<CommunityPost>.from(value.value.posts);
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = posts[idx];
    final nowLiked = !post.likedByMe;
    posts[idx] = post.copyWith(
      likesCount: post.likesCount + (nowLiked ? 1 : -1),
      likedByMe: nowLiked,
    );
    value.value = value.value.copyWith(posts: posts);
    unawaited(_repo.toggleLike(postId));
  }

  Future<String?> uploadPhoto(XFile file) async {
    if (!isSupabaseConfigured) return null;
    try {
      return await _repo.uploadPhoto(file);
    } catch (_) {
      return null;
    }
  }

  Future<bool> createPost({
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
    if (!isSupabaseConfigured) return false;
    try {
      final post = await _repo.createPost(
        zoneLabel:   zoneLabel,
        photoUrl:    photoUrl,
        species:     species,
        weightKg:    weightKg,
        technique:   technique,
        caption:     caption,
        oracleScore: oracleScore,
        isLegal:     isLegal,
        country:     country,
      );
      value.value = value.value.copyWith(
        posts: [post, ...value.value.posts],
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
