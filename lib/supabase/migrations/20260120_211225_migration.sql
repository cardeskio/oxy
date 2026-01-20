-- Fix: Add org_id column to tenant_user_links if it doesn't exist
-- This fixes the policy error where org_id column was referenced but not present

-- ====================
-- 1. ADD ORG_ID TO TENANT_USER_LINKS (IF NOT EXISTS)
-- ====================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenant_user_links' AND column_name = 'org_id') THEN
    ALTER TABLE tenant_user_links ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ====================
-- 2. CREATE INDEX ON TENANT_USER_LINKS ORG_ID (IF NOT EXISTS)
-- ====================

CREATE INDEX IF NOT EXISTS idx_tenant_user_links_org_id ON tenant_user_links(org_id);

-- ====================
-- 3. DROP AND RECREATE TENANT_USER_LINKS POLICIES
-- ====================

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own tenant links" ON tenant_user_links;
DROP POLICY IF EXISTS "Org members can view tenant links" ON tenant_user_links;
DROP POLICY IF EXISTS "Users can create own tenant links" ON tenant_user_links;

-- Recreate policies
CREATE POLICY "Users can view own tenant links" ON tenant_user_links
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Org members can view tenant links" ON tenant_user_links
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create own tenant links" ON tenant_user_links
  FOR INSERT WITH CHECK (user_id = auth.uid());
