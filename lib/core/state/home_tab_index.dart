import 'package:flutter/foundation.dart';

/// Índice do tab em [AquanautixHome].
/// 6 tabs: Início(0) · Oráculo(1) · Mapa(2) · Vision(3) · Log(4) · Perfil(5)
class HomeTabIndex {
  HomeTabIndex._();

  static const int inicioTabIndex   = 0;
  static const int oracleTabIndex   = 1;
  static const int mapTabIndex      = 2;
  static const int visionTabIndex   = 3;
  static const int logTabIndex      = 4;
  static const int profileTabIndex  = 5;

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
}
