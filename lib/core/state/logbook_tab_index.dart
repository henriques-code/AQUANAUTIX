import 'package:flutter/foundation.dart';

/// Sub-tab pendente no Logbook (0=minhas · 1=comunidade · 2=troféus).
class LogbookTabIndex {
  LogbookTabIndex._();

  static const int minhasTab = 0;
  static const int comunidadeTab = 1;
  static const int trofeusTab = 2;

  static final ValueNotifier<int?> pendingTab = ValueNotifier<int?>(null);
}
