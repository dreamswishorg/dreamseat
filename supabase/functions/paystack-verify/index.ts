// Supabase Edge Function: paystack-verify
// Deploy with: supabase functions deploy paystack-verify
// 
// This function verifies a Paystack payment reference server-side,
// keeping the secret key OFF the client device.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY");
  if (!PAYSTACK_SECRET_KEY) {
    return new Response(JSON.stringify({ verified: false, message: "PAYSTACK_SECRET_KEY is not set in Supabase Secrets." }), {
      status: 500,
      headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
    });
  }

  try {
    const { reference } = await req.json();

    if (!reference) {
      return new Response(
        JSON.stringify({ verified: false, message: "Missing reference" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Verify with Paystack
    const paystackRes = await fetch(
      `https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,
      {
        method: "GET",
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    if (!paystackRes.ok) {
      const errorText = await paystackRes.text();
      console.error("Paystack API error:", errorText);
      return new Response(
        JSON.stringify({
          verified: false,
          message: `Paystack API error: ${paystackRes.status}`,
        }),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const data = await paystackRes.json();

    // Paystack returns status: 'success' for successful payments
    const verified =
      data.status === true &&
      data.data?.status === "success";

    const amountGhs = verified ? (data.data.amount / 100).toFixed(2) : null;
    const channel = data.data?.channel ?? null;
    const customerEmail = data.data?.customer?.email ?? null;

    console.log(
      `Payment reference ${reference}: ${verified ? "VERIFIED ✓" : "FAILED ✗"}`
    );

    return new Response(
      JSON.stringify({
        verified,
        reference,
        amount_ghs: amountGhs,
        channel,
        customer_email: customerEmail,
        message: verified ? "Payment verified successfully" : (data.data?.gateway_response ?? "Payment not successful"),
      }),
      {
        status: 200,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ verified: false, message: `Server error: ${error.message}` }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
