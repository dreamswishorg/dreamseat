// Supabase Edge Function: paystack-charge
// This function initiates a direct charge (Mobile Money) via Paystack.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY");
  if (!PAYSTACK_SECRET_KEY) {
    return new Response(JSON.stringify({ status: false, message: "PAYSTACK_SECRET_KEY is not set in Supabase Secrets." }), {
      status: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  try {
    const { action, email, amount, phone, provider, metadata, reference, otp } = await req.json();

    if (action === "submit_otp" || otp) {
      const response = await fetch("https://api.paystack.co/charge/submit_otp", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ otp, reference }),
      });
      const data = await response.json();
      return new Response(JSON.stringify(data), {
        status: response.status,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      });
    }

    // Mapping providers to Paystack slugs
    const providerMap: Record<string, string> = {
      'MTN MoMo': 'mtn',
      'Telecel Cash': 'vod', // Vodafone is now Telecel
      'AirtelTigo Money': 'atl',
    };

    const payload = {
      email,
      amount: Math.round(amount * 100), // GHS to pesewas
      currency: "GHS",
      reference: reference || `DE-${Date.now()}`,
      metadata,
      mobile_money: {
        phone,
        provider: providerMap[provider] || 'mtn'
      }
    };

    const response = await fetch("https://api.paystack.co/charge", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      status: response.status,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });

  } catch (error) {
    return new Response(JSON.stringify({ status: false, message: error.message }), {
      status: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }
});
