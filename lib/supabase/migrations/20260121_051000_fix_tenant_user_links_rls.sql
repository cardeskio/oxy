-- Fix RLS policies for tenant_user_links table
-- Issue: Admins can't insert tenant_user_links when claiming a tenant profile

-- Drop existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_user_links' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_user_links', pol.policyname);
    END LOOP;
END $$;

-- Enable RLS
ALTER TABLE public.tenant_user_links ENABLE ROW LEVEL SECURITY;

-- Org members (admins) can INSERT tenant links for their orgs
CREATE POLICY "tenant_user_links_insert_admin"
ON public.tenant_user_links FOR INSERT
TO authenticated
WITH CHECK (
    org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid())
);

-- Org members can SELECT tenant links for their orgs
CREATE POLICY "tenant_user_links_select_admin"
ON public.tenant_user_links FOR SELECT
TO authenticated
USING (
    org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid())
);

-- Tenant users can SELECT their own links
CREATE POLICY "tenant_user_links_select_own"
ON public.tenant_user_links FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Org members can UPDATE tenant links for their orgs
CREATE POLICY "tenant_user_links_update_admin"
ON public.tenant_user_links FOR UPDATE
TO authenticated
USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()))
WITH CHECK (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Org members can DELETE tenant links for their orgs
CREATE POLICY "tenant_user_links_delete_admin"
ON public.tenant_user_links FOR DELETE
TO authenticated
USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Grant permissions
GRANT ALL ON public.tenant_user_links TO authenticated;
