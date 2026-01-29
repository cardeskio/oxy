-- Create unit_charges table for per-unit charge amounts
-- Each unit can have custom amounts for each charge type
CREATE TABLE IF NOT EXISTS public.unit_charges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
    unit_id UUID NOT NULL REFERENCES public.units(id) ON DELETE CASCADE,
    charge_type_id UUID NOT NULL REFERENCES public.charge_types(id) ON DELETE CASCADE,
    amount NUMERIC NOT NULL DEFAULT 0,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(unit_id, charge_type_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_unit_charges_org_id ON public.unit_charges(org_id);
CREATE INDEX IF NOT EXISTS idx_unit_charges_unit_id ON public.unit_charges(unit_id);
CREATE INDEX IF NOT EXISTS idx_unit_charges_charge_type_id ON public.unit_charges(charge_type_id);

-- Enable RLS
ALTER TABLE public.unit_charges ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY unit_charges_select ON public.unit_charges
    FOR SELECT TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

CREATE POLICY unit_charges_insert ON public.unit_charges
    FOR INSERT TO authenticated
    WITH CHECK (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

CREATE POLICY unit_charges_update ON public.unit_charges
    FOR UPDATE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

CREATE POLICY unit_charges_delete ON public.unit_charges
    FOR DELETE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Grant permissions
GRANT ALL ON public.unit_charges TO authenticated;

-- Enable realtime for instant updates
ALTER PUBLICATION supabase_realtime ADD TABLE public.unit_charges;
