import 'package:flutter/material.dart';

import '../../core/l10n/aqx_l10n.dart';
import '../../core/location/gps_access.dart';
import '../_shared.dart';
import 'aqx_pressable.dart';

/// Sheet ao entrar na app (ou no Oráculo) quando GPS bloqueado / negado.
class LocationAccessSheet extends StatelessWidget {
  const LocationAccessSheet({
    super.key,
    required this.status,
    required this.onEnableGps,
    required this.onSearchPlace,
  });

  final GpsAccessStatus status;
  final VoidCallback onEnableGps;
  final VoidCallback onSearchPlace;

  String _body(AqxL10n t) {
    switch (status) {
      case GpsAccessStatus.deniedForever:
        return t.gpsBlocked;
      case GpsAccessStatus.serviceOff:
        return t.gpsServiceOff;
      case GpsAccessStatus.denied:
      case GpsAccessStatus.granted:
        return t.gpsDenied;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AqxL10n(Localizations.localeOf(context).languageCode);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottom),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kAmber.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: kAmber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.locationPromptTitle,
                  style: orb(15, c: kAmber, fw: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_body(t), style: ibm(14, c: Colors.white70)),
          const SizedBox(height: 16),
          AqxNeonButton(
            label: t.enableLocation,
            icon: Icons.my_location_rounded,
            onTap: onEnableGps,
            pulse: false,
          ),
          const SizedBox(height: 8),
          AqxGlassButton(
            label: t.locationPromptChoosePlace,
            icon: Icons.search_rounded,
            onTap: onSearchPlace,
          ),
        ],
      ),
    );
  }
}
