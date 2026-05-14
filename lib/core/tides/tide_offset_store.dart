import 'package:shared_preferences/shared_preferences.dart';

import 'marine_bundle.dart';
import 'tide_location_prefs.dart';

/// Chave de armazenamento do ajuste temporal (minutos) por origem de local.
String tideOffsetStorageKey({
  required String locSource,
  String? portId,
}) {
  if (locSource == TideLocationPrefs.sourcePort && portId != null && portId.isNotEmpty) {
    return 'tide_off_$portId';
  }
  if (locSource == TideLocationPrefs.sourceGps) {
    return 'tide_off_gps';
  }
  return 'tide_off_region';
}

/// Desloca a série no eixo do tempo (fase) mantendo cotas — alinha horários a tábuas oficiais.
List<MarineHourPoint> shiftMarineSeriesMinutes(List<MarineHourPoint> raw, int minutes) {
  if (minutes == 0 || raw.isEmpty) return List<MarineHourPoint>.from(raw);
  final d = Duration(minutes: minutes);
  return raw
      .map(
        (p) => MarineHourPoint(
          time: p.time.add(d),
          seaLevelMslM: p.seaLevelMslM,
          temperatureC: p.temperatureC,
          pressureHpa: p.pressureHpa,
        ),
      )
      .toList();
}

class TideOffsetStore {
  TideOffsetStore._();

  static const int minMinutes = -180;
  static const int maxMinutes = 180;

  static Future<int> load(String key) async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(key);
    if (v == null) return 0;
    return v.clamp(minMinutes, maxMinutes);
  }

  static Future<void> save(String key, int minutes) async {
    final p = await SharedPreferences.getInstance();
    final m = minutes.clamp(minMinutes, maxMinutes);
    if (m == 0) {
      await p.remove(key);
    } else {
      await p.setInt(key, m);
    }
  }
}
