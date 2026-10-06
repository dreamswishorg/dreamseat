import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY") ?? "";
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const FROM_NAME = Deno.env.get("SMTP_FROM_NAME") ?? "DreamEats";
const FROM_EMAIL = Deno.env.get("SMTP_USER") ?? "support@winningedgeinvestment.com";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const { subject, content, html, audience } = await req.json();

    if (!subject || (!content && !html)) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields: subject, content/html" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase admin client
    const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Query profiles matching the target audience
    let query = supabaseAdmin
      .from("profiles")
      .select("email, name")
      .eq("is_suspended", false);

    if (audience === "customers") {
      query = query.eq("role", "customer");
    } else if (audience === "merchants") {
      query = query.eq("role", "merchant");
    } else if (audience === "admins") {
      query = query.eq("role", "admin");
    }

    const { data: profiles, error: dbError } = await query;

    if (dbError) {
      console.error("Database query error:", dbError);
      return new Response(
        JSON.stringify({ success: false, error: `Database query failed: ${dbError.message}` }),
        { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    if (!profiles || profiles.length === 0) {
      return new Response(
        JSON.stringify({ success: true, message: "No recipients found for this audience.", count: 0 }),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const emailHtml = html ?? content ?? "";
    const emailText = content ?? html ?? "";

    const recipientsCount = profiles.length;
    console.log(`Sending broadcast to ${recipientsCount} recipients.`);

    // If no real API key is configured, log and return success (Dev Mode / Test environment)
    if (!RESEND_API_KEY && !BREVO_API_KEY) {
      console.log(`[DEV MODE] Broadcast logged for ${recipientsCount} users: "${subject}"`);
      return new Response(
        JSON.stringify({ success: true, mode: "dev", count: recipientsCount, message: "Dev Mode: Broadcast logged successfully." }),
        { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Send emails
    const sendPromises = profiles.map(async (profile) => {
      try {
        if (RESEND_API_KEY) {
          await sendViaResend({ to: profile.email, subject, html: emailHtml, text: emailText });
        } else {
          await sendViaBrevo({ to: profile.email, subject, html: emailHtml, text: emailText });
        }
        return { email: profile.email, success: true };
      } catch (err) {
        console.error(`Failed to send broadcast email to ${profile.email}:`, err);
        return { email: profile.email, success: false, error: err.message };
      }
    });

    const results = await Promise.all(sendPromises);
    const successCount = results.filter((r) => r.success).length;

    return new Response(
      JSON.stringify({
        success: true,
        count: successCount,
        total: recipientsCount,
        details: results,
      }),
      { status: 200, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Broadcast edge function error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});

// Helper for Resend
async function sendViaResend({ to, subject, html, text }: { to: string; subject: string; html?: string; text?: string }) {
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
      text,
    }),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.message ?? "Resend error");
  }
}

// Helper for Brevo
async function sendViaBrevo({ to, subject, html, text }: { to: string; subject: string; html?: string; text?: string }) {
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
      textContent: text,
    }),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.message ?? "Brevo error");
  }
}
