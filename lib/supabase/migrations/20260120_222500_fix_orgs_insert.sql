-- Migration: Fix orgs INSERT policy
-- This migration ensures users can create organizations

-- Start fresh: disable RLS temporarily to clean up
ALTER TABLE public.orgs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.charge_types DISABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies on orgs (brute force approach)
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'orgs' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.orgs', pol.policyname);
    END LOOP;
END $$;

-- Drop ALL existing policies on org_members
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'org_members' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.org_members', pol.policyname);
    END LOOP;
END $$;

-- Drop ALL existing policies on charge_types
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'charge_types' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.charge_types', pol.policyname);
    END LOOP;
END $$;

-- Drop and recreate helper function with explicit permissions
DROP FUNCTION IF EXISTS public.get_user_org_ids(uuid) CASCADE;

CREATE OR REPLACE FUNCTION public.get_user_org_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT org_id FROM public.org_members WHERE user_id = p_user_id;
$$;

-- Grant execute to all roles that might need it
GRANT EXECUTE ON FUNCTION public.get_user_org_ids(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_org_ids(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.get_user_org_ids(uuid) TO service_role;

-- Re-enable RLS
ALTER TABLE public.orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.charge_types ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- ORGS POLICIES
-- ============================================================================

-- Allow ALL authenticated users to INSERT into orgs (creating a new org)
CREATE POLICY "orgs_insert_any_authenticated"
ON public.orgs FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow org members to SELECT their orgs
CREATE POLICY "orgs_select_members"
ON public.orgs FOR SELECT
TO authenticated
USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- Allow org members to UPDATE their orgs
CREATE POLICY "orgs_update_members"
ON public.orgs FOR UPDATE
TO authenticated
USING (id IN (SELECT public.get_user_org_ids(auth.uid())))
WITH CHECK (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- Allow org members to DELETE their orgs
CREATE POLICY "orgs_delete_members"
ON public.orgs FOR DELETE
TO authenticated
USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- ============================================================================
-- ORG_MEMBERS POLICIES
-- ============================================================================

-- Allow authenticated users to INSERT themselves as org members
-- This is needed when creating a new org (user adds themselves as owner)
CREATE POLICY "org_members_insert_self"
ON public.org_members FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Allow org members to view members of their orgs
CREATE POLICY "org_members_select"
ON public.org_members FOR SELECT
TO authenticated
USING (
    user_id = auth.uid() 
    OR org_id IN (SELECT public.get_user_org_ids(auth.uid()))
);

-- Allow org members to UPDATE members in their orgs
CREATE POLICY "org_members_update"
ON public.org_members FOR UPDATE
TO authenticated
USING (org_id IN (SELECT public.get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT public.get_user_org_ids(auth.uid())));

-- Allow org members to DELETE members from their orgs
CREATE POLICY "org_members_delete"
ON public.org_members FOR DELETE
TO authenticated
USING (org_id IN (SELECT public.get_user_org_ids(auth.uid())));

-- ============================================================================
-- CHARGE_TYPES POLICIES
-- ============================================================================

-- Allow org members full access to their charge types
CREATE POLICY "charge_types_all_org"
ON public.charge_types FOR ALL
TO authenticated
USING (org_id IN (SELECT public.get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT public.get_user_org_ids(auth.uid())));

-- ============================================================================
-- GRANT TABLE PERMISSIONS
-- ============================================================================

-- Ensure authenticated role has all necessary table permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orgs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.org_members TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.charge_types TO authenticated;

-- Grant usage on sequences if they exist
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;
