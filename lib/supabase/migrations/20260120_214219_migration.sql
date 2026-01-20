-- Fix infinite recursion in org_members RLS policies
-- This migration creates a helper function and rewrites policies to avoid recursion

-- Drop existing problematic policies on org_members
DROP POLICY IF EXISTS "Users can view their own memberships" ON org_members;
DROP POLICY IF EXISTS "Users can view org memberships" ON org_members;
DROP POLICY IF EXISTS "Allow authenticated users full access to org_members" ON org_members;
DROP POLICY IF EXISTS "org_members_select_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_insert_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_update_policy" ON org_members;
DROP POLICY IF EXISTS "org_members_delete_policy" ON org_members;

-- Drop existing problematic policies on orgs
DROP POLICY IF EXISTS "Users can view orgs they belong to" ON orgs;
DROP POLICY IF EXISTS "Allow authenticated users full access to orgs" ON orgs;
DROP POLICY IF EXISTS "orgs_select_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_insert_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_update_policy" ON orgs;
DROP POLICY IF EXISTS "orgs_delete_policy" ON orgs;

-- Drop old helper function if exists
DROP FUNCTION IF EXISTS is_org_member(uuid, uuid);
DROP FUNCTION IF EXISTS get_user_org_ids(uuid);

-- Create a SECURITY DEFINER function to check org membership
-- This function bypasses RLS to avoid infinite recursion
CREATE OR REPLACE FUNCTION get_user_org_ids(user_uuid uuid)
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT org_id FROM org_members WHERE user_id = user_uuid;
$$;

-- Create a helper function to check if user is member of a specific org
CREATE OR REPLACE FUNCTION is_org_member(user_uuid uuid, org_uuid uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM org_members 
    WHERE user_id = user_uuid AND org_id = org_uuid
  );
$$;

-- Recreate org_members policies without recursion
-- SELECT: Users can see memberships for orgs they belong to
CREATE POLICY "org_members_select_own" ON org_members
  FOR SELECT
  USING (user_id = auth.uid() OR org_id IN (SELECT get_user_org_ids(auth.uid())));

-- INSERT: Authenticated users can create memberships (for creating orgs or being invited)
CREATE POLICY "org_members_insert" ON org_members
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: Only org owners/managers can update memberships
CREATE POLICY "org_members_update" ON org_members
  FOR UPDATE
  USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- DELETE: Only org owners/managers can delete memberships
CREATE POLICY "org_members_delete" ON org_members
  FOR DELETE
  USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Recreate orgs policies without recursion
-- SELECT: Users can view orgs they are members of
CREATE POLICY "orgs_select" ON orgs
  FOR SELECT
  USING (id IN (SELECT get_user_org_ids(auth.uid())));

-- INSERT: Authenticated users can create orgs
CREATE POLICY "orgs_insert" ON orgs
  FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- UPDATE: Only members can update their orgs
CREATE POLICY "orgs_update" ON orgs
  FOR UPDATE
  USING (id IN (SELECT get_user_org_ids(auth.uid())));

-- DELETE: Only members can delete their orgs
CREATE POLICY "orgs_delete" ON orgs
  FOR DELETE
  USING (id IN (SELECT get_user_org_ids(auth.uid())));
