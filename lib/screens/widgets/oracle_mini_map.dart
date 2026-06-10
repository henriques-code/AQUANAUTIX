import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../_shared.dart';
import 'aqx_pressable.dart';

/// Mini-mapa contextual no Oráculo (~140px) — pin GPS ou planeamento + CTA.
class OracleMiniMap extends StatelessWidget {
  const OracleMiniMap({
    super.key,
    required this.lat,
    required this.lon,
    required this.isPlanning,
    required this.isRio,
    required this.onViewMap,
    this.viewMapLabel = 'VER MAPA',
  });

  final double lat;
  final double lon;
  final bool isPlanning;
  final bool isRio;
  final VoidCallback onViewMap;
  final String viewMapLabel;

  static const _arcgisSatellite =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  Widget build(BuildContext context) {
    final center = LatLng(lat, lon);

    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kCyan.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              backgroundColor: kBg,
              initialCenter: center,
              initialZoom: isPlanning ? 11.0 : 12.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isRio
                    ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
                    : _arcgisSatellite,
                userAgentPackageName: 'com.example.aquanautix',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 28,
                    height: 28,
                    child: Icon(
                      isPlanning ? Icons.place_rounded : Icons.my_location_rounded,
                      color: isPlanning ? kAmber : kCyan,
                      size: 24,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: kBg.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (isPlanning ? kAmber : kCyan).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                isPlanning ? 'PLANEAMENTO' : 'GPS',
                style: mono(8, c: isPlanning ? kAmber : kCyan, ls: 0.4),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: AqxGlassButton(
              label: viewMapLabel,
              onTap: onViewMap,
              expand: false,
            ),
          ),
        ],
      ),
    );
  }
}
