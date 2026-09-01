import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// Edge Function server-side para o Vision Scanner (P1 — correção de segurança):
// a chave OPENAI_API_KEY nunca deve existir no cliente Flutter/APK.
// Fluxo: Flutter -> vision-scan (aqui) -> OpenAI -> devolve só os campos necessários.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Cliente já comprime a foto antes de enviar (ImagePicker maxWidth 1600, quality 82),
// por isso o payload real fica muito abaixo deste limite; a margem cobre fotos maiores.
const MAX_BASE64_LEN = 12_000_000; // ~9 MB decodificados
const ALLOWED_MIME = new Set(["image/jpeg", "image/png", "image/webp"]);

const SYSTEM_PROMPT = `És o motor de visão AQUANAUTIX. Identifica peixes do Atlântico NE / ibérico em contexto de pesca desportiva.
Responde APENAS com um objeto JSON válido (sem markdown), chaves exactas:
{"scientific_name":"","length_cm":null,"weight_kg":null,"confidence_0_100":0}

Regras:
- scientific_name: nome binomial latim quando possível (ex.: Dicentrarchus labrax). Se incerto, melhor esforço.
- length_cm: comprimento total estimado em cm, ou null se impossível.
- weight_kg: massa estimada em kg, ou null se impossível.
- confidence_0_100: 0–100 coerente com a nitidez da foto e incerteza.`;

type RequestBody = {
  image_base64?: string;
  mime_type?: string;
};

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function readNumber(v: unknown): number | null {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string") {
    const n = Number(v.replace(",", "."));
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "method_not_allowed" }, 405);
  }

  const apiKey = Deno.env.get("OPENAI_API_KEY");
  if (!apiKey) {
    console.error("vision-scan: OPENAI_API_KEY não configurada no ambiente da função");
    return jsonResponse({ error: "server_misconfigured" }, 500);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "invalid_json" }, 400);
  }

  const mimeType = (body.mime_type ?? "").toLowerCase().trim();
  const imageB64 = body.image_base64 ?? "";

  if (!ALLOWED_MIME.has(mimeType)) {
    return jsonResponse({ error: "unsupported_mime_type" }, 400);
  }
  if (typeof imageB64 !== "string" || imageB64.length === 0) {
    return jsonResponse({ error: "missing_image" }, 400);
  }
  if (imageB64.length > MAX_BASE64_LEN) {
    return jsonResponse({ error: "image_too_large" }, 413);
  }

  const model = Deno.env.get("OPENAI_CHAT_MODEL") || "gpt-4o";
  const dataUrl = `data:${mimeType};base64,${imageB64}`;

  const openAiBody = {
    model,
    response_format: { type: "json_object" },
    max_tokens: 400,
    temperature: 0.25,
    messages: [
      { role: "system", content: SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Analisa esta fotografia de peixe (captura ou na areia/rocha). Devolve só o JSON pedido.",
          },
          { type: "image_url", image_url: { url: dataUrl } },
        ],
      },
    ],
  };

  let openAiRes: Response;
  try {
    openAiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(openAiBody),
    });
  } catch (err) {
    console.error("vision-scan: falha ao contactar OpenAI", err);
    return jsonResponse({ error: "upstream_unreachable" }, 502);
  }

  if (!openAiRes.ok) {
    const text = await openAiRes.text().catch(() => "");
    console.error("vision-scan: OpenAI HTTP", openAiRes.status, text.slice(0, 500));
    return jsonResponse({ error: "upstream_error" }, 502);
  }

  let decoded: Record<string, unknown>;
  try {
    decoded = await openAiRes.json();
  } catch {
    return jsonResponse({ error: "upstream_invalid_response" }, 502);
  }

  const choices = decoded?.choices as Array<Record<string, unknown>> | undefined;
  const message = choices?.[0]?.message as Record<string, unknown> | undefined;
  const content = message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    return jsonResponse({ error: "empty_result" }, 502);
  }

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(content.trim());
  } catch {
    return jsonResponse({ error: "unparseable_result" }, 502);
  }

  const scientificName =
    typeof parsed.scientific_name === "string" && parsed.scientific_name.trim().length > 0
      ? parsed.scientific_name.trim()
      : null;
  const lengthCm = readNumber(parsed.length_cm);
  const weightKg = readNumber(parsed.weight_kg);
  const confidenceRaw = readNumber(parsed.confidence_0_100) ?? 50;
  const confidence = Math.max(0, Math.min(100, Math.round(confidenceRaw)));

  return jsonResponse(
    {
      scientific_name: scientificName,
      length_cm: lengthCm,
      weight_kg: weightKg,
      confidence_0_100: confidence,
    },
    200,
  );
});
