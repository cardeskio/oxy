import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface InvoiceGenerationRequest {
  org_id: string;
  period_start: string; // ISO date string, e.g., "2026-01-01"
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { org_id, period_start }: InvoiceGenerationRequest = await req.json();

    if (!org_id || !period_start) {
      return new Response(
        JSON.stringify({ error: "org_id and period_start are required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    const periodStartDate = new Date(period_start);
    const periodEndDate = new Date(periodStartDate.getFullYear(), periodStartDate.getMonth() + 1, 0);
    const dueDate = new Date(periodStartDate);

    // Get active leases for this org
    const { data: leases, error: leasesError } = await supabase
      .from("leases")
      .select("*, tenants(full_name), units(unit_label)")
      .eq("org_id", org_id)
      .eq("status", "active");

    if (leasesError) {
      throw new Error(`Failed to fetch leases: ${leasesError.message}`);
    }

    const invoicesCreated: string[] = [];
    const skipped: string[] = [];

    for (const lease of leases || []) {
      // Check if invoice already exists for this period (idempotency)
      const { data: existingInvoice } = await supabase
        .from("invoices")
        .select("id")
        .eq("lease_id", lease.id)
        .eq("period_start", periodStartDate.toISOString())
        .maybeSingle();

      if (existingInvoice) {
        skipped.push(lease.id);
        continue;
      }

      // Calculate due date based on lease due_day
      const leaseDueDate = new Date(periodStartDate);
      leaseDueDate.setDate(Math.min(lease.due_day, periodEndDate.getDate()));

      const invoiceId = crypto.randomUUID();
      const rentLineId = crypto.randomUUID();
      const rentAmount = lease.rent_amount;

      // Create invoice
      const { error: invoiceError } = await supabase
        .from("invoices")
        .insert({
          id: invoiceId,
          org_id: org_id,
          lease_id: lease.id,
          tenant_id: lease.tenant_id,
          unit_id: lease.unit_id,
          property_id: lease.property_id,
          period_start: periodStartDate.toISOString(),
          period_end: periodEndDate.toISOString(),
          due_date: leaseDueDate.toISOString(),
          status: "open",
          total_amount: rentAmount,
          balance_amount: rentAmount,
        });

      if (invoiceError) {
        console.error(`Failed to create invoice for lease ${lease.id}:`, invoiceError);
        continue;
      }

      // Create rent line item
      const monthName = periodStartDate.toLocaleString("en-US", { month: "long" });
      const { error: lineError } = await supabase
        .from("invoice_lines")
        .insert({
          id: rentLineId,
          org_id: org_id,
          invoice_id: invoiceId,
          charge_type: "Rent",
          description: `${monthName} ${periodStartDate.getFullYear()} Rent`,
          amount: rentAmount,
          balance_amount: rentAmount,
        });

      if (lineError) {
        console.error(`Failed to create invoice line for invoice ${invoiceId}:`, lineError);
        // Rollback invoice
        await supabase.from("invoices").delete().eq("id", invoiceId);
        continue;
      }

      invoicesCreated.push(invoiceId);

      // Create audit log
      await supabase.from("audit_logs").insert({
        id: crypto.randomUUID(),
        org_id: org_id,
        action: "CREATE_INVOICE",
        entity_type: "invoice",
        entity_id: invoiceId,
        metadata_json: { lease_id: lease.id, period: period_start, generated_by: "system" },
      });
    }

    return new Response(
      JSON.stringify({
        success: true,
        invoices_created: invoicesCreated.length,
        skipped: skipped.length,
        invoice_ids: invoicesCreated,
      }),
      { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error generating invoices:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
