import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class FishingContext {
  final String country;
  final String region;
  final String species;

  const FishingContext({
    this.country = 'PT',
    this.region = 'SETUBAL',
    this.species = 'ROBALO',
  });

  FishingContext copyWith({
    String? country,
    String? region,
    String? species,
  }) {
    return FishingContext(
      country: (country ?? this.country).toUpperCase(),
      region: (region ?? this.region).toUpperCase(),
      species: (species ?? this.species).toUpperCase(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FishingContext &&
        other.country == country &&
        other.region == region &&
        other.species == species;
  }

  @override
  int get hashCode => Object.hash(country, region, species);
}

class FishingContextStore {
  FishingContextStore._();
  static final FishingContextStore instance = FishingContextStore._();

  static const _countryKey = 'fishing_context_country';
  static const _regionKey = 'fishing_context_region';
  static const _speciesKey = 'fishing_context_species';

  final ValueNotifier<FishingContext> value =
      ValueNotifier<FishingContext>(const FishingContext());

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final country = prefs.getString(_countryKey) ?? _countryFromDeviceLocale();
    final region = prefs.getString(_regionKey);
    final species = prefs.getString(_speciesKey);
    if (region == null && species == null && country == const FishingContext().country) {
      return;
    }

    value.value = value.value.copyWith(
      country: country,
      region: region,
      species: species,
    );
    await _persist(value.value);
  }

  void update({
    String? country,
    String? region,
    String? species,
  }) {
    final next = value.value.copyWith(
      country: country,
      region: region,
      species: species,
    );
    if (next == value.value) return;
    value.value = next;
    _persist(next);
  }

  void useDeviceCountry() {
    update(country: _countryFromDeviceLocale());
  }

  String detectedCountry() => _countryFromDeviceLocale();

  Future<void> _persist(FishingContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, ctx.country);
    await prefs.setString(_regionKey, ctx.region);
    await prefs.setString(_speciesKey, ctx.species);
  }

  String _countryFromDeviceLocale() {
    final code =
        PlatformDispatcher.instance.locale.countryCode?.toUpperCase() ?? 'PT';
    if (code == 'PT' || code == 'ES') return code;
    return 'PT';
  }
}
