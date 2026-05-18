import 'package:flutter/widgets.dart';

/// Textos PT/ES para pipeline do Oráculo e UI principal (GPS ibérico).
class AqxL10n {
  AqxL10n(this.lang);
  final String lang;
  bool get es => lang == 'es';

  // ── GPS / erros ─────────────────────────────────────────
  String get gpsDenied => es
      ? 'Permite el acceso a la ubicación para calcular marea y tiempo en el sitio donde vas a pescar.'
      : 'Permite o acesso à localização para calcular maré e tempo no sítio onde vais pescar.';

  String get gpsBlocked => es
      ? 'La ubicación está bloqueada para AQUANAUTIX. Abre Ajustes y activa el permiso para ver el índice en tu zona.'
      : 'A localização está bloqueada para AQUANAUTIX. Abre Definições e activa a permissão para ver o índice na tua zona.';

  String get gpsServiceOff => es
      ? 'Activa el GPS del móvil para obtener condiciones en la posición donde vas a pescar.'
      : 'Activa o GPS no telemóvel para obter condições na posição onde vais pescar.';

  String get gpsFixFailed => es
      ? 'No se pudo obtener tu posición. Sal al exterior o a la ventana, espera el fix GPS e inténtalo de nuevo.'
      : 'Não foi possível obter a tua posição. Vai para o exterior ou à janela, espera o GPS fixar e tenta de novo.';

  // ── Cabeçalhos / planeamento ────────────────────────────
  String get yourPosition => es ? 'En tu posición' : 'À tua posição';

  String planningSubtitle(double lat, double lon) => es
      ? 'Modo planificación · ${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}° · Open‑Meteo'
      : 'Modo planeamento · ${lat.toStringAsFixed(3)}°, ${lon.toStringAsFixed(3)}° · Open‑Meteo';

  String get tideActive => es ? 'Marea activa' : 'Maré activa';

  String tideWithPhase(String phaseWord) =>
      es ? 'Marea $phaseWord' : 'Maré $phaseWord';

  String get slackWater => es ? 'Marea muerta' : 'Vau-mar';

  String get highTide => es ? 'Pleamar' : 'Preia-mar';

  String get lowTide => es ? 'Bajamar' : 'Baixa-mar';

  /// Fases devolvidas por [tidePhaseBetween] em PT.
  String mapTidePhaseWord(String ptPhase) {
    if (!es) return ptPhase;
    switch (ptPhase) {
      case 'Enchente':
        return 'creciente';
      case 'Vazante':
        return 'vaciante';
      default:
        return ptPhase;
    }
  }

  String moonLong(double moonPhase01) {
    if (moonPhase01 < 0.1 || moonPhase01 > 0.9) {
      return es ? 'luna nueva' : 'lua nova';
    }
    if (moonPhase01 < 0.4) return es ? 'luna creciente' : 'lua crescente';
    if (moonPhase01 < 0.6) return es ? 'luna llena' : 'lua cheia';
    return es ? 'luna menguante' : 'lua minguante';
  }

  String moonTileShort(double moonPhase01) {
    if (moonPhase01 < 0.1 || moonPhase01 > 0.9) return es ? 'Nueva' : 'Nova';
    if (moonPhase01 < 0.4) return es ? 'Creciente' : 'Crescente';
    if (moonPhase01 < 0.6) return es ? 'Llena' : 'Cheia';
    return es ? 'Menguante' : 'Minguante';
  }

  String get janelaPro => es
      ? 'Activa alertas PRO para notificación de ventana.'
      : 'Activa alertas PRO para notificação de janela.';

  String janelaLine(String dayLbl, String window, int score, String placeShort) {
    if (es) {
      return '$dayLbl $window — índice $score/100 cerca de $placeShort.';
    }
    return '$dayLbl $window — índice $score/100 perto de $placeShort.';
  }

  String get todayShort => es ? 'HOY' : 'HOJ';

