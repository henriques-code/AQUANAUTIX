import 'package:flutter/foundation.dart';

/// Índice do tab em [AquanautixHome].
/// 5 tabs: Oráculo(0) · Mapa(1) · Vision(2) · Log(3) · Perfil(4)
class HomeTabIndex {
  HomeTabIndex._();

  static const int oracleTabIndex = 0;
  static const int mapTabIndex    = 1;
  static const int visionTabIndex = 2;
  static const int logTabIndex    = 3;
  static const int profileTabIndex = 4;

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
}
