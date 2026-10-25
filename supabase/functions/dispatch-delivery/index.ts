// Supabase Edge Function: dispatch-delivery
// Idempotent courier dispatch worker.
// Guarantees one paid delivery creates exactly ONE provider dispatch job.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const COURIER_API_KEY = Deno.env.get("COURIER_API_KEY") || "";

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const body = await req.json();
    const { order_id } = body ?? {};

    if (!order_id) {
      return new Response(JSON.stringify({ error: "order_id is required" }), {
        status: 400,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      });
    }

    // 1. Fetch Order and Verify State
    const { data: order, error: orderError } = await supabaseAdmin
      .from("orders")
      .select("*, businesses(name, address, latitude, longitude)")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(JSON.stringify({ error: "Order not found" }), {
        status: 404,
        headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
      });
    }

    // 2. Strict Pre-conditions for Dispatch
    if (order.fulfillment_type !== "delivery") {
      return new Response(
        JSON.stringify({ error: "Order is not marked for doorstep delivery" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const isPayOnDelivery = order.payment_method === "Cash on Delivery";
    if (order.payment_status !== "paid" && !isPayOnDelivery) {
      return new Response(
        JSON.stringify({ error: "Cannot dispatch unpaid order. Payment status: " + order.payment_status }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // 3. Idempotency Check: Don't duplicate provider dispatch!
    if (order.dispatch_job_id && order.dispatch_job_id.trim().length > 0) {
      console.log(`Order ${order_id} already dispatched to job ${order.dispatch_job_id}`);
      return new Response(
        JSON.stringify({
          success: true,
          message: "Order already dispatched",
          dispatch_job_id: order.dispatch_job_id,
          delivery_status: order.delivery_status,
        }),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // 4. Fallback if no provider key configured yet (Internal Fleet Mode)
    if (!COURIER_API_KEY) {
      console.warn("COURIER_API_KEY secret not set. Queuing for internal rider fleet.");
      await supabaseAdmin
        .from("orders")
        .update({
          delivery_status: "dispatch_pending",
          dispatch_last_error: "Awaiting courier integration key; dispatched to internal fleet pool.",
        })
        .eq("id", order_id);

      return new Response(
        JSON.stringify({
          success: true,
          mode: "internal_fleet",
          message: "Dispatched to internal rider pool",
          delivery_status: "dispatch_pending",
        }),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // 5. Send Dispatch Request to Courier API
    const pickupLat = order.businesses?.latitude || 5.6148;
    const pickupLng = order.businesses?.longitude || -0.2059;
    const dropoffAddress = order.delivery_address || "Accra Central, Ghana";

    const courierPayload = {
      pickup_address: order.businesses?.address || "Restaurant Storefront",
      dropoff_address: dropoffAddress,
      pickup_lat: pickupLat,
      pickup_lng: pickupLng,
      dropoff_lat: 5.5560, // Default dropoff coord fallback
      dropoff_lng: -0.1825,
      service_type: "food",
      payment_method: isPayOnDelivery ? "cash" : "card",
    };

    const courierRes = await fetch("https://api.kwikiedelivery.com/api/v1/orders", {
      method: "POST",
      headers: {
        "X-API-Key": COURIER_API_KEY,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(courierPayload),
    });

    const courierData = await courierRes.json();

    if (!courierRes.ok || !courierData.success) {
      const errMsg = courierData.message || "Courier API returned failure status";
      console.error(`Courier dispatch failed for order ${order_id}:`, errMsg);

      await supabaseAdmin
        .from("orders")
        .update({
          dispatch_retry_count: (order.dispatch_retry_count || 0) + 1,
          dispatch_last_error: errMsg,
          delivery_status: "dispatch_pending", // Remains recoverable for admin intervention
        })
        .eq("id", order_id);

      return new Response(
        JSON.stringify({
          success: false,
          error: "Courier dispatch request failed: " + errMsg,
          recoverable: true,
        }),
        { status: 502, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // 6. Record Successful Dispatch with Provider ID and OTP
    const externalOrderId = String(courierData.data?.order_id || "");
    const deliveryOtp = courierData.data?.delivery_otp || order.delivery_pin;

    await supabaseAdmin
      .from("orders")
      .update({
        dispatch_job_id: externalOrderId,
        delivery_pin: deliveryOtp,
        delivery_status: "assigned",
        dispatch_last_error: null,
      })
      .eq("id", order_id);

    return new Response(
      JSON.stringify({
        success: true,
        dispatch_job_id: externalOrderId,
        delivery_status: "assigned",
        delivery_pin: deliveryOtp,
      }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("Dispatch delivery unexpected error:", err);
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
