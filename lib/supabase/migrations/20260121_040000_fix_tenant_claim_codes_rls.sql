-- Fix RLS policies for tenant_claim_codes table
-- The issue: new tenant users can't create claim codes because policies require org membership
-- But new users DON'T have org membership yet - that's the whole point of the claim code!

-- Drop all existing policies on tenant_claim_codes
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_claim_codes' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_claim_codes', pol.policyname);
    END LOOP;
END $$;

-- Enable RLS
ALTER TABLE public.tenant_claim_codes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can INSERT their own claim codes
-- Any authenticated user can create a claim code for themselves
CREATE POLICY "tenant_claim_codes_insert_own"
ON public.tenant_claim_codes FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Users can SELECT their own claim codes
CREATE POLICY "tenant_claim_codes_select_own"
ON public.tenant_claim_codes FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Policy: Org admins can SELECT claim codes (to look up codes from tenants)
CREATE POLICY "tenant_claim_codes_select_admin"
ON public.tenant_claim_codes FOR SELECT
TO authenticated
USING (
    -- Admin can view any claim code (needed for lookup by code)
    EXISTS (SELECT 1 FROM public.org_members WHERE user_id = auth.uid())
);

-- Policy: Org admins can UPDATE claim codes (to claim them for a tenant)
CREATE POLICY "tenant_claim_codes_update_admin"
ON public.tenant_claim_codes FOR UPDATE
TO authenticated
USING (
    -- Admin of any org can update (to link tenant)
    EXISTS (SELECT 1 FROM public.org_members WHERE user_id = auth.uid())
)
WITH CHECK (
    EXISTS (SELECT 1 FROM public.org_members WHERE user_id = auth.uid())
);

-- Grant permissions
GRANT ALL ON public.tenant_claim_codes TO authenticated;
