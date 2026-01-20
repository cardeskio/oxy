-- Complete RLS fix for orgs and org_members tables
-- This migration drops ALL existing policies and recreates them cleanly

-- Step 1: Drop ALL policies on orgs table (regardless of name)
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'orgs' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.orgs', pol.policyname);
    END LOOP;
END $$;

-- Step 2: Drop ALL policies on org_members table (regardless of name)
DO $$ 
DECLARE
    pol record;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'org_members' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.org_members', pol.policyname);
    END LOOP;
END $$;

-- Step 3: Drop existing helper functions
DROP FUNCTION IF EXISTS public.get_user_org_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_org_member(UUID, UUID) CASCADE;

-- Step 4: Create helper function to get user's org IDs (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_user_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT org_id FROM org_members WHERE user_id = p_user_id;
$$;

-- Step 5: Create helper function to check org membership (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_org_member(p_user_id UUID, p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM org_members WHERE user_id = p_user_id AND org_id = p_org_id);
$$;

-- Step 6: Ensure RLS is enabled on both tables
ALTER TABLE public.orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS policies for orgs table
-- INSERT: Any authenticated user can create an org (no restrictions)
CREATE POLICY "orgs_insert_policy" ON public.orgs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- SELECT: Users can only view orgs they are members of
CREATE POLICY "orgs_select_policy" ON public.orgs
  FOR SELECT
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- UPDATE: Users can only update orgs they are members of
CREATE POLICY "orgs_update_policy" ON public.orgs
  FOR UPDATE
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())))
  WITH CHECK (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- DELETE: Users can only delete orgs they are members of
CREATE POLICY "orgs_delete_policy" ON public.orgs
  FOR DELETE
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- Step 8: Create RLS policies for org_members table
-- SELECT: Users can view members of orgs they belong to
CREATE POLICY "org_members_select_policy" ON public.org_members
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id));

-- INSERT: Users can add themselves to any org (for new org creation)
-- OR add others if they're already a member of that org
CREATE POLICY "org_members_insert_policy" ON public.org_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() 
    OR public.is_org_member(auth.uid(), org_id)
  );

-- UPDATE: Only members of the org can update membership records
CREATE POLICY "org_members_update_policy" ON public.org_members
  FOR UPDATE
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id))
  WITH CHECK (public.is_org_member(auth.uid(), org_id));

-- DELETE: Users can remove themselves, or remove others if they're a member
CREATE POLICY "org_members_delete_policy" ON public.org_members
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid() 
    OR public.is_org_member(auth.uid(), org_id)
  );

-- Step 9: Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.get_user_org_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_member(UUID, UUID) TO authenticated;
