import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// Compile-time SDK keys — fornecer via --dart-define, nunca commitar.
const _androidKey = String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');
const _iosKey = String.fromEnvironment('REVENUECAT_API_KEY_IOS');

// Identificadores de entitlement — override via --dart-define opcional.
const _entitlementPro = String.fromEnvironment(
  'REVENUECAT_ENTITLEMENT_PRO',
  defaultValue: 'pro',
);
const _entitlementElite = String.fromEnvironment(
  'REVENUECAT_ENTITLEMENT_ELITE',
  defaultValue: 'elite',
);

// Package identifiers — alinhados com offering `default` no dashboard RC.
const _pkgProMonthly = String.fromEnvironment(
  'REVENUECAT_PACKAGE_PRO_MONTHLY',
  defaultValue: 'pro_monthly',
);
const _pkgProAnnual = String.fromEnvironment(
  'REVENUECAT_PACKAGE_PRO_ANNUAL',
  defaultValue: 'pro_annual',
);
const _pkgEliteAnnual = String.fromEnvironment(
  'REVENUECAT_PACKAGE_ELITE_ANNUAL',
  defaultValue: 'elite_annual',
);

/// Erro tipado para operações RevenueCat — sem dependência de UI.
class RevenueCatException implements Exception {
  final String message;
  final PurchasesErrorCode? code;

  const RevenueCatException(this.message, {this.code});

  /// True quando o utilizador fechou o sheet de pagamento sem comprar.
  /// As camadas superiores não devem tratar isto como erro crítico.
  bool get isUserCancelled => code == PurchasesErrorCode.purchaseCancelledError;

  @override
  String toString() => 'RevenueCatException($code): $message';
}

