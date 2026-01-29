-- Create move_out_requests table for tenant move-out requests
CREATE TABLE IF NOT EXISTS public.move_out_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    lease_id UUID NOT NULL REFERENCES public.leases(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    preferred_move_out_date DATE NOT NULL,
    reason TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    admin_notes TEXT,
    responded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_move_out_requests_tenant_id ON public.move_out_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_move_out_requests_lease_id ON public.move_out_requests(lease_id);
CREATE INDEX IF NOT EXISTS idx_move_out_requests_org_id ON public.move_out_requests(org_id);
CREATE INDEX IF NOT EXISTS idx_move_out_requests_status ON public.move_out_requests(status);

-- Enable RLS
ALTER TABLE public.move_out_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies

-- Admins can view/manage all requests for their org
CREATE POLICY "move_out_requests_all_org"
ON public.move_out_requests FOR ALL
TO authenticated
USING (org_id IN (SELECT public.get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT public.get_user_org_ids(auth.uid())));

-- Tenants can view their own requests
CREATE POLICY "move_out_requests_select_tenant"
ON public.move_out_requests FOR SELECT
TO authenticated
USING (org_id IN (SELECT public.get_user_tenant_org_ids(auth.uid())));

-- Tenants can create requests for their own tenant record
CREATE POLICY "move_out_requests_insert_tenant"
ON public.move_out_requests FOR INSERT
TO authenticated
WITH CHECK (
    org_id IN (SELECT public.get_user_tenant_org_ids(auth.uid()))
    AND tenant_id IN (
        SELECT tenant_id FROM public.tenant_user_links 
        WHERE user_id = auth.uid()
    )
);

-- Tenants can update their own pending requests (e.g., to cancel)
CREATE POLICY "move_out_requests_update_own"
ON public.move_out_requests FOR UPDATE
TO authenticated
USING (
    tenant_id IN (
        SELECT tenant_id FROM public.tenant_user_links 
        WHERE user_id = auth.uid()
    )
    AND status = 'pending'
)
WITH CHECK (
    tenant_id IN (
        SELECT tenant_id FROM public.tenant_user_links 
        WHERE user_id = auth.uid()
    )
);

-- Grant permissions
GRANT ALL ON public.move_out_requests TO authenticated;
