// lib/core/catch_photos/catch_photos_store.dart

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'catch_photo_model.dart';
import 'catch_photo_repository.dart';

enum CatchPhotosStatus { idle, loading, error }

class CatchPhotosStore extends ChangeNotifier {
  CatchPhotosStore({CatchPhotoRepository? repo})
      : _repo = repo ?? CatchPhotoRepository();

  final CatchPhotoRepository _repo;

  List<CatchPhoto> _photos = [];
  CatchPhotosStatus _status = CatchPhotosStatus.idle;
  String? _error;
  bool _uploading = false;

  List<CatchPhoto> get photos   => _photos;
  CatchPhotosStatus get status  => _status;
  String? get error             => _error;
  bool get uploading            => _uploading;

  // ── Carregar fotos próximas ────────────────────────────
  Future<void> loadNearby({
    required double lat,
    required double lng,
    double radiusKm = 20,
  }) async {
    _status = CatchPhotosStatus.loading;
    _error  = null;
    notifyListeners();
    try {
      _photos = await _repo.fetchNearby(lat: lat, lng: lng, radiusKm: radiusKm);
      _status = CatchPhotosStatus.idle;
    } catch (e) {
      _error  = e.toString();
      _status = CatchPhotosStatus.error;
    }
    notifyListeners();
  }

  // ── Upload de nova captura ─────────────────────────────
  Future<bool> upload({
    required LatLng location,
    required XFile photoFile,
    String? species,
    double? weightKg,
    String? lureType,
    String? technique,
    String? notes,
    CatchPrivacy privacy = CatchPrivacy.public,
  }) async {
    _uploading = true;
    _error     = null;
    notifyListeners();
    try {
      final photo = await _repo.create(
        location:  location,
        photoFile: photoFile,
        species:   species,
        weightKg:  weightKg,
        lureType:  lureType,
        technique: technique,
        notes:     notes,
        privacy:   privacy,
      );
      _photos = [photo, ..._photos];
      _uploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error     = e.toString();
      _uploading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Alterar privacidade ────────────────────────────────
  Future<void> changePrivacy(String id, CatchPrivacy privacy) async {
    await _repo.changePrivacy(id, privacy);
    _photos = _photos
        .map((p) => p.id == id ? p.copyWith(privacy: privacy) : p)
        .toList();
    notifyListeners();
  }

  // ── Apagar ─────────────────────────────────────────────
  Future<void> delete(String id) async {
    await _repo.delete(id);
    _photos = _photos.where((p) => p.id != id).toList();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
