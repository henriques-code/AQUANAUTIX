import 'package:shared_preferences/shared_preferences.dart';

/// Origem da localização usada no ecrã de marés (`region` = preset do contexto da app).
class TideLocationPrefs {
  TideLocationPrefs({
    required this.source,
    this.portId,
    this.savedGpsLat,
    this.savedGpsLng,
  });

  static const sourceRegion = 'region';
  static const sourcePort = 'port';
  static const sourceGps = 'gps';

  static const _kSource = 'tides_loc_source';
  static const _kPortId = 'tides_port_id';
  static const _kGpsLat = 'tides_gps_lat';
  static const _kGpsLng = 'tides_gps_lng';

  final String source;
  final String? portId;
  final double? savedGpsLat;
  final double? savedGpsLng;

  static Future<TideLocationPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kSource) ?? sourceRegion;
    final lat = p.getDouble(_kGpsLat);
    final lng = p.getDouble(_kGpsLng);
    return TideLocationPrefs(
      source: s,
      portId: p.getString(_kPortId),
      savedGpsLat: lat,
      savedGpsLng: lng,
    );
  }

  static Future<void> saveRegion() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSource, sourceRegion);
    await p.remove(_kPortId);
  }

  static Future<void> savePort(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSource, sourcePort);
    await p.setString(_kPortId, id);
  }

  static Future<void> saveGps(double lat, double lng) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kSource, sourceGps);
    await p.setDouble(_kGpsLat, lat);
    await p.setDouble(_kGpsLng, lng);
  }
}
