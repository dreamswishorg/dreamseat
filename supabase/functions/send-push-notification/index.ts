// Supabase Edge Function: send-push-notification
// Sends Firebase Cloud Messaging (FCM) push notifications using the HTTP v1 API
// Deploy: supabase functions deploy send-push-notification
//
// IMPORTANT: Set secrets before deploying:
// supabase secrets set FCM_PROJECT_ID=dreamseat-75ed1
// supabase secrets set FCM_CLIENT_EMAIL=firebase-adminsdk-fbsvc@dreamseat-75ed1.iam.gserviceaccount.com
// supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID") ?? "dreamseat-75ed1";
const FCM_CLIENT_EMAIL = Deno.env.get("FCM_CLIENT_EMAIL") ??
  "firebase-adminsdk-fbsvc@dreamseat-75ed1.iam.gserviceaccount.com";
const FCM_PRIVATE_KEY = (Deno.env.get("FCM_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n");

/** Generates a short-lived Google OAuth2 access token from the service account. */
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // Import the RSA private key
  const keyData = FCM_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: FCM_CLIENT_EMAIL,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: getNumericDate(0),
      exp: getNumericDate(3600),
    },
    cryptoKey
  );

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get FCM access token: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

/** Sends an FCM notification to a single device token. */
async function sendToToken(
  accessToken: string,
  deviceToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const message: Record<string, unknown> = {
    token: deviceToken,
    notification: { title, body },
    android: {
      notification: {
        icon: "ic_notification",
        color: "#2E7D32",
        channel_id: "dreameats_default",
        priority: "HIGH",
        sound: "default",
      },
      priority: "HIGH",
    },
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  if (data) message.data = data;

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    }
  );

  if (!res.ok) {
    const err = await res.json();
    console.error("FCM send error:", JSON.stringify(err));
    return false;
  }

  const result = await res.json();
  console.log("FCM sent:", result.name);
  return true;
}

/** Sends FCM notification to a topic (e.g., 'all_customers', 'all_merchants'). */
async function sendToTopic(
  accessToken: string,
  topic: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<boolean> {
  const message: Record<string, unknown> = {
    topic,
    notification: { title, body },
    android: {
      notification: {
        icon: "ic_notification",
        color: "#2E7D32",
        channel_id: "dreameats_default",
        priority: "HIGH",
      },
    },
  };

  if (data) message.data = data;

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ message }),
    }
  );

  return res.ok;
}

// ── Request payload types ────────────────────────────────────────────────────
// Single device:  { type: "token",  token, title, body, data? }
// Topic broadcast:{ type: "topic",  topic, title, body, data? }
// Predefined:     { type: "order_confirmed", ...order data }
//                 { type: "new_order_merchant", ...order data }
//                 { type: "deal_expiring", ...deal data }
//                 { type: "merchant_approved" }

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const payload = await req.json();
    const accessToken = await getAccessToken();

    let success = false;

    if (payload.type === "token" && payload.token) {
      // Direct device notification
      success = await sendToToken(
        accessToken,
        payload.token,
        payload.title,
        payload.body,
        payload.data
      );
    } else if (payload.type === "topic" && payload.topic) {
      // Topic broadcast (all customers, all merchants, etc.)
      success = await sendToTopic(
        accessToken,
        payload.topic,
        payload.title,
        payload.body,
        payload.data
      );
    } else if (payload.type === "order_confirmed" && payload.token) {
      // Customer: order confirmation
      success = await sendToToken(
        accessToken,
        payload.token,
        "✅ Order Confirmed!",
        `Your ${payload.dealTitle} from ${payload.businessName} is reserved. Code: ${payload.collectionCode}`,
        {
          type: "order_confirmed",
          orderId: payload.orderId ?? "",
          screen: "order_history",
        }
      );
    } else if (payload.type === "new_order_merchant" && payload.token) {
      // Merchant: new order received
      success = await sendToToken(
        accessToken,
        payload.token,
        "🛍️ New Order!",
        `${payload.customerName} reserved your ${payload.dealTitle}. Pickup code: ${payload.collectionCode}`,
        {
          type: "new_order",
          orderId: payload.orderId ?? "",
          screen: "merchant_orders",
        }
      );
    } else if (payload.type === "deal_expiring" && payload.topic) {
      // Broadcast: deal expiring soon
      success = await sendToTopic(
        accessToken,
        payload.topic,
        "⏰ Deal Ending Soon!",
        `${payload.dealTitle} at ${payload.businessName} — only ${payload.quantity} left!`,
        { type: "deal_expiring", dealId: payload.dealId ?? "" }
      );
    } else if (payload.type === "merchant_approved" && payload.token) {
      // Merchant: account approved
      success = await sendToToken(
        accessToken,
        payload.token,
        "🎉 You're Approved!",
        "Your DreamEats merchant account has been approved. Start listing your surplus food now!",
        { type: "merchant_approved", screen: "merchant_listings" }
      );
    } else if (payload.type === "announcement" && payload.topic) {
      // Admin broadcast announcement
      success = await sendToTopic(
        accessToken,
        payload.topic ?? "all_users",
        payload.title ?? "📢 DreamEats Update",
        payload.body ?? "",
        { type: "announcement" }
      );
    } else {
      return new Response(
        JSON.stringify({ success: false, error: "Unknown notification type or missing required fields" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Push notification error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
