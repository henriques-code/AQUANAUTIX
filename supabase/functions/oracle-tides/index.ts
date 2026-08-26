import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import {
  fetchOpenMeteoSeaLevel,
  nearestPort,
  type TideHourlyPoint,
} from "../_shared/tides_ports.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type RequestBody = {
  latitude?: number;
  longitude?: number;
  timezone?: string;
  past_days?: number;
  forecast_days?: number;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const lat = Number(body.latitude);
  const lon = Number(body.longitude);
  const timezone = body.timezone ?? "Europe/Lisbon";
  const pastDays = Number(body.past_days ?? 1);
  const forecastDays = Number(body.forecast_days ?? 5);

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return new Response(JSON.stringify({ error: "latitude/longitude required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const port = nearestPort(lat, lon);
  const fetchedAt = new Date().toISOString();

  // Primário: maré no porto de referência oficial mais próximo (IH/Puertos).
  let hourly: TideHourlyPoint[] = await fetchOpenMeteoSeaLevel(
    port.latitude,
    port.longitude,
    timezone,
    pastDays,
    forecastDays,
    1800,
  );
  let source = "official_port_ref";

  // Fallback <2s: modelo global nas coordenadas exactas do utilizador (FES-equivalente).
  if (hourly.length === 0) {
    hourly = await fetchOpenMeteoSeaLevel(
      lat,
      lon,
      timezone,
      pastDays,
      forecastDays,
      1800,
    );
    source = "fes_global";
  }

  if (hourly.length === 0) {
    return new Response(JSON.stringify({ error: "Tide sources unavailable" }), {
      status: 502,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({
      source,
      portId: port.id,
      portLabel: port.fullLabel,
      portCountry: port.country,
      attribution:
        port.country === "PT"
          ? "Referência IH/IPMA · validar com tábua oficial"
          : "Referência Puertos del Estado · validar com tábua oficial",
      fetchedAt,
      hourly,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
