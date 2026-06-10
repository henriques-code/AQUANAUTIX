import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fishing_context_store.dart';

/// Locale da UI (PT/ES/EN). Em modo GPS ao vivo, [applyGpsCountryIso2] alinha
/// idioma e `FishingContext.country` com o país detetado (Nominatim), salvo
/// escolha manual em [setLocale].
class AppLocaleStore extends ChangeNotifier {
  AppLocaleStore._();
  static final AppLocaleStore instance = AppLocaleStore._();

  static const _prefLang = 'aqx_ui_language_code';
  static const _prefUserChose = 'aqx_ui_language_user_chose';

  Locale _locale = const Locale('pt');
  bool _userChoseLocale = false;

  Locale get locale => _locale;
  bool get userChoseLocale => _userChoseLocale;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    final code = p.getString(_prefLang);
    _userChoseLocale = p.getBool(_prefUserChose) ?? false;
    if (code == 'es') {
      _locale = const Locale('es');
      if (_userChoseLocale) {
        FishingContextStore.instance.update(country: 'ES');
      }
    } else if (code == 'en') {
      _locale = const Locale('en');
    } else if (code == 'pt') {
      _locale = const Locale('pt');
      if (_userChoseLocale) {
        FishingContextStore.instance.update(country: 'PT');
      }
    }
    notifyListeners();
  }

  /// Escolha explícita (ex.: login). Persiste e bloqueia override por GPS.
  Future<void> setLocale(String code, {bool userChose = true}) async {
    final normalized = switch (code) {
      'es' => 'es',
      'en' => 'en',
      _ => 'pt',
    };
    _locale = Locale(normalized);
    if (userChose) {
      _userChoseLocale = true;
      if (normalized == 'es') {
        FishingContextStore.instance.update(country: 'ES');
      } else if (normalized == 'pt') {
        FishingContextStore.instance.update(country: 'PT');
      }
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefLang, _locale.languageCode);
    await p.setBool(_prefUserChose, _userChoseLocale);
  }

  /// Chamado quando o GPS ao vivo devolve país PT ou ES (ISO2 maiúsculas).
  void applyGpsCountryIso2(String? iso2) {
    if (_userChoseLocale) return;
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
