import 'package:flutter/foundation.dart';

/// Índice do tab em [AquanautixHome]. Com ecrã Início no índice 0, o Oráculo é 1.
class HomeTabIndex {
  HomeTabIndex._();

  static const int inicioTabIndex = 0;
  static const int oracleTabIndex = 1;
  static const int mapTabIndex = 2;
  static const int visionTabIndex = 3;
  static const int logTabIndex = 4;
  static const int profileTabIndex = 5;

  static final ValueNotifier<int> notifier = ValueNotifier<int>(0);
}
