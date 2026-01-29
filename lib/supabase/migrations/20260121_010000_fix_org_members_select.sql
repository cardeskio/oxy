-- Fix org_members SELECT policy to allow users to see their own memberships
-- This fixes the bootstrap problem where users can't see their org memberships

-- Add policy allowing users to SELECT their own org_members records
-- This ensures users can always see orgs they belong to
CREATE POLICY "org_members_select_own"
ON public.org_members FOR SELECT
TO authenticated
USING (user_id = auth.uid());
