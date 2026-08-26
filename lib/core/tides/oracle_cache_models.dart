import 'marine_bundle.dart';

/// Metadados de uma zona em cache offline (Oráculo COSTA).
class OracleCacheMeta {
  const OracleCacheMeta({
    required this.lat,
    required this.lon,
    required this.lang,
    required this.isPlanning,
    required this.label,
    required this.fetchedAt,
    required this.validUntil,
    this.tideSource = 'open_meteo',
    this.priority = 'normal',
  });

  final double lat;
  final double lon;
  final String lang;
  final bool isPlanning;
  final String label;
  final DateTime fetchedAt;
  final DateTime validUntil;
  final String tideSource;
  final String priority;

  bool get isExpired => DateTime.now().isAfter(validUntil);

  bool get isStale =>
      DateTime.now().difference(fetchedAt) > const Duration(hours: 6);

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lon': lon,
        'lang': lang,
        'isPlanning': isPlanning,
        'label': label,
        'fetchedAt': fetchedAt.toIso8601String(),
        'validUntil': validUntil.toIso8601String(),
        'tideSource': tideSource,
        'priority': priority,
      };

  factory OracleCacheMeta.fromJson(Map<String, dynamic> j) => OracleCacheMeta(
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        lang: j['lang'] as String? ?? 'pt',
        isPlanning: j['isPlanning'] as bool? ?? false,
        label: j['label'] as String? ?? '',
        fetchedAt: DateTime.parse(j['fetchedAt'] as String),
        validUntil: DateTime.parse(j['validUntil'] as String),
        tideSource: j['tideSource'] as String? ?? 'open_meteo',
        priority: j['priority'] as String? ?? 'normal',
      );
}

Map<String, dynamic> marineHourPointToJson(MarineHourPoint p) => {
      'time': p.time.toIso8601String(),
      'seaLevelMslM': p.seaLevelMslM,
      'temperatureC': p.temperatureC,
      'pressureHpa': p.pressureHpa,
    };

MarineHourPoint marineHourPointFromJson(Map<String, dynamic> j) =>
    MarineHourPoint(
      time: DateTime.parse(j['time'] as String),
      seaLevelMslM: (j['seaLevelMslM'] as num).toDouble(),
      temperatureC: (j['temperatureC'] as num?)?.toDouble(),
      pressureHpa: (j['pressureHpa'] as num?)?.toDouble(),
    );

/// Chave estável de zona (~100 m).
String oracleCacheZoneKey({
  required double lat,
  required double lon,
  required String lang,
  required bool isPlanning,
}) {
  final latR = (lat * 1000).round() / 1000;
  final lonR = (lon * 1000).round() / 1000;
  final mode = isPlanning ? 'plan' : 'gps';
  return '${lang}_${mode}_${latR}_$lonR';
}
