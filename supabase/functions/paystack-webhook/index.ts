// Supabase Edge Function: paystack-webhook
// This function handles incoming webhooks from Paystack to ensure orders are
// created even if the user closes the app during checkout.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Initialize Supabase Admin client
const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

serve(async (req) => {
  try {
    const signature = req.headers.get("x-paystack-signature");
    if (!signature) {
      return new Response("No signature", { status: 400 });
    }

    const bodyText = await req.text();

    // 1. Verify Paystack Signature (HMAC SHA512)
    const encoder = new TextEncoder();
    const key = await crypto.subtle.importKey(
      "raw",
      encoder.encode(PAYSTACK_SECRET_KEY),
      { name: "HMAC", hash: "SHA-512" },
      false,
      ["verify"]
    );

    const sigHex = Array.from(new Uint8Array(
      await crypto.subtle.sign("HMAC", key, encoder.encode(bodyText))
    )).map(b => b.toString(16).padStart(2, "0")).join("");

    if (sigHex !== signature) {
      console.error("Invalid signature");
      return new Response("Invalid signature", { status: 401 });
    }

    const event = JSON.parse(bodyText);

    // 2. Only process 'charge.success' events
    if (event.event !== "charge.success") {
      return new Response("Event ignored", { status: 200 });
    }

    const data = event.data;
    const metadata = data.metadata;
    const reference = data.reference;

    // Check if order already exists (prevent duplicates)
    const { data: existingOrder } = await supabaseAdmin
      .from("orders")
      .select("id")
      .eq("payment_reference", reference)
      .maybeSingle();

    if (existingOrder) {
      console.log(`Order for reference ${reference} already exists.`);
      return new Response("Order already exists", { status: 200 });
    }

    // 3. Create Order using metadata passed from the app
    // Metadata should contain: deal_id, customer_id, customer_name, business_id, business_name, deal_title
    if (!metadata || !metadata.deal_id) {
      console.error("Missing metadata for order creation");
      return new Response("Missing metadata", { status: 200 }); // Return 200 so Paystack stops retrying
    }

    const collectionCode = `DE-${Math.floor(1000 + Math.random() * 9000)}`;

    const { error: orderError } = await supabaseAdmin
      .from("orders")
      .insert({
        deal_id: metadata.deal_id,
        deal_title: metadata.deal_title,
        business_id: metadata.business_id,
        business_name: metadata.business_name,
        customer_id: metadata.customer_id,
        customer_name: metadata.customer_name,
        price: data.amount / 100, // Convert pesewas back to GHS
        status: "reserved",
        payment_method: data.channel,
        payment_reference: reference,
        collection_code: collectionCode,
        created_at: new Date().toISOString(),
      });

    if (orderError) {
      console.error("Error creating order:", orderError);
      return new Response("Database error", { status: 500 });
    }

    // 4. Update Deal Stock Atomically
    const { error: stockError } = await supabaseAdmin.rpc(
      "decrement_deal_quantity",
      { deal_id: metadata.deal_id }
    );

    if (stockError) {
      console.error("Error updating stock:", stockError);
    }

    console.log(`Order created successfully for reference: ${reference}`);

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    console.error("Webhook processing error:", err);
    return new Response("Server error", { status: 500 });
  }
});
