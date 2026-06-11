import 'package:flutter/foundation.dart';

import '../community/community_public_profile.dart';

/// Pedido de foco no mapa — coords + etiqueta opcional para o pin.
typedef MapFocusRequest = ({double lat, double lon, String? label});

/// Índice do tab em [AquanautixHome].
/// 7 tabs: Início(0) · Oráculo(1) · Mapa(2) · Vision(3) · Log(4) · Perfil(5) · Comunidade(6)
class HomeTabIndex {
  HomeTabIndex._();

  static const int inicioTabIndex   = 0;
  static const int oracleTabIndex   = 1;
  static const int mapTabIndex      = 2;
  static const int visionTabIndex   = 3;
  static const int logTabIndex      = 4;
  static const int profileTabIndex  = 5;
  static const int communityTabIndex = 6;

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);

  /// Abre pesquisa de local no Oráculo (modo planeamento).
  static final ValueNotifier<bool> pendingOraclePlaceSearch =
      ValueNotifier<bool>(false);

  /// Centrar mapa + pin de destaque (Spots em Destaque / VER NO MAPA).
  static final ValueNotifier<MapFocusRequest?> pendingMapFocus =
      ValueNotifier<MapFocusRequest?>(null);

  /// Perfil Ghost a abrir ao entrar no tab Comunidade (tap no Início).
  static final ValueNotifier<CommunityPublicProfile?> pendingCommunityProfile =
      ValueNotifier<CommunityPublicProfile?>(null);
}
