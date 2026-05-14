/// Coordenadas aproximadas por região de contexto (fallback sem GPS).
class TideMapPreset {
  const TideMapPreset({
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  final double latitude;
  final double longitude;
  final String label;

  static TideMapPreset forRegion(String region) {
    switch (region.toUpperCase()) {
      case 'MAFRA':
        return const TideMapPreset(
          latitude: 38.962,
          longitude: -9.417,
          label: 'Ericeira · MAFRA',
        );
      case 'CASCAIS':
        return const TideMapPreset(
          latitude: 38.697,
          longitude: -9.422,
          label: 'Cascais · LISBOA',
        );
      case 'ABRANTES':
        return const TideMapPreset(
          latitude: 39.466,
          longitude: -8.198,
          label: 'Rio Tejo · ABRANTES',
        );
      case 'SETUBAL':
      default:
        return const TideMapPreset(
          latitude: 38.444,
          longitude: -9.101,
          label: 'Sesimbra · SETÚBAL',
        );
    }
  }

  static String timezoneForCountry(String country) {
    switch (country.toUpperCase()) {
      case 'ES':
        return 'Europe/Madrid';
      default:
        return 'Europe/Lisbon';
    }
  }
}