/// Serviço RevenueCat — singleton puro sem UI.
///
/// Ciclo de vida:
///   1. [configure] uma vez no arranque (main.dart), antes de runApp.
///   2. Verificar [isConfigured] antes de chamar métodos de compra/restore
///      em contextos onde as keys podem estar ausentes (dev sem dart-defines).
class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  /// Identificadores de entitlement expostos para C3 (SubscriptionStore).
  static const entitlementPro = _entitlementPro;
  static const entitlementElite = _entitlementElite;

  bool _configured = false;

  /// Key activa conforme plataforma actual.
  String get _activeKey {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iosKey;
      case TargetPlatform.android:
      default:
        return _androidKey;
    }
  }

  /// True se a key da plataforma actual está presente (dart-define fornecido).
  /// False em dev sem keys ou em plataforma sem key configurada.
  bool get isConfigured => _activeKey.isNotEmpty;

  /// True após [configure] completar com sucesso (SDK pronto para chamadas).
  bool get isSdkReady => _configured;

  /// Configura o SDK RevenueCat. Idempotente — seguro chamar várias vezes.
  ///
  /// Retorna sem throw quando não há key (modo dev): a app funciona com
  /// SubscriptionStore local.
  Future<void> configure() async {
    if (_configured) return;
    if (!isConfigured) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }
    await Purchases.configure(PurchasesConfiguration(_activeKey));
    _configured = true;
  }

  /// Devolve o [CustomerInfo] actual (cache interno do SDK + refresh).
  ///
  /// Nota: [Purchases.getCustomerInfo] gere cache + refresh automático.
  /// [Purchases.syncPurchases] serve apenas para reconciliar compras feitas
  /// fora do SDK (ex. migração externa) — não é necessário aqui.
  Future<CustomerInfo> getCustomerInfo() async {
    _assertReady();
    try {
      return await Purchases.getCustomerInfo();
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  /// Devolve as Offerings configuradas no dashboard RevenueCat.
  /// Retorna null se não houver offerings publicadas.
  Future<Offerings?> getOfferings() async {
    _assertReady();
    try {
      return await Purchases.getOfferings();
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  /// Resumo para diagnóstico (dev / verify script).
  Future<({bool sdkReady, String? offeringId, int packageCount})> diagnostics() async {
    if (!isSdkReady) {
      return (sdkReady: false, offeringId: null, packageCount: 0);
    }
    try {
      final offerings = await getOfferings();
      final current = offerings?.current;
      return (
        sdkReady: true,
        offeringId: current?.identifier,
        packageCount: current?.availablePackages.length ?? 0,
      );
    } catch (_) {
      return (sdkReady: true, offeringId: null, packageCount: 0);
    }
  }

  /// Inicia a compra de um [Package]. Lança [RevenueCatException] em caso de
  /// erro; usar [RevenueCatException.isUserCancelled] para distinguir
  /// cancelamentos de erros reais.
  Future<CustomerInfo> purchasePackage(Package package) async {
    _assertReady();
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      return result.customerInfo;
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  /// Restaura compras anteriores e devolve o [CustomerInfo] actualizado.
  Future<CustomerInfo> restorePurchases() async {
    _assertReady();
    try {
      return await Purchases.restorePurchases();
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  /// Associa compras ao ID Supabase (restore cross-device).
  Future<CustomerInfo> logIn(String appUserId) async {
    _assertReady();
    try {
      final result = await Purchases.logIn(appUserId);
      return result.customerInfo;
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  /// Volta ao utilizador anónimo RC (logout Supabase).
  Future<CustomerInfo> logOut() async {
    _assertReady();
    try {
      return await Purchases.logOut();
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  /// Listener de actualizações de entitlement (compras, restore, expiração).
  void addCustomerInfoListener(void Function(CustomerInfo info) listener) {
    if (!_configured) return;
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  // ── Helpers puros ────────────────────────────────────────────────────────

  /// Chaves de plano usadas no paywall → package identifier RC.
  static String packageIdForPlanKey(String planKey) => switch (planKey) {
        'pro_monthly' => _pkgProMonthly,
        'pro_annual' => _pkgProAnnual,
        'elite_annual' => _pkgEliteAnnual,
        _ => '',
      };

  /// Resolve package por identifier configurado, depois por [PackageType].
  static Package? resolvePackage(
    Offerings? offerings, {
    required String planKey,
  }) {
    final current = offerings?.current;
    if (current == null) return null;

    final id = packageIdForPlanKey(planKey);
    if (id.isNotEmpty) {
      for (final p in current.availablePackages) {
        if (p.identifier == id) return p;
      }
    }

    return switch (planKey) {
      'pro_monthly' => current.monthly ?? _firstOfType(current, PackageType.monthly),
      'pro_annual' => current.annual ?? _firstOfType(current, PackageType.annual),
      'elite_annual' => _packageByHint(current, 'elite') ??
          _secondAnnualOrLast(current),
      _ => null,
    };
  }

  static Package? _firstOfType(Offering offering, PackageType type) {
    for (final p in offering.availablePackages) {
      if (p.packageType == type) return p;
    }
    return null;
  }

  static Package? _packageByHint(Offering offering, String hint) {
    for (final p in offering.availablePackages) {
      if (p.identifier.toLowerCase().contains(hint)) return p;
    }
    return null;
  }

  static Package? _secondAnnualOrLast(Offering offering) {
    Package? firstAnnual;
    for (final p in offering.availablePackages) {
      if (p.packageType == PackageType.annual) {
        if (firstAnnual != null) return p;
        firstAnnual = p;
      }
    }
    if (offering.availablePackages.isEmpty) return null;
    return offering.availablePackages.last;
  }

  /// True se o entitlement [entitlementId] está activo em [info].
  bool customerHasEntitlement(CustomerInfo info, String entitlementId) =>
      info.entitlements.active.containsKey(entitlementId);

  /// Mapa de todos os entitlements conhecidos → activo/inactivo.
  /// Usado por SubscriptionStore (C3) para mapear para SubscriptionPlan.
  Map<String, bool> entitlementStatus(CustomerInfo info) => {
        entitlementPro: customerHasEntitlement(info, entitlementPro),
        entitlementElite: customerHasEntitlement(info, entitlementElite),
      };

  // ── Privado ─────────────────────────────────────────────────────────────

  void _assertReady() {
    if (!_configured) {
      throw const RevenueCatException(
        'RevenueCatService.configure() não foi chamado ou não há API key.',
      );
    }
  }

  RevenueCatException _wrap(PlatformException e) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    return RevenueCatException(e.message ?? e.code, code: code);
  }
}
