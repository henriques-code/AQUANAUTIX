import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fishing_context_store.dart';

/// Locale da UI (PT/ES). Em modo GPS ao vivo, [applyGpsCountryIso2] alinha
/// idioma e `FishingContext.country` com o país detetado (Nominatim).
class AppLocaleStore extends ChangeNotifier {
  AppLocaleStore._();
  static final AppLocaleStore instance = AppLocaleStore._();

  static const _prefLang = 'aqx_ui_language_code';

  Locale _locale = const Locale('pt');
  Locale get locale => _locale;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefLang);
    if (code == 'es') {
      _locale = const Locale('es');
      FishingContextStore.instance.update(country: 'ES');
    } else if (code == 'pt') {
      _locale = const Locale('pt');
      FishingContextStore.instance.update(country: 'PT');
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefLang, _locale.languageCode);
  }

  /// Chamado quando o GPS ao vivo devolve país PT ou ES (ISO2 maiúsculas).
  void applyGpsCountryIso2(String? iso2) {
    if (iso2 == null) return;
    final u = iso2.toUpperCase();
    if (u != 'PT' && u != 'ES') return;
    final wantEs = u == 'ES';
    final nextLang = wantEs ? 'es' : 'pt';
    FishingContextStore.instance.update(country: u);
    if (_locale.languageCode == nextLang) return;
    _locale = Locale(nextLang);
    notifyListeners();
    unawaited(_persist());
  }
}
