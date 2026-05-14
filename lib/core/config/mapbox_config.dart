import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Token via --dart-define=MAPBOX_ACCESS_TOKEN=pk.ey... — nunca commitar.
const _mapboxToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

/// Token pk. para Mapbox SDK (`MapWidget`) e defines. Vazio se não passares `--dart-define`.
String get mapboxAccessToken => _mapboxToken;

/// Navigation Night: máximo contraste marítimo, alinha com Midnight Deep Sea.
const mapboxDarkStyleUri = 'mapbox://styles/mapbox/navigation-night-v1';

/// Satélite + ruas/labels (mesmo stack que o site — vista aérea real).
const mapboxSatelliteStreetsStyleUri = 'mapbox://styles/mapbox/satellite-streets-v12';

/// Topográfico exterior — ideal para água doce (rios, barragens), trilhos de acesso.
const mapboxOutdoorsStyleUri = 'mapbox://styles/mapbox/outdoors-v12';

/// Centro inicial: costa atlântica portuguesa · lon -9.0 lat 39.5 · zoom 7 · bearing 0.
const mapboxInitialCenter = (lon: -9.0, lat: 39.5);
const mapboxInitialZoom = 7.0;

bool get isMapboxConfigured => _mapboxToken.isNotEmpty;

/// Regista o token Mapbox globalmente. Síncrono; sem-op se token ausente.
void initMapboxIfConfigured() {
  if (!isMapboxConfigured) return;
  MapboxOptions.setAccessToken(_mapboxToken);
}
