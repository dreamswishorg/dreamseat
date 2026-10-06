// Supabase Edge Function: send-email
// Sends transactional emails via Brevo (formerly Sendinblue) HTTP API
// Free tier: 300 emails/day — no credit card needed
// OR via Resend.com (100 emails/day free)
//
// Why not direct SMTP: Supabase Edge Functions (Deno Isolates) cannot make
// outbound TCP connections. Must use HTTP APIs instead.
//
// Deploy: supabase functions deploy send-email
// Secrets needed: BREVO_API_KEY=your_key_here (get free at app.brevo.com)

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Brevo (Sendinblue) or Resend API key — set via supabase secrets
const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY") ?? "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FROM_NAME = Deno.env.get("SMTP_FROM_NAME") ?? "DreamEats";
const FROM_EMAIL = Deno.env.get("SMTP_USER") ?? "support@winningedgeinvestment.com";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const { to, subject, html, text, template, data } = await req.json();

    if (!to || !subject) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: to, subject" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Build HTML from template if provided
    let emailHtml = html ?? text ?? "";
    if (template && data) {
      emailHtml = buildTemplate(template, data);
    }

    // Try Resend first, then Brevo as fallback
    if (RESEND_API_KEY) {
      return await sendViaResend({ to, subject, html: emailHtml, text });
    } else if (BREVO_API_KEY) {
      return await sendViaBrevo({ to, subject, html: emailHtml, text });
    } else {
      // No API key set — log and return success (dev mode)
      console.log(`[DEV MODE] Email to ${to}: ${subject}`);
      console.log("Set RESEND_API_KEY or BREVO_API_KEY secret to enable real emails");
      return new Response(
        JSON.stringify({ success: true, mode: "dev", message: "Email logged (no API key configured)" }),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }
  } catch (error) {
    console.error("Email send error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});

// ─── Resend.com API ──────────────────────────────────────────────────────────
async function sendViaResend({ to, subject, html, text }: {
  to: string; subject: string; html?: string; text?: string;
}): Promise<Response> {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `${FROM_NAME} <${FROM_EMAIL}>`,
      to: [to],
      subject,
      html,
      text: text ?? stripHtml(html ?? ""),
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    console.error("Resend error:", data);
    return new Response(
      JSON.stringify({ success: false, error: data.message ?? "Resend API error" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
  console.log(`Email sent via Resend to ${to}: ${subject}`);
  return new Response(
    JSON.stringify({ success: true, id: data.id }),
    { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
  );
}

// ─── Brevo (Sendinblue) API ───────────────────────────────────────────────────
async function sendViaBrevo({ to, subject, html, text }: {
  to: string; subject: string; html?: string; text?: string;
}): Promise<Response> {
  const res = await fetch("https://api.brevo.com/v3/smtp/email", {
    method: "POST",
    headers: {
      "api-key": BREVO_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      sender: { name: FROM_NAME, email: FROM_EMAIL },
      to: [{ email: to }],
      subject,
      htmlContent: html,
      textContent: text ?? stripHtml(html ?? ""),
    }),
  });

  const data = await res.json();
  if (!res.ok) {
    console.error("Brevo error:", data);
    return new Response(
      JSON.stringify({ success: false, error: data.message ?? "Brevo API error" }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
  console.log(`Email sent via Brevo to ${to}: ${subject}`);
  return new Response(
    JSON.stringify({ success: true, messageId: data.messageId }),
    { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function stripHtml(html: string): string {
  return html.replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim();
}

function buildTemplate(template: string, data: Record<string, string>): string {
  switch (template) {
    case "welcome":
      return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #2E7D32, #4CAF50); padding: 40px 32px; text-align: center; }
    .header h1 { color: white; margin: 0; font-size: 28px; }
    .header p { color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 15px; }
    .body { padding: 40px 32px; }
    .body h2 { color: #1B5E20; font-size: 22px; margin: 0 0 16px; }
    .body p { color: #444; line-height: 1.6; margin: 0 0 20px; }
    .cta { display: inline-block; background: #2E7D32; color: white !important; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: bold; font-size: 16px; }
    .footer { background: #f9f9f9; padding: 24px 32px; text-align: center; font-size: 12px; color: #888; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🌿 Welcome to DreamEats!</h1>
      <p>Save Food. Save Money. Feed Dreams.</p>
    </div>
    <div class="body">
      <h2>Hey ${data.name ?? "there"} 👋</h2>
      <p>Your DreamEats account is ready. Discover surplus meals from restaurants, bakeries, and farms across Ghana at up to <strong>70% off</strong>.</p>
      <p>Every meal you rescue helps reduce food waste and supports local businesses.</p>
      <a href="https://dreameats.com.gh" class="cta">Start Exploring Deals →</a>
    </div>
    <div class="footer">
      <p>DreamEats | Accra, Ghana</p>
      <p>You're receiving this because you signed up at DreamEats.</p>
    </div>
  </div>
</body>
</html>`;

    case "order_confirmed":
      return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #2E7D32, #4CAF50); padding: 40px 32px; text-align: center; }
    .header h1 { color: white; margin: 0; font-size: 26px; }
    .code-box { background: #f0fdf4; border: 2px dashed #4CAF50; border-radius: 12px; padding: 24px; margin: 24px 32px; text-align: center; }
    .pickup-code { font-size: 42px; font-weight: 900; color: #2E7D32; letter-spacing: 10px; font-family: monospace; }
    .code-label { font-size: 13px; color: #666; margin-bottom: 8px; }
    .details { background: #fafafa; border-radius: 8px; padding: 20px; margin: 0 32px 32px; }
    .details table { width: 100%; border-collapse: collapse; }
    .details td { padding: 8px 0; border-bottom: 1px solid #eee; color: #444; }
    .details td:first-child { font-weight: 600; color: #222; width: 45%; }
    .footer { padding: 24px; text-align: center; font-size: 12px; color: #888; }
    h2 { color: #1B5E20; padding: 24px 32px 0; margin: 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header"><h1>✅ Order Confirmed!</h1></div>
    <h2>Your rescue pack is reserved, ${data.customerName ?? "Customer"}!</h2>
    <div class="code-box">
      <p class="code-label">YOUR PICKUP CODE</p>
      <div class="pickup-code">${data.collectionCode ?? "----"}</div>
      <p style="color:#666;font-size:13px;margin:12px 0 0;">Show this to the merchant when you collect</p>
    </div>
    <div class="details">
      <table>
        <tr><td>Business</td><td>${data.businessName ?? "-"}</td></tr>
        <tr><td>Order</td><td>${data.dealTitle ?? "-"}</td></tr>
        <tr><td>Amount Paid</td><td>GHS ${data.price ?? "-"}</td></tr>
        <tr><td>Payment</td><td>${data.paymentMethod ?? "-"}</td></tr>
        <tr><td>Pickup Window</td><td>${data.pickupWindow ?? "Check with merchant"}</td></tr>
      </table>
    </div>
    <div class="footer">DreamEats | Accra, Ghana</div>
  </div>
</body>
</html>`;

    case "merchant_new_order":
      return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: 'Segoe UI', Arial, sans-serif; background: #f5f5f5; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1565C0, #1976D2); padding: 32px; text-align: center; }
    .header h1 { color: white; margin: 0; font-size: 24px; }
    .body { padding: 32px; }
    .alert { background: #e3f2fd; border-left: 4px solid #1976D2; padding: 16px; border-radius: 0 8px 8px 0; margin: 16px 0; }
    .details { background: #fafafa; border-radius: 8px; padding: 20px; }
    .details table { width: 100%; border-collapse: collapse; }
    .details td { padding: 8px 0; border-bottom: 1px solid #eee; }
    .details td:first-child { font-weight: 600; width: 45%; }
    .footer { padding: 24px; text-align: center; font-size: 12px; color: #888; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header"><h1>🛍️ New Order Received!</h1></div>
    <div class="body">
      <div class="alert">A customer has just reserved <strong>${data.dealTitle ?? "a deal"}</strong> from your store.</div>
      <div class="details">
        <table>
          <tr><td>Customer</td><td>${data.customerName ?? "-"}</td></tr>
          <tr><td>Deal</td><td>${data.dealTitle ?? "-"}</td></tr>
          <tr><td>Pickup Code</td><td><strong>${data.collectionCode ?? "-"}</strong></td></tr>
          <tr><td>Payment</td><td>GHS ${data.price ?? "-"} (${data.paymentMethod ?? "-"})</td></tr>
        </table>
      </div>
      <p style="color:#555;font-size:14px;margin-top:20px;">Prepare the order for collection. Verify the customer's pickup code on arrival.</p>
    </div>
    <div class="footer">DreamEats | Accra, Ghana</div>
  </div>
</body>
</html>`;

    default:
      return `<p>${data.message ?? ""}</p>`;
  }
}
