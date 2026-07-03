import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  applyTierToProfile,
  fetchRevenueCatTier,
  isSupabaseUserId,
  type RevenueCatWebhookBody,
  verifyWebhookAuthorization,
} from "../_shared/revenuecat_tier.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!verifyWebhookAuthorization(req)) {
    return new Response("Unauthorized", { status: 401 });
  }

  let body: RevenueCatWebhookBody;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const appUserId =
    body.event?.app_user_id ?? body.event?.original_app_user_id ?? "";

  if (!isSupabaseUserId(appUserId)) {
    // Anónimo RC ou ID não-Supabase — ignorar sem erro (RC espera 200).
    return new Response(JSON.stringify({ ok: true, skipped: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
    return new Response("Server misconfigured", { status: 500 });
  }

  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const tier = await fetchRevenueCatTier(appUserId);
    await applyTierToProfile(supabase, appUserId, tier);

    console.log(
      JSON.stringify({
        event: body.event?.type,
        app_user_id: appUserId,
        tier,
      }),
    );

    return new Response(
      JSON.stringify({ ok: true, tier, event: body.event?.type }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error("revenuecat-webhook error:", err);
    return new Response("Processing failed", { status: 500 });
  }
});
