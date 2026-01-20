import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface VoidInvoiceRequest {
  invoice_id: string;
  org_id: string;
  reason: string;
  actor_user_id?: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { invoice_id, org_id, reason, actor_user_id }: VoidInvoiceRequest = await req.json();

    if (!invoice_id || !org_id || !reason) {
      return new Response(
        JSON.stringify({ error: "invoice_id, org_id, and reason are required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Verify user role (owner or accountant only)
    if (actor_user_id) {
      const { data: member, error: memberError } = await supabase
        .from("org_members")
        .select("role")
        .eq("org_id", org_id)
        .eq("user_id", actor_user_id)
        .single();

      if (memberError || !member) {
        return new Response(
          JSON.stringify({ error: "User not found in organization" }),
          { status: 403, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
      }

      if (!["owner", "accountant"].includes(member.role)) {
        return new Response(
          JSON.stringify({ error: "Only owners and accountants can void invoices" }),
          { status: 403, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
      }
    }

    // Get invoice
    const { data: invoice, error: invoiceError } = await supabase
      .from("invoices")
      .select("*")
      .eq("id", invoice_id)
      .eq("org_id", org_id)
      .single();

    if (invoiceError || !invoice) {
      return new Response(
        JSON.stringify({ error: "Invoice not found" }),
        { status: 404, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    if (invoice.status === "void") {
      return new Response(
        JSON.stringify({ error: "Invoice is already voided" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Check for allocations - can't void if payments are allocated
    const { data: allocations } = await supabase
      .from("payment_allocations")
      .select("id, amount_allocated")
      .eq("invoice_id", invoice_id);

    if (allocations && allocations.length > 0) {
      const totalAllocated = allocations.reduce((sum, a) => sum + Number(a.amount_allocated), 0);
      if (totalAllocated > 0) {
        return new Response(
          JSON.stringify({ 
            error: "Cannot void invoice with allocated payments. Unallocate payments first.",
            allocated_amount: totalAllocated,
          }),
          { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
        );
      }
    }

    // Update invoice status to void
    const { error: updateError } = await supabase
      .from("invoices")
      .update({ 
        status: "void",
        updated_at: new Date().toISOString(),
      })
      .eq("id", invoice_id);

    if (updateError) {
      throw new Error(`Failed to void invoice: ${updateError.message}`);
    }

    // Create audit log
    await supabase.from("audit_logs").insert({
      id: crypto.randomUUID(),
      org_id: org_id,
      actor_user_id: actor_user_id,
      action: "VOID_INVOICE",
      entity_type: "invoice",
      entity_id: invoice_id,
      metadata_json: { 
        reason,
        original_amount: invoice.total_amount,
        tenant_id: invoice.tenant_id,
        period_start: invoice.period_start,
      },
    });

    return new Response(
      JSON.stringify({
        success: true,
        message: "Invoice voided successfully",
        invoice_id,
      }),
      { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error voiding invoice:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
