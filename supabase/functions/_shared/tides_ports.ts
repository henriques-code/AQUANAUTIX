/** Portos de referência IH (PT) / Puertos del Estado (ES) — espelha tide_reference_ports.dart */
export type ReferencePort = {
  id: string;
  shortLabel: string;
  fullLabel: string;
  latitude: number;
  longitude: number;
  country: "PT" | "ES";
};

export const REFERENCE_PORTS: ReferencePort[] = [
  { id: "pt_viana", shortLabel: "Viana", fullLabel: "Viana do Castelo", latitude: 41.693, longitude: -8.842, country: "PT" },
  { id: "pt_leixoes", shortLabel: "Leixões", fullLabel: "Leixões · Matosinhos", latitude: 41.182, longitude: -8.704, country: "PT" },
  { id: "pt_aveiro", shortLabel: "Aveiro", fullLabel: "Costa de Aveiro", latitude: 40.638, longitude: -8.745, country: "PT" },
  { id: "pt_nazare", shortLabel: "Nazaré", fullLabel: "Nazaré", latitude: 39.601, longitude: -9.071, country: "PT" },
  { id: "pt_peniche", shortLabel: "Peniche", fullLabel: "Peniche", latitude: 39.356, longitude: -9.381, country: "PT" },
  { id: "pt_ericeira", shortLabel: "Ericeira", fullLabel: "Ericeira", latitude: 38.963, longitude: -9.417, country: "PT" },
  { id: "pt_cascais", shortLabel: "Cascais", fullLabel: "Cascais", latitude: 38.697, longitude: -9.421, country: "PT" },
  { id: "pt_lisboa", shortLabel: "Lisboa", fullLabel: "Lisboa · estuário", latitude: 38.676, longitude: -9.146, country: "PT" },
  { id: "pt_sesimbra", shortLabel: "Sesimbra", fullLabel: "Sesimbra", latitude: 38.444, longitude: -9.101, country: "PT" },
  { id: "pt_sines", shortLabel: "Sines", fullLabel: "Sines", latitude: 37.956, longitude: -8.867, country: "PT" },
  { id: "pt_lagos", shortLabel: "Lagos", fullLabel: "Lagos", latitude: 37.108, longitude: -8.673, country: "PT" },
  { id: "pt_faro", shortLabel: "Faro", fullLabel: "Faro · Ria Formosa", latitude: 37.016, longitude: -7.936, country: "PT" },
  { id: "es_coruna", shortLabel: "Coruña", fullLabel: "A Coruña", latitude: 43.368, longitude: -8.402, country: "ES" },
  { id: "es_bilbao", shortLabel: "Bilbao", fullLabel: "Bilbao · Abra", latitude: 43.341, longitude: -3.035, country: "ES" },
  { id: "es_gijon", shortLabel: "Gijón", fullLabel: "Gijón", latitude: 43.559, longitude: -5.661, country: "ES" },
  { id: "es_santander", shortLabel: "Santander", fullLabel: "Santander", latitude: 43.459, longitude: -3.810, country: "ES" },
  { id: "es_cadiz", shortLabel: "Cádiz", fullLabel: "Cádiz", latitude: 36.536, longitude: -6.288, country: "ES" },
  { id: "es_huelva", shortLabel: "Huelva", fullLabel: "Huelva · estuário", latitude: 37.201, longitude: -6.934, country: "ES" },
];

export function nearestPort(lat: number, lon: number): ReferencePort {
  let best = REFERENCE_PORTS[0];
  let bestD = Number.POSITIVE_INFINITY;
  for (const p of REFERENCE_PORTS) {
    const d = haversineKm(lat, lon, p.latitude, p.longitude);
    if (d < bestD) {
      bestD = d;
      best = p;
    }
  }
  return best;
}

function haversineKm(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

export type TideHourlyPoint = { time: string; sea_level_m: number };

/** Open-Meteo marine — modelo oceânico global (fallback FES-equivalente). */
export async function fetchOpenMeteoSeaLevel(
  lat: number,
  lon: number,
  timezone: string,
  pastDays: number,
  forecastDays: number,
  timeoutMs = 1800,
): Promise<TideHourlyPoint[]> {
  const params = new URLSearchParams({
    latitude: String(lat),
    longitude: String(lon),
    timezone,
    past_days: String(Math.min(92, Math.max(0, pastDays))),
    forecast_days: String(Math.min(8, Math.max(0, forecastDays))),
    hourly: "sea_level_height_msl",
  });
  const url = `https://marine-api.open-meteo.com/v1/marine?${params}`;
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: ctrl.signal });
    if (!res.ok) return [];
    const body = await res.json();
    const hourly = body?.hourly;
    if (!hourly?.time || !hourly?.sea_level_height_msl) return [];
    const out: TideHourlyPoint[] = [];
    for (let i = 0; i < hourly.time.length; i++) {
      const v = hourly.sea_level_height_msl[i];
      if (v == null) continue;
      out.push({ time: hourly.time[i], sea_level_m: Number(v) });
    }
    return out;
  } catch {
    return [];
  } finally {
    clearTimeout(timer);
  }
}
