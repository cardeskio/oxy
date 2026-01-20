-- Complete RLS fix for orgs, org_members, tenant_user_links, and tenant_claim_codes tables
-- This migration fixes infinite recursion issues using SECURITY DEFINER helper functions

-- ============================================
-- STEP 1: Drop ALL existing policies on all affected tables
-- ============================================

-- Drop all policies on orgs table
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'orgs' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.orgs', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on org_members table
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'org_members' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.org_members', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on tenant_user_links table
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_user_links' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_user_links', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on tenant_claim_codes table
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_claim_codes' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_claim_codes', pol.policyname);
    END LOOP;
END $$;

-- ============================================
-- STEP 2: Drop and recreate helper functions
-- ============================================

DROP FUNCTION IF EXISTS public.get_user_org_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_org_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_tenant_org_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_tenant_user(UUID, UUID) CASCADE;

-- Helper function: Get org IDs where user is a member
CREATE OR REPLACE FUNCTION public.get_user_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT org_id FROM org_members WHERE user_id = p_user_id;
$$;

-- Helper function: Check if user is an org member
CREATE OR REPLACE FUNCTION public.is_org_member(p_user_id UUID, p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM org_members WHERE user_id = p_user_id AND org_id = p_org_id);
$$;

-- Helper function: Get org IDs where user is linked as tenant
CREATE OR REPLACE FUNCTION public.get_user_tenant_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT org_id FROM tenant_user_links WHERE user_id = p_user_id;
$$;

-- Helper function: Check if user has a tenant link in an org
CREATE OR REPLACE FUNCTION public.is_tenant_user(p_user_id UUID, p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM tenant_user_links WHERE user_id = p_user_id AND org_id = p_org_id);
$$;

-- ============================================
-- STEP 3: Enable RLS on all tables
-- ============================================

ALTER TABLE public.orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_user_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_claim_codes ENABLE ROW LEVEL SECURITY;

-- ============================================
-- STEP 4: Create RLS policies for orgs table
-- ============================================

-- INSERT: Any authenticated user can create an org
CREATE POLICY "orgs_insert_policy" ON public.orgs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- SELECT: Users can view orgs they are members of
CREATE POLICY "orgs_select_policy" ON public.orgs
  FOR SELECT
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- UPDATE: Only org members can update
CREATE POLICY "orgs_update_policy" ON public.orgs
  FOR UPDATE
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())))
  WITH CHECK (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- DELETE: Only org members can delete
CREATE POLICY "orgs_delete_policy" ON public.orgs
  FOR DELETE
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- ============================================
-- STEP 5: Create RLS policies for org_members table
-- ============================================

-- SELECT: Users can view their own memberships OR memberships in orgs they belong to
CREATE POLICY "org_members_select_policy" ON public.org_members
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_org_member(auth.uid(), org_id)
  );

-- INSERT: Users can add themselves OR add others if they're already a member
CREATE POLICY "org_members_insert_policy" ON public.org_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() 
    OR public.is_org_member(auth.uid(), org_id)
  );

-- UPDATE: Only members can update membership records in their org
CREATE POLICY "org_members_update_policy" ON public.org_members
  FOR UPDATE
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id))
  WITH CHECK (public.is_org_member(auth.uid(), org_id));

-- DELETE: Users can remove themselves or others if they're a member
CREATE POLICY "org_members_delete_policy" ON public.org_members
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid() 
    OR public.is_org_member(auth.uid(), org_id)
  );

-- ============================================
-- STEP 6: Create RLS policies for tenant_user_links table
-- ============================================

-- SELECT: Users can view their own links OR org members can view links in their org
CREATE POLICY "tenant_user_links_select_policy" ON public.tenant_user_links
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR public.is_org_member(auth.uid(), org_id)
  );

-- INSERT: Org members can create tenant links in their org
CREATE POLICY "tenant_user_links_insert_policy" ON public.tenant_user_links
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_org_member(auth.uid(), org_id)
  );

-- UPDATE: Org members can update tenant links in their org
CREATE POLICY "tenant_user_links_update_policy" ON public.tenant_user_links
  FOR UPDATE
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id))
  WITH CHECK (public.is_org_member(auth.uid(), org_id));

-- DELETE: Org members can delete tenant links in their org
CREATE POLICY "tenant_user_links_delete_policy" ON public.tenant_user_links
  FOR DELETE
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id));

-- ============================================
-- STEP 7: Create RLS policies for tenant_claim_codes table
-- ============================================

-- SELECT: Users can view their own claim codes OR org members can view codes claimed in their org
CREATE POLICY "tenant_claim_codes_select_policy" ON public.tenant_claim_codes
  FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR (org_id IS NOT NULL AND public.is_org_member(auth.uid(), org_id))
  );

-- INSERT: Any authenticated user can create a claim code for themselves
CREATE POLICY "tenant_claim_codes_insert_policy" ON public.tenant_claim_codes
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- UPDATE: Users can update their own codes OR org members can update codes in their org
CREATE POLICY "tenant_claim_codes_update_policy" ON public.tenant_claim_codes
  FOR UPDATE
  TO authenticated
  USING (
    user_id = auth.uid()
    OR (org_id IS NOT NULL AND public.is_org_member(auth.uid(), org_id))
  )
  WITH CHECK (
    user_id = auth.uid()
    OR (org_id IS NOT NULL AND public.is_org_member(auth.uid(), org_id))
  );

-- DELETE: Users can delete their own codes
CREATE POLICY "tenant_claim_codes_delete_policy" ON public.tenant_claim_codes
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================
-- STEP 8: Grant necessary permissions
-- ============================================

GRANT EXECUTE ON FUNCTION public.get_user_org_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_tenant_org_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_tenant_user(UUID, UUID) TO authenticated;
