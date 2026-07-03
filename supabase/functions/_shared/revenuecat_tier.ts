/** Partilhado entre Edge Functions RevenueCat → user_profiles.tier */

export type AppTier = "FREE" | "PRO" | "ELITE";

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export function isSupabaseUserId(appUserId: string): boolean {
  if (!appUserId || appUserId.startsWith("$RCAnonymousID:")) return false;
  return UUID_RE.test(appUserId);
}

export function entitlementIds(): { pro: string; elite: string } {
  return {
    pro: Deno.env.get("REVENUECAT_ENTITLEMENT_PRO") ?? "pro",
    elite: Deno.env.get("REVENUECAT_ENTITLEMENT_ELITE") ?? "elite",
  };
}

type RcEntitlement = {
  expires_date: string | null;
  grace_period_expires_date?: string | null;
  product_identifier?: string;
};

type RcSubscriberResponse = {
  subscriber?: {
    entitlements?: Record<string, RcEntitlement>;
  };
};

function isEntitlementActive(ent: RcEntitlement | undefined): boolean {
  if (!ent) return false;
  const expiry = ent.grace_period_expires_date ?? ent.expires_date;
  if (expiry === null || expiry === undefined) return true;
  return new Date(expiry).getTime() > Date.now();
}

export function tierFromSubscriber(
  subscriber: RcSubscriberResponse["subscriber"],
): AppTier {
  const ids = entitlementIds();
  const entitlements = subscriber?.entitlements ?? {};

  if (isEntitlementActive(entitlements[ids.elite])) return "ELITE";
  if (isEntitlementActive(entitlements[ids.pro])) return "PRO";
  return "FREE";
}

export async function fetchRevenueCatTier(appUserId: string): Promise<AppTier> {
  const secret = Deno.env.get("REVENUECAT_SECRET_API_KEY");
  if (!secret) {
    throw new Error("REVENUECAT_SECRET_API_KEY not configured");
  }

  const res = await fetch(
    `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}`,
    {
      headers: {
        Authorization: `Bearer ${secret}`,
        "Content-Type": "application/json",
      },
    },
  );

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`RevenueCat API ${res.status}: ${body.slice(0, 200)}`);
  }

  const data = (await res.json()) as RcSubscriberResponse;
  return tierFromSubscriber(data.subscriber);
}

export async function applyTierToProfile(
  supabase: {
    rpc: (
      fn: string,
      args: Record<string, unknown>,
    ) => PromiseLike<{ error: { message: string } | null }>;
  },
  userId: string,
  tier: AppTier,
): Promise<void> {
  const { error } = await supabase.rpc("sync_user_subscription_tier", {
    p_user_id: userId,
    p_tier: tier,
  });
  if (error) {
    throw new Error(`sync_user_subscription_tier: ${error.message}`);
  }
}

export function verifyWebhookAuthorization(req: Request): boolean {
  const expected = Deno.env.get("REVENUECAT_WEBHOOK_AUTHORIZATION");
  if (!expected) return false;

  const auth = req.headers.get("Authorization") ?? "";
  if (auth === expected) return true;
  if (auth === `Bearer ${expected}`) return true;
  return false;
}

export type RevenueCatWebhookBody = {
  api_version?: string;
  event?: {
    type?: string;
    app_user_id?: string;
    original_app_user_id?: string;
    entitlement_ids?: string[];
  };
};
