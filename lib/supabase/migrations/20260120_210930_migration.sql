-- Migration to fix role-based access control
-- This migration handles the case where objects may already exist

-- ====================
-- 1. CREATE NEW TABLES (IF NOT EXISTS)
-- ====================

-- Profiles table (linked to auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'tenant' CHECK (role IN ('owner', 'admin', 'staff', 'tenant')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organizations table
CREATE TABLE IF NOT EXISTS orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organization members (links users to orgs with roles)
CREATE TABLE IF NOT EXISTS org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'staff' CHECK (role IN ('owner', 'admin', 'staff')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

-- Charge types table
CREATE TABLE IF NOT EXISTS charge_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vendors table
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  specialization TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tenant claim codes table
CREATE TABLE IF NOT EXISTS tenant_claim_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  code TEXT NOT NULL UNIQUE,
  claimed BOOLEAN NOT NULL DEFAULT FALSE,
  claimed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days')
);

-- Tenant user links (links auth users to tenant profiles)
CREATE TABLE IF NOT EXISTS tenant_user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, tenant_id)
);

-- ====================
-- 2. ADD ORG_ID COLUMNS TO EXISTING TABLES (IF NOT EXISTS)
-- ====================

-- Add org_id to properties
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'org_id') THEN
    ALTER TABLE properties ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add org_id to units
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'units' AND column_name = 'org_id') THEN
    ALTER TABLE units ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add org_id to tenants
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'org_id') THEN
    ALTER TABLE tenants ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add org_id to leases
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leases' AND column_name = 'org_id') THEN
    ALTER TABLE leases ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add org_id to invoices
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = 'org_id') THEN
    ALTER TABLE invoices ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add org_id to payments
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payments' AND column_name = 'org_id') THEN
    ALTER TABLE payments ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add org_id to maintenance_tickets
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'org_id') THEN
    ALTER TABLE maintenance_tickets ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- ====================
-- 3. CREATE INDEXES (IF NOT EXISTS)
-- ====================

CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON org_members(org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON org_members(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_user_links_user_id ON tenant_user_links(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_user_links_tenant_id ON tenant_user_links(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_claim_codes_code ON tenant_claim_codes(code);
CREATE INDEX IF NOT EXISTS idx_tenant_claim_codes_tenant_id ON tenant_claim_codes(tenant_id);
CREATE INDEX IF NOT EXISTS idx_properties_org_id ON properties(org_id);
CREATE INDEX IF NOT EXISTS idx_units_org_id ON units(org_id);
CREATE INDEX IF NOT EXISTS idx_tenants_org_id ON tenants(org_id);
CREATE INDEX IF NOT EXISTS idx_leases_org_id ON leases(org_id);
CREATE INDEX IF NOT EXISTS idx_invoices_org_id ON invoices(org_id);
CREATE INDEX IF NOT EXISTS idx_payments_org_id ON payments(org_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_tickets_org_id ON maintenance_tickets(org_id);
CREATE INDEX IF NOT EXISTS idx_charge_types_org_id ON charge_types(org_id);
CREATE INDEX IF NOT EXISTS idx_vendors_org_id ON vendors(org_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_id ON audit_logs(org_id);

-- ====================
-- 4. ENABLE RLS ON NEW TABLES
-- ====================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE charge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_claim_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_user_links ENABLE ROW LEVEL SECURITY;

-- ====================
-- 5. DROP EXISTING POLICIES (to avoid conflicts)
-- ====================

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

-- Orgs policies
DROP POLICY IF EXISTS "Users can view orgs they belong to" ON orgs;
DROP POLICY IF EXISTS "Org owners can update their orgs" ON orgs;
DROP POLICY IF EXISTS "Allow authenticated users to create orgs" ON orgs;

-- Org members policies
DROP POLICY IF EXISTS "Users can view org members of their orgs" ON org_members;
DROP POLICY IF EXISTS "Org owners can manage members" ON org_members;
DROP POLICY IF EXISTS "Allow org creation member insert" ON org_members;

-- Tenant claim codes policies
DROP POLICY IF EXISTS "Org members can view claim codes" ON tenant_claim_codes;
DROP POLICY IF EXISTS "Org members can create claim codes" ON tenant_claim_codes;
DROP POLICY IF EXISTS "Anyone can claim with valid code" ON tenant_claim_codes;

-- Tenant user links policies
DROP POLICY IF EXISTS "Users can view own tenant links" ON tenant_user_links;
DROP POLICY IF EXISTS "Org members can view tenant links" ON tenant_user_links;
DROP POLICY IF EXISTS "Users can create own tenant links" ON tenant_user_links;

-- Properties policies (drop old simple policy)
DROP POLICY IF EXISTS "Allow authenticated users full access to properties" ON properties;
DROP POLICY IF EXISTS "Org members can view properties" ON properties;
DROP POLICY IF EXISTS "Org members can manage properties" ON properties;

-- Units policies
DROP POLICY IF EXISTS "Allow authenticated users full access to units" ON units;
DROP POLICY IF EXISTS "Org members can view units" ON units;
DROP POLICY IF EXISTS "Org members can manage units" ON units;

-- Tenants policies
DROP POLICY IF EXISTS "Allow authenticated users full access to tenants" ON tenants;
DROP POLICY IF EXISTS "Org members can view tenants" ON tenants;
DROP POLICY IF EXISTS "Org members can manage tenants" ON tenants;
DROP POLICY IF EXISTS "Linked users can view own tenant profile" ON tenants;

-- Leases policies
DROP POLICY IF EXISTS "Allow authenticated users full access to leases" ON leases;
DROP POLICY IF EXISTS "Org members can view leases" ON leases;
DROP POLICY IF EXISTS "Org members can manage leases" ON leases;
DROP POLICY IF EXISTS "Linked tenants can view own leases" ON leases;

-- Invoices policies
DROP POLICY IF EXISTS "Allow authenticated users full access to invoices" ON invoices;
DROP POLICY IF EXISTS "Org members can view invoices" ON invoices;
DROP POLICY IF EXISTS "Org members can manage invoices" ON invoices;
DROP POLICY IF EXISTS "Linked tenants can view own invoices" ON invoices;

-- Invoice lines policies
DROP POLICY IF EXISTS "Allow authenticated users full access to invoice_lines" ON invoice_lines;
DROP POLICY IF EXISTS "Org members can view invoice lines" ON invoice_lines;
DROP POLICY IF EXISTS "Org members can manage invoice lines" ON invoice_lines;

-- Payments policies
DROP POLICY IF EXISTS "Allow authenticated users full access to payments" ON payments;
DROP POLICY IF EXISTS "Org members can view payments" ON payments;
DROP POLICY IF EXISTS "Org members can manage payments" ON payments;
DROP POLICY IF EXISTS "Linked tenants can view own payments" ON payments;

-- Payment allocations policies
DROP POLICY IF EXISTS "Allow authenticated users full access to payment_allocations" ON payment_allocations;
DROP POLICY IF EXISTS "Org members can view payment allocations" ON payment_allocations;
DROP POLICY IF EXISTS "Org members can manage payment allocations" ON payment_allocations;

-- Maintenance tickets policies
DROP POLICY IF EXISTS "Allow authenticated users full access to maintenance_tickets" ON maintenance_tickets;
DROP POLICY IF EXISTS "Org members can view maintenance tickets" ON maintenance_tickets;
DROP POLICY IF EXISTS "Org members can manage maintenance tickets" ON maintenance_tickets;
DROP POLICY IF EXISTS "Linked tenants can view own tickets" ON maintenance_tickets;
DROP POLICY IF EXISTS "Linked tenants can create tickets" ON maintenance_tickets;

-- Maintenance costs policies
DROP POLICY IF EXISTS "Allow authenticated users full access to maintenance_costs" ON maintenance_costs;
DROP POLICY IF EXISTS "Org members can view maintenance costs" ON maintenance_costs;
DROP POLICY IF EXISTS "Org members can manage maintenance costs" ON maintenance_costs;

-- Charge types policies
DROP POLICY IF EXISTS "Org members can view charge types" ON charge_types;
DROP POLICY IF EXISTS "Org members can manage charge types" ON charge_types;

-- Vendors policies
DROP POLICY IF EXISTS "Org members can view vendors" ON vendors;
DROP POLICY IF EXISTS "Org members can manage vendors" ON vendors;

-- Audit logs policies
DROP POLICY IF EXISTS "Org members can view audit logs" ON audit_logs;
DROP POLICY IF EXISTS "System can insert audit logs" ON audit_logs;

-- ====================
-- 6. CREATE NEW POLICIES
-- ====================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (id = auth.uid());

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (id = auth.uid());

-- Orgs policies
CREATE POLICY "Users can view orgs they belong to" ON orgs
  FOR SELECT USING (
    id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org owners can update their orgs" ON orgs
  FOR UPDATE USING (
    id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role = 'owner')
  ) WITH CHECK (
    id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role = 'owner')
  );

CREATE POLICY "Allow authenticated users to create orgs" ON orgs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Org members policies
CREATE POLICY "Users can view org members of their orgs" ON org_members
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org owners can manage members" ON org_members
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role = 'owner')
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role = 'owner')
  );

CREATE POLICY "Allow org creation member insert" ON org_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Tenant claim codes policies
CREATE POLICY "Org members can view claim codes" ON tenant_claim_codes
  FOR SELECT USING (
    tenant_id IN (SELECT id FROM tenants WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

CREATE POLICY "Org members can create claim codes" ON tenant_claim_codes
  FOR INSERT WITH CHECK (
    tenant_id IN (SELECT id FROM tenants WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

CREATE POLICY "Anyone can claim with valid code" ON tenant_claim_codes
  FOR UPDATE USING (auth.uid() IS NOT NULL AND claimed = false)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Tenant user links policies
CREATE POLICY "Users can view own tenant links" ON tenant_user_links
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Org members can view tenant links" ON tenant_user_links
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can create own tenant links" ON tenant_user_links
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Properties policies (org-scoped)
CREATE POLICY "Org members can view properties" ON properties
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR org_id IN (SELECT org_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage properties" ON properties
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Units policies (org-scoped)
CREATE POLICY "Org members can view units" ON units
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR org_id IN (SELECT org_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage units" ON units
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Tenants policies (org-scoped)
CREATE POLICY "Org members can view tenants" ON tenants
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage tenants" ON tenants
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Linked users can view own tenant profile" ON tenants
  FOR SELECT USING (
    id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

-- Leases policies (org-scoped)
CREATE POLICY "Org members can view leases" ON leases
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage leases" ON leases
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Linked tenants can view own leases" ON leases
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

-- Invoices policies (org-scoped)
CREATE POLICY "Org members can view invoices" ON invoices
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage invoices" ON invoices
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Linked tenants can view own invoices" ON invoices
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

-- Invoice lines policies
CREATE POLICY "Org members can view invoice lines" ON invoice_lines
  FOR SELECT USING (
    invoice_id IN (SELECT id FROM invoices WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

CREATE POLICY "Org members can manage invoice lines" ON invoice_lines
  FOR ALL USING (
    invoice_id IN (SELECT id FROM invoices WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  ) WITH CHECK (
    invoice_id IN (SELECT id FROM invoices WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

-- Payments policies (org-scoped)
CREATE POLICY "Org members can view payments" ON payments
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage payments" ON payments
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Linked tenants can view own payments" ON payments
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

-- Payment allocations policies
CREATE POLICY "Org members can view payment allocations" ON payment_allocations
  FOR SELECT USING (
    payment_id IN (SELECT id FROM payments WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

CREATE POLICY "Org members can manage payment allocations" ON payment_allocations
  FOR ALL USING (
    payment_id IN (SELECT id FROM payments WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  ) WITH CHECK (
    payment_id IN (SELECT id FROM payments WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

-- Maintenance tickets policies (org-scoped)
CREATE POLICY "Org members can view maintenance tickets" ON maintenance_tickets
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage maintenance tickets" ON maintenance_tickets
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Linked tenants can view own tickets" ON maintenance_tickets
  FOR SELECT USING (
    tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

CREATE POLICY "Linked tenants can create tickets" ON maintenance_tickets
  FOR INSERT WITH CHECK (
    tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );

-- Maintenance costs policies
CREATE POLICY "Org members can view maintenance costs" ON maintenance_costs
  FOR SELECT USING (
    ticket_id IN (SELECT id FROM maintenance_tickets WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

CREATE POLICY "Org members can manage maintenance costs" ON maintenance_costs
  FOR ALL USING (
    ticket_id IN (SELECT id FROM maintenance_tickets WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  ) WITH CHECK (
    ticket_id IN (SELECT id FROM maintenance_tickets WHERE org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid()))
  );

-- Charge types policies (org-scoped)
CREATE POLICY "Org members can view charge types" ON charge_types
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage charge types" ON charge_types
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Vendors policies (org-scoped)
CREATE POLICY "Org members can view vendors" ON vendors
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "Org members can manage vendors" ON vendors
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

-- Audit logs policies (org-scoped, read-only for users)
CREATE POLICY "Org members can view audit logs" ON audit_logs
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );

CREATE POLICY "System can insert audit logs" ON audit_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
