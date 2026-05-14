/// Dia Juliano (UTC) a partir do contador interno.
/// JD 2440587.5 = 1970-01-01 00:00 UTC (epoch Unix).
double julianDayUtc(DateTime utc) {
  final u = utc.toUtc();
  return u.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
}

/// Nova de referência para o ciclo sinódico — 2000-01-06 18:14 UTC.
double referenceNewMoonJd2000() {
  final ref = DateTime.utc(2000, 1, 6, 18, 14);
  return ref.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
}

/// Idade da lua no ciclo sinódico 0–1 (nova → cheia → nova).
double synodicMoonPhase01(DateTime utc) {
  const synodic = 29.530588861;
  final jd = julianDayUtc(utc);
  final ref = referenceNewMoonJd2000();
  var frac = ((jd - ref) / synodic) % 1.0;
  if (frac < 0) frac += 1.0;
  return frac;
}