  String weekdayShort(int weekday) {
    if (es) {
      const labels = ['', 'LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
      return (weekday >= 1 && weekday <= 7) ? labels[weekday] : '—';
    }
    const labels = ['', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'];
    return (weekday >= 1 && weekday <= 7) ? labels[weekday] : '—';
  }

  String scoreLabel(int s) {
    if (s >= 80) return 'EXCELENTE';
    if (s >= 65) return es ? 'BUENO' : 'BOM';
    if (s >= 45) return 'MODERADO';
    return es ? 'DÉBIL' : 'FRACO';
  }

  // ── Tendências / tempo (marinho) ─────────────────────────
  String get tideRising => es ? 'Subiendo ↑' : 'A subir ↑';

  String get tideFalling => es ? 'Bajando ↓' : 'A descer ↓';

  String get tideFlat => es ? 'Plano →' : 'Plano →';

  String get tempWarming => es ? 'Calentando ↑' : 'A aquecer ↑';

  String get tempCooling => es ? 'Enfriando ↓' : 'A arrefecer ↓';

  String get tempStable => es ? 'Estable →' : 'Estável →';

  String get pressureDash => es ? 'presión —' : 'pressão —';

  String get pressureStable => es ? 'presión estable' : 'pressão estável';

  String get pressureVariable => es ? 'presión variable' : 'pressão variável';

  String get pressureStableShort => es ? '↗ Estable' : '↗ Estável';

  String get pressureVariableShort => es ? '⇄ Variable' : '⇄ Variável';

  // ── Rio / céu ───────────────────────────────────────────
  String get weatherVariable => es ? 'Tiempo variable' : 'Tempo variável';

  String get skyClear => es ? 'Cielo claro' : 'Céu claro';

  String get skyMedium => es ? 'Nubes medias' : 'Nuvens médias';

  String get skyOvercast => es ? 'Cielo cubierto' : 'Céu encoberto';

  String get riverUpdating => es ? 'Datos en actualización' : 'Dados em atualização';

  String get riverHumid => es ? 'Húmedo' : 'Húmido';

  String get riverWet => es ? 'Mojado' : 'Molhado';

  String get riverDry => es ? 'Seco' : 'Seco';

  String get rainIncreasing => es ? 'Lluvia a más ↑' : 'Chuva a intensificar ↑';

  String get rainDecreasing => es ? 'Lluvia a menos ↓' : 'Chuva a diminuir ↓';

  String get precipStable => es ? 'Precipitación estable →' : 'Precipitação estável →';

  String get visGood => es ? 'Buena' : 'Boa';

  String get visFewClouds => es ? 'Pocas nubes' : 'Poucas nuvens';

  String get visMedium => es ? 'Media' : 'Média';

  String get visMediumCloud => es ? 'Nubosidad media' : 'Nebulosidade média';

  String get visLow => es ? 'Baja' : 'Baixa';

  String get visHeavyCloud => es ? 'Muy nublado' : 'Muito nublado';

  String get snirhSoon => es
      ? 'GloFAS · sin datos fluviales aquí'
      : 'GloFAS · sem dados fluviais aqui';

  /// Fonte do caudal com tendência: "GloFAS · Copernicus ↑"
  String caudalSource(String trendIcon) => es
      ? 'GloFAS · Copernicus $trendIcon'
      : 'GloFAS · Copernicus $trendIcon';

  // ── Home / Oráculo UI ───────────────────────────────────
  String get tabOracle => 'ORÁCULO';
  String get tabMap => 'MAPA';
  String get tabVision => es ? 'VISIÓN' : 'VISION';
  String get tabLog => es ? 'DIARIO' : 'LOG';
  String get tabProfile => es ? 'PERFIL' : 'PERFIL';

  String get tabHome => es ? 'INICIO' : 'INÍCIO';

  String get homeTagline =>
      es ? '¿Listo para otra aventura?' : 'Pronto para mais uma aventura?';

  String get homeSectionConditions =>
      es ? 'Condiciones favorables' : 'Condições Favoráveis';

  String get homeSectionSpots => es ? 'Spots destacados' : 'Spots em Destaque';

  String get homeSectionCommunity =>
      es ? 'Actividad de la comunidad' : 'Atividade da Comunidade';

  String get homeVerTodas => es ? 'Ver todas >' : 'Ver todas >';

  String get homeVerMapa => es ? 'Ver mapa >' : 'Ver mapa >';

  String get homeLoadError =>
      es ? 'No se pudo cargar el inicio.' : 'Não foi possível carregar o início.';

  String get homeRetry => es ? 'Reintentar' : 'Tentar novamente';

  String get homeStatWind => es ? 'Viento' : 'Vento';
  String get homeStatWaves => es ? 'Oleaje' : 'Ondas';
  String get homeStatTide => es ? 'Marea' : 'Maré';
  String get homeStatMoon => es ? 'Luna' : 'Lua';
  String get homeStatSolunar => es ? 'Actividad Solunar' : 'Actividade Solunar';

  /// Saudação dinâmica (hora local) + emoji, alinhada ao mockup Início.
  String homeGreetingLine(int hour) {
    final g = greeting(hour);
    if (es) return '$g, pescador! 🎣';
    return '$g, Pescador! 🎣';
  }

  String homeGreetingPersonalized(int hour, String name) {
    final g = greeting(hour);
    final n = name.trim().isEmpty ? (es ? 'pescador' : 'Pescador') : name.trim();
    if (es) return '$g, $n! 🎣';
    if (n.length == 1) return '$g, ${n.toUpperCase()}! 🎣';
    return '$g, ${n[0].toUpperCase()}${n.substring(1)}! 🎣';
  }

  String greeting(int hour) {
    if (hour < 12) return es ? 'Buenos días' : 'Bom dia';
    if (hour < 19) return es ? 'Buenas tardes' : 'Boa tarde';
    return es ? 'Buenas noches' : 'Boa noite';
  }

  String get fisherSuffix => es ? ', pescador' : ', pescador';

  String get costa => 'COSTA';
  String get rio => es ? 'RÍO' : 'RIO';

  String get positionGpsLive =>
      es ? 'Posición GPS (en vivo)' : 'Posição GPS (ao vivo)';

  String get forecastHeader =>
      es ? '// PREVISIÓN 5 DÍAS · ÍNDICE 0–100' : '// PREVISÃO 5 DIAS · ÍNDICE 0–100';

  String get pushGoldenPro =>
      es ? 'Push ventana de oro · PRO' : 'Push Janela de Ouro · PRO';

  String get activate => es ? 'ACTIVAR' : 'ATIVAR';

  String get rigCardTitle =>
      es ? 'ISCO + CAÑA + TÉCNICA' : 'ISCO + CANA + TÉCNICA';

  String get rigMoreActive => es ? 'Más activas' : 'Mais activas';

  /// Etiqueta néon ao lado de «Mais activas» (cartão isco/cana).
  String get rigActivityNeon => es ? 'Actividad' : 'Actividade';

  String get rigBait => es ? 'Cebos' : 'Isco';

  String get rigRod => es ? 'Caña' : 'Cana';

  String get rigTechnique => es ? 'Técnica' : 'Técnica';

  String get rigDistance => es ? 'Distancia' : 'Distância';

  String get bestWindow => es ? 'Mejor ventana' : 'Melhor janela';

  String get metricTide => es ? 'MAREA' : 'MARÉ';

  String get metricWaterTemp => es ? 'TEMP. AGUA' : 'TEMP. ÁGUA';

  String get metricPressure => es ? 'PRESIÓN' : 'PRESSÃO';

  String get metricMoon => es ? 'LUNA' : 'LUA';

  String get metricFlow => es ? 'CAUDAL' : 'CAUDAL';

  String get metricLevel => es ? 'NIVEL' : 'NÍVEL';

  String get metricVis => es ? 'VISIB.' : 'VISIB.';

  String get indexWhat => es ? '¿Qué es el índice?' : 'O que é o índice?';

  String get understood => es ? 'Entendido' : 'Percebi';

  String get search => es ? 'Buscar' : 'Pesquisar';

  String get settings => es ? 'Ajustes' : 'Definições';

  String get retry => es ? 'Reintentar' : 'Tentar';

  String get searchPlace => es ? 'Buscar lugar' : 'Pesquisar local';

  String get useMyGps =>
      es ? 'Usar mi posición (GPS)' : 'Usar a minha posição (GPS)';

  String get activityVeryHigh => es ? 'Muy activo' : 'Muito activo';

  String get activityGood => es ? 'Buena' : 'Boa';

  String get activityModerate => es ? 'Moderada' : 'Moderada';

  String get activityLow => es ? 'Baja' : 'Baixa';

  // ── Erros genéricos (Oráculo) ────────────────────────────
  String get errNoNetwork =>
      es ? 'Sin conexión a internet.' : 'Sem ligação à internet.';

  String get errTimeout =>
      es ? 'Tiempo de espera agotado.' : 'Tempo limite esgotado.';

  String get errService =>
      es ? 'Servicio temporalmente no disponible.' : 'Serviço temporariamente indisponível.';

  String get errGeneric =>
      es ? 'No se pudieron cargar los datos.' : 'Não foi possível carregar dados.';

  String get goldenWindowTitle => es ? 'Ventana de oro ' : 'Janela de Ouro ';

  String get alertsProConfigSoon => es
      ? 'Alertas PRO — configuración detallada en breve.'
      : 'Alertas PRO — configuração detalhada em breve.';

  String pushDemoBody(String spotHint) => es
      ? 'Recibe alerta cuando el índice suba cerca de $spotHint · demo'
      : 'Recebe alerta quando o índice disparar perto de $spotHint · demo';

  String get riverTagusDemo => es ? 'Río Tajo' : 'Rio Tejo';

  String get searchHint => es ? 'Ej.: Nazaré, Sagres, Vigo…' : 'Ex.: Nazaré, Sagres, Vigo…';

  String get searchFailed =>
      es ? 'Error al buscar.' : 'Erro ao pesquisar.';

  String noResultsFor(String q) =>
      es ? 'Sin resultados para "$q".' : 'Sem resultados para "$q".';

  String get fishActivityTitle =>
      es ? 'Actividad del pez' : 'Actividade do peixe';

  String get alertZone => es ? 'tu zona' : 'a tua zona';

  String get alertYou => 'ti';

  String get indexCardSubtitle => es
      ? 'Índice AQUANAUTIX · hoy (0–100)'
      : 'Índice AQUANAUTIX · hoje (0–100)';

  // ── Mapa — legenda dos pins ─────────────────────────────
  String get mapLegendSavedSpot =>
      es ? 'Mi spot (foto)' : 'Meu spot (foto)';

  String get mapLegendBaitOpen =>
      es ? 'Isco ≤5 km' : 'Isco ≤5 km';

  String get mapLegendCommunity =>
      es ? 'Comunidad' : 'Comunidade';

  String get mapLegendProSpot =>
      es ? 'Spot PRO' : 'Spot PRO';

  String get mapLegendEliteSpot =>
      es ? 'Spot ELITE' : 'Spot ELITE';

  String get indexHelpBody => es
      ? 'El número de 0 a 100 es el Índice AQUANAUTIX de hoy: combina la marea '
          '(amplitud respecto a los días cercanos), la fase lunar y el comportamiento '
          'de la presión atmosférica.\n\n'
          'El índice se calcula para tu posición GPS — sin ubicación activa no hay '
          'una lectura fiable del sitio donde vas a pescar.\n\n'
          'No garantiza pez a la hora — es una lectura rápida para ver si las '
          'condiciones están alineadas con tu especie objetivo.\n\n'
          '• 80+ condiciones muy favorables\n'
          '• 65–79 buenas\n'
          '• 45–64 moderadas\n'
          '• por debajo de 45 débiles'
      : 'O número de 0 a 100 é o Índice AQUANAUTIX para hoje: combina a maré '
          '(amplitude face aos dias próximos), a fase lunar e o comportamento da '
          'pressão atmosférica.\n\n'
          'O índice é calculado para a tua posição GPS — sem localização activa não '
          'há leitura fiável para o sítio onde vais pescar.\n\n'
          'Não é garantia de peixe na hora — é uma leitura rápida para perceber se '
          'as condições estão alinhadas para a tua espécie alvo.\n\n'
          '• 80+ condições muito favoráveis\n'
          '• 65–79 boas\n'
          '• 45–64 moderadas\n'
          '• abaixo de 45 fracas';
}

AqxL10n aqxL10nOf(BuildContext context) =>
    AqxL10n(Localizations.localeOf(context).languageCode);
