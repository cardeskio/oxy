-- Fix RLS policies for orgs and org_members tables to prevent infinite recursion
-- and allow new org creation

-- Step 1: Create a SECURITY DEFINER function that bypasses RLS to check membership
-- This prevents infinite recursion when policies query org_members

CREATE OR REPLACE FUNCTION public.get_user_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT org_id FROM org_members WHERE user_id = p_user_id;
$$;

-- Step 2: Create a helper function to check if user is member of an org
CREATE OR REPLACE FUNCTION public.is_org_member(p_org_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM org_members 
    WHERE org_id = p_org_id AND user_id = p_user_id
  );
$$;

-- Step 3: Drop existing policies on orgs table (if any)
DROP POLICY IF EXISTS "Allow authenticated users full access to orgs" ON orgs;
DROP POLICY IF EXISTS "org_select_policy" ON orgs;
DROP POLICY IF EXISTS "org_insert_policy" ON orgs;
DROP POLICY IF EXISTS "org_update_policy" ON orgs;
DROP POLICY IF EXISTS "org_delete_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_select_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_insert_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_update_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_delete_policy" ON orgs;

-- Step 4: Create new policies for orgs table

-- SELECT: Only see orgs you're a member of
CREATE POLICY "orgs_select_policy" ON orgs
  FOR SELECT
  USING (id IN (SELECT get_user_org_ids(auth.uid())));

-- INSERT: Any authenticated user can create a new org
CREATE POLICY "orgs_insert_policy" ON orgs
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: Only members can update their orgs
CREATE POLICY "orgs_update_policy" ON orgs
  FOR UPDATE
  USING (is_org_member(id, auth.uid()))
  WITH CHECK (is_org_member(id, auth.uid()));

-- DELETE: Only members can delete their orgs
CREATE POLICY "orgs_delete_policy" ON orgs
  FOR DELETE
  USING (is_org_member(id, auth.uid()));

-- Step 5: Drop existing policies on org_members table (if any)
DROP POLICY IF EXISTS "Allow authenticated users full access to org_members" ON org_members;
DROP POLICY IF EXISTS "org_members_select_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_insert_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_update_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_delete_policy" ON org_members;

-- Step 6: Create new policies for org_members table

-- SELECT: Can see members of orgs you belong to
CREATE POLICY "org_members_select_policy" ON org_members
  FOR SELECT
  USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- INSERT: Can add members to orgs you belong to, OR can add yourself (for initial org creation)
CREATE POLICY "org_members_insert_policy" ON org_members
  FOR INSERT
  WITH CHECK (
    -- Allow if you're adding yourself
    user_id = auth.uid()
    -- OR if you're already a member of the org
    OR is_org_member(org_id, auth.uid())
  );

-- UPDATE: Only members can update members in their orgs
CREATE POLICY "org_members_update_policy" ON org_members
  FOR UPDATE
  USING (is_org_member(org_id, auth.uid()))
  WITH CHECK (is_org_member(org_id, auth.uid()));

-- DELETE: Members can remove members from their orgs (but not themselves easily for safety)
CREATE POLICY "org_members_delete_policy" ON org_members
  FOR DELETE
  USING (is_org_member(org_id, auth.uid()));

-- Step 7: Update other org-scoped tables to use the helper function
-- This ensures they use the SECURITY DEFINER function and avoid recursion

-- Charge Types
DROP POLICY IF EXISTS "Allow authenticated users full access to charge_types" ON charge_types;
CREATE POLICY "charge_types_policy" ON charge_types
  FOR ALL
  USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
  WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Vendors
DROP POLICY IF EXISTS "Allow authenticated users full access to vendors" ON vendors;
CREATE POLICY "vendors_policy" ON vendors
  FOR ALL
  USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
  WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));
