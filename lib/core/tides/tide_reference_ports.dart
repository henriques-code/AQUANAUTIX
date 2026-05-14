/// Pontos costeiros de referência (coordenadas públicas aproximadas) para alinhar
/// o modelo marinho ao sítio onde pescas — cruza sempre com tábuas oficiais DHM/IPMA.
class TideReferencePort {
  const TideReferencePort({
    required this.id,
    required this.shortLabel,
    required this.fullLabel,
    required this.latitude,
    required this.longitude,
    required this.country,
  });

  final String id;
  final String shortLabel;
  final String fullLabel;
  final double latitude;
  final double longitude;
  /// `PT` ou `ES`
  final String country;

  static const List<TideReferencePort> all = [
    TideReferencePort(
      id: 'pt_viana',
      shortLabel: 'Viana',
      fullLabel: 'Viana do Castelo',
      latitude: 41.693,
      longitude: -8.842,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_leixoes',
      shortLabel: 'Leixões',
      fullLabel: 'Leixões · Matosinhos',
      latitude: 41.182,
      longitude: -8.704,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_aveiro',
      shortLabel: 'Aveiro',
      fullLabel: 'Costa de Aveiro',
      latitude: 40.638,
      longitude: -8.745,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_nazare',
      shortLabel: 'Nazaré',
      fullLabel: 'Nazaré',
      latitude: 39.601,
      longitude: -9.071,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_peniche',
      shortLabel: 'Peniche',
      fullLabel: 'Peniche',
      latitude: 39.356,
      longitude: -9.381,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_ericeira',
      shortLabel: 'Ericeira',
      fullLabel: 'Ericeira',
      latitude: 38.963,
      longitude: -9.417,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_cascais',
      shortLabel: 'Cascais',
      fullLabel: 'Cascais',
      latitude: 38.697,
      longitude: -9.421,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_lisboa',
      shortLabel: 'Lisboa',
      fullLabel: 'Lisboa · estuário',
      latitude: 38.676,
      longitude: -9.146,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_sesimbra',
      shortLabel: 'Sesimbra',
      fullLabel: 'Sesimbra',
      latitude: 38.444,
      longitude: -9.101,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_sines',
      shortLabel: 'Sines',
      fullLabel: 'Sines',
      latitude: 37.956,
      longitude: -8.867,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_lagos',
      shortLabel: 'Lagos',
      fullLabel: 'Lagos',
      latitude: 37.108,
      longitude: -8.673,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'pt_faro',
      shortLabel: 'Faro',
      fullLabel: 'Faro · Ria Formosa',
      latitude: 37.016,
      longitude: -7.936,
      country: 'PT',
    ),
    TideReferencePort(
      id: 'es_coruna',
      shortLabel: 'Coruña',
      fullLabel: 'A Coruña',
      latitude: 43.368,
      longitude: -8.402,
      country: 'ES',
    ),
    TideReferencePort(
      id: 'es_bilbao',
      shortLabel: 'Bilbao',
      fullLabel: 'Bilbao · Abra',
      latitude: 43.341,
      longitude: -3.035,
      country: 'ES',
    ),
    TideReferencePort(
      id: 'es_gijon',
      shortLabel: 'Gijón',
      fullLabel: 'Gijón',
      latitude: 43.559,
      longitude: -5.661,
      country: 'ES',
    ),
    TideReferencePort(
      id: 'es_santander',
      shortLabel: 'Santander',
      fullLabel: 'Santander',
      latitude: 43.459,
      longitude: -3.810,
      country: 'ES',
    ),
    TideReferencePort(
      id: 'es_cadiz',
      shortLabel: 'Cádiz',
      fullLabel: 'Cádiz',
      latitude: 36.536,
      longitude: -6.288,
      country: 'ES',
    ),
    TideReferencePort(
      id: 'es_huelva',
      shortLabel: 'Huelva',
      fullLabel: 'Huelva · estuário',
      latitude: 37.201,
      longitude: -6.934,
      country: 'ES',
    ),
  ];

  static TideReferencePort? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static List<TideReferencePort> forCountry(String country) {
    final c = country.toUpperCase();
    return all.where((p) => p.country == c).toList();
  }

  static List<TideReferencePort> forDisplay(String country) {
    final c = country.toUpperCase();
    if (c == 'ES') return forCountry('ES');
    return forCountry('PT');
  }
}
