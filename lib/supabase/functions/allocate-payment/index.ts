import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

interface AllocationRequest {
  payment_id: string;
  org_id: string;
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

    const { payment_id, org_id, actor_user_id }: AllocationRequest = await req.json();

    if (!payment_id || !org_id) {
      return new Response(
        JSON.stringify({ error: "payment_id and org_id are required" }),
        { status: 400, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Get payment details
    const { data: payment, error: paymentError } = await supabase
      .from("payments")
      .select("*")
      .eq("id", payment_id)
      .eq("org_id", org_id)
      .single();

    if (paymentError || !payment) {
      return new Response(
        JSON.stringify({ error: "Payment not found" }),
        { status: 404, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Get existing allocations to calculate remaining amount
    const { data: existingAllocations } = await supabase
      .from("payment_allocations")
      .select("amount_allocated")
      .eq("payment_id", payment_id);

    const totalAllocated = (existingAllocations || []).reduce(
      (sum, a) => sum + Number(a.amount_allocated),
      0
    );
    let remainingAmount = Number(payment.amount) - totalAllocated;

    if (remainingAmount <= 0) {
      return new Response(
        JSON.stringify({ success: true, message: "Payment already fully allocated", allocations_made: 0 }),
        { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
      );
    }

    // Get open invoice lines for the tenant, ordered by invoice due date (oldest first)
    const { data: invoiceLines, error: linesError } = await supabase
      .from("invoice_lines")
      .select(`
        id,
        invoice_id,
        org_id,
        balance_amount,
        invoices!inner(
          id,
          tenant_id,
          due_date,
          status
        )
      `)
      .eq("org_id", org_id)
      .gt("balance_amount", 0)
      .eq("invoices.tenant_id", payment.tenant_id)
      .eq("invoices.status", "open")
      .order("due_date", { foreignTable: "invoices", ascending: true });

    if (linesError) {
      throw new Error(`Failed to fetch invoice lines: ${linesError.message}`);
    }

    const allocations: { invoice_id: string; invoice_line_id: string; amount: number }[] = [];

    // Allocate to oldest invoice lines first
    for (const line of invoiceLines || []) {
      if (remainingAmount <= 0) break;

      const lineBalance = Number(line.balance_amount);
      const allocationAmount = Math.min(remainingAmount, lineBalance);
      
      if (allocationAmount <= 0) continue;

      const allocationId = crypto.randomUUID();

      // Create allocation record
      const { error: allocError } = await supabase
        .from("payment_allocations")
        .insert({
          id: allocationId,
          org_id: org_id,
          payment_id: payment_id,
          invoice_line_id: line.id,
          invoice_id: line.invoice_id,
          amount_allocated: allocationAmount,
        });

      if (allocError) {
        console.error(`Failed to create allocation: ${allocError.message}`);
        continue;
      }

      // Update invoice line balance
      const newLineBalance = lineBalance - allocationAmount;
      await supabase
        .from("invoice_lines")
        .update({ balance_amount: newLineBalance })
        .eq("id", line.id);

      // Update invoice total balance and status
      const { data: invoiceData } = await supabase
        .from("invoices")
        .select("balance_amount")
        .eq("id", line.invoice_id)
        .single();

      if (invoiceData) {
        const newInvoiceBalance = Number(invoiceData.balance_amount) - allocationAmount;
        const invoiceStatus = newInvoiceBalance <= 0 ? "paid" : "open";
        
        await supabase
          .from("invoices")
          .update({ 
            balance_amount: Math.max(0, newInvoiceBalance),
            status: invoiceStatus,
            updated_at: new Date().toISOString(),
          })
          .eq("id", line.invoice_id);
      }

      allocations.push({
        invoice_id: line.invoice_id,
        invoice_line_id: line.id,
        amount: allocationAmount,
      });

      remainingAmount -= allocationAmount;
    }

    // Update payment status
    const newTotalAllocated = totalAllocated + allocations.reduce((sum, a) => sum + a.amount, 0);
    let paymentStatus: string;
    if (newTotalAllocated >= Number(payment.amount)) {
      paymentStatus = "allocated";
    } else if (newTotalAllocated > 0) {
      paymentStatus = "partiallyAllocated";
    } else {
      paymentStatus = "unallocated";
    }

    await supabase
      .from("payments")
      .update({ 
        status: paymentStatus,
        updated_at: new Date().toISOString(),
      })
      .eq("id", payment_id);

    // Create audit log
    await supabase.from("audit_logs").insert({
      id: crypto.randomUUID(),
      org_id: org_id,
      actor_user_id: actor_user_id,
      action: "ALLOCATE_PAYMENT",
      entity_type: "payment",
      entity_id: payment_id,
      metadata_json: { allocations, remaining_unallocated: remainingAmount },
    });

    return new Response(
      JSON.stringify({
        success: true,
        allocations_made: allocations.length,
        total_allocated: allocations.reduce((sum, a) => sum + a.amount, 0),
        remaining_unallocated: remainingAmount,
        payment_status: paymentStatus,
        allocations,
      }),
      { headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error allocating payment:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...CORS_HEADERS, "Content-Type": "application/json" } }
    );
  }
});
