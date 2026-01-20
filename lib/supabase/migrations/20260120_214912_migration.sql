-- Fix RLS policies for orgs and org_members tables
-- Must DROP existing functions first since we cannot change parameter names with CREATE OR REPLACE

-- Step 1: Drop existing policies that depend on the functions
DROP POLICY IF EXISTS "Users can view their orgs" ON orgs;
DROP POLICY IF EXISTS "Users can update their orgs" ON orgs;
DROP POLICY IF EXISTS "Users can delete their orgs" ON orgs;
DROP POLICY IF EXISTS "Authenticated users can create orgs" ON orgs;
DROP POLICY IF EXISTS "org_members_select_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_insert_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_update_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_delete_policy" ON org_members;
DROP POLICY IF EXISTS "Allow org members to view org_members" ON org_members;
DROP POLICY IF EXISTS "Allow users to insert org_members" ON org_members;
DROP POLICY IF EXISTS "Allow org admins to update org_members" ON org_members;
DROP POLICY IF EXISTS "Allow org admins to delete org_members" ON org_members;

-- Step 2: Drop existing functions (CASCADE to remove any remaining dependencies)
DROP FUNCTION IF EXISTS public.get_user_org_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_org_member(UUID, UUID) CASCADE;

-- Step 3: Create helper function to get user's org IDs (bypasses RLS)
CREATE FUNCTION public.get_user_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT org_id FROM org_members WHERE user_id = p_user_id;
$$;

-- Step 4: Create helper function to check org membership (bypasses RLS)
CREATE FUNCTION public.is_org_member(p_user_id UUID, p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM org_members WHERE user_id = p_user_id AND org_id = p_org_id);
$$;

-- Step 5: Re-enable RLS on both tables (in case it was disabled)
ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS policies for orgs table
-- INSERT: Any authenticated user can create an org
CREATE POLICY "Authenticated users can create orgs" ON orgs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- SELECT: Users can only view orgs they are members of
CREATE POLICY "Users can view their orgs" ON orgs
  FOR SELECT
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- UPDATE: Users can only update orgs they are members of
CREATE POLICY "Users can update their orgs" ON orgs
  FOR UPDATE
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())))
  WITH CHECK (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- DELETE: Users can only delete orgs they are members of
CREATE POLICY "Users can delete their orgs" ON orgs
  FOR DELETE
  TO authenticated
  USING (id IN (SELECT public.get_user_org_ids(auth.uid())));

-- Step 7: Create RLS policies for org_members table
-- SELECT: Users can view members of orgs they belong to
CREATE POLICY "org_members_select_policy" ON org_members
  FOR SELECT
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id));

-- INSERT: Users can add themselves to an org (for new org creation)
-- or add others if they're already a member
CREATE POLICY "org_members_insert_policy" ON org_members
  FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid() 
    OR public.is_org_member(auth.uid(), org_id)
  );

-- UPDATE: Users can update their own membership or members of orgs they belong to
CREATE POLICY "org_members_update_policy" ON org_members
  FOR UPDATE
  TO authenticated
  USING (public.is_org_member(auth.uid(), org_id))
  WITH CHECK (public.is_org_member(auth.uid(), org_id));

-- DELETE: Users can remove their own membership or remove others if they're a member
CREATE POLICY "org_members_delete_policy" ON org_members
  FOR DELETE
  TO authenticated
  USING (
    user_id = auth.uid() 
    OR public.is_org_member(auth.uid(), org_id)
  );
