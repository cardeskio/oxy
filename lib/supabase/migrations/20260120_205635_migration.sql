-- =============================================
-- Auth & Multi-tenant Migration
-- =============================================

-- Profiles table (linked to auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organizations table
CREATE TABLE IF NOT EXISTS orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'KE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organization members (linking users to orgs with roles)
CREATE TABLE IF NOT EXISTS org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'accountant', 'caretaker', 'tenant_admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

-- Charge types table
CREATE TABLE IF NOT EXISTS charge_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  default_amount NUMERIC(10, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vendors table
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  trade TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  metadata_json JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tenant claim codes table (for tenant signup flow)
CREATE TABLE IF NOT EXISTS tenant_claim_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id UUID REFERENCES orgs(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
  claimed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Tenant user links table (linking auth users to tenant records)
CREATE TABLE IF NOT EXISTS tenant_user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, tenant_id)
);

-- Add org_id to all existing tables for multi-tenant support
ALTER TABLE properties ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
ALTER TABLE units ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
ALTER TABLE leases ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
ALTER TABLE maintenance_tickets ADD COLUMN IF NOT EXISTS org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;

-- Add user_id to tenants for linking to auth users
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON org_members(org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON org_members(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_claim_codes_code ON tenant_claim_codes(code);
CREATE INDEX IF NOT EXISTS idx_tenant_claim_codes_user_id ON tenant_claim_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_user_links_user_id ON tenant_user_links(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_user_links_tenant_id ON tenant_user_links(tenant_id);
CREATE INDEX IF NOT EXISTS idx_properties_org_id ON properties(org_id);
CREATE INDEX IF NOT EXISTS idx_units_org_id ON units(org_id);
CREATE INDEX IF NOT EXISTS idx_tenants_org_id ON tenants(org_id);
CREATE INDEX IF NOT EXISTS idx_tenants_user_id ON tenants(user_id);
CREATE INDEX IF NOT EXISTS idx_leases_org_id ON leases(org_id);
CREATE INDEX IF NOT EXISTS idx_invoices_org_id ON invoices(org_id);
CREATE INDEX IF NOT EXISTS idx_payments_org_id ON payments(org_id);
CREATE INDEX IF NOT EXISTS idx_maintenance_tickets_org_id ON maintenance_tickets(org_id);
CREATE INDEX IF NOT EXISTS idx_charge_types_org_id ON charge_types(org_id);
CREATE INDEX IF NOT EXISTS idx_vendors_org_id ON vendors(org_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_id ON audit_logs(org_id);

-- Enable RLS on new tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE charge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_claim_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_user_links ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Orgs policies (users can only see orgs they belong to)
CREATE POLICY "Users can view orgs they belong to" ON orgs
  FOR SELECT USING (
    id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Authenticated users can create orgs" ON orgs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Org owners can update their orgs" ON orgs
  FOR UPDATE USING (
    id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role = 'owner')
  );

-- Org members policies
CREATE POLICY "Users can view members of their orgs" ON org_members
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Org owners/managers can manage members" ON org_members
  FOR ALL USING (
    org_id IN (SELECT om.org_id FROM org_members om WHERE om.user_id = auth.uid() AND om.role IN ('owner', 'manager'))
  ) WITH CHECK (
    org_id IN (SELECT om.org_id FROM org_members om WHERE om.user_id = auth.uid() AND om.role IN ('owner', 'manager'))
  );

-- Charge types policies
CREATE POLICY "Users can view charge types of their orgs" ON charge_types
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Managers can manage charge types" ON charge_types
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
  );

-- Vendors policies
CREATE POLICY "Users can view vendors of their orgs" ON vendors
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
  );
CREATE POLICY "Managers can manage vendors" ON vendors
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

-- Audit logs policies
CREATE POLICY "Users can view audit logs of their orgs" ON audit_logs
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'accountant'))
  );
CREATE POLICY "System can insert audit logs" ON audit_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Tenant claim codes policies
CREATE POLICY "Users can view their own claim codes" ON tenant_claim_codes
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Users can create their own claim codes" ON tenant_claim_codes
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Org managers can view and claim codes" ON tenant_claim_codes
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
    OR user_id = auth.uid()
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
    OR user_id = auth.uid()
  );

-- Tenant user links policies
CREATE POLICY "Users can view their own tenant links" ON tenant_user_links
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "Org managers can manage tenant links" ON tenant_user_links
  FOR ALL USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  ) WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

-- Update existing table policies to use org_id
DROP POLICY IF EXISTS "Allow authenticated users full access to properties" ON properties;
CREATE POLICY "Users can access properties in their orgs" ON properties
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR org_id IN (SELECT org_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Managers can manage properties" ON properties
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );
CREATE POLICY "Managers can update properties" ON properties
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );
CREATE POLICY "Managers can delete properties" ON properties
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to units" ON units;
CREATE POLICY "Users can access units in their orgs" ON units
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR org_id IN (SELECT org_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Managers can manage units" ON units
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );
CREATE POLICY "Managers can update units" ON units
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'caretaker'))
  );
CREATE POLICY "Managers can delete units" ON units
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to tenants" ON tenants;
CREATE POLICY "Users can access tenants in their orgs" ON tenants
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR user_id = auth.uid()
  );
CREATE POLICY "Staff can manage tenants" ON tenants
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'caretaker'))
  );
CREATE POLICY "Staff can update tenants" ON tenants
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'caretaker'))
    OR user_id = auth.uid()
  );
CREATE POLICY "Managers can delete tenants" ON tenants
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to leases" ON leases;
CREATE POLICY "Users can access leases in their orgs" ON leases
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Staff can manage leases" ON leases
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );
CREATE POLICY "Staff can update leases" ON leases
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );
CREATE POLICY "Managers can delete leases" ON leases
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to invoices" ON invoices;
CREATE POLICY "Users can access invoices in their orgs" ON invoices
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Staff can create invoices" ON invoices
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
  );
CREATE POLICY "Staff can update invoices" ON invoices
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
  );
CREATE POLICY "Managers can delete invoices" ON invoices
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to invoice_lines" ON invoice_lines;
CREATE POLICY "Users can access invoice lines" ON invoice_lines
  FOR SELECT USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
        OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
    )
  );
CREATE POLICY "Staff can manage invoice lines" ON invoice_lines
  FOR ALL USING (
    invoice_id IN (
      SELECT id FROM invoices WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
    )
  ) WITH CHECK (
    invoice_id IN (
      SELECT id FROM invoices WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
    )
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to payments" ON payments;
CREATE POLICY "Users can access payments in their orgs" ON payments
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Staff can create payments" ON payments
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant', 'caretaker'))
  );
CREATE POLICY "Staff can update payments" ON payments
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant'))
  );
CREATE POLICY "Managers can delete payments" ON payments
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to payment_allocations" ON payment_allocations;
CREATE POLICY "Users can access payment allocations" ON payment_allocations
  FOR SELECT USING (
    payment_id IN (
      SELECT id FROM payments WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
        OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
    )
  );
CREATE POLICY "Staff can manage payment allocations" ON payment_allocations
  FOR ALL USING (
    payment_id IN (
      SELECT id FROM payments WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant', 'caretaker'))
    )
  ) WITH CHECK (
    payment_id IN (
      SELECT id FROM payments WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'accountant', 'caretaker'))
    )
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to maintenance_tickets" ON maintenance_tickets;
CREATE POLICY "Users can access tickets in their orgs" ON maintenance_tickets
  FOR SELECT USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Users can create tickets" ON maintenance_tickets
  FOR INSERT WITH CHECK (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR org_id IN (SELECT org_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Staff can update tickets" ON maintenance_tickets
  FOR UPDATE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    OR tenant_id IN (SELECT tenant_id FROM tenant_user_links WHERE user_id = auth.uid())
  );
CREATE POLICY "Managers can delete tickets" ON maintenance_tickets
  FOR DELETE USING (
    org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager'))
  );

DROP POLICY IF EXISTS "Allow authenticated users full access to maintenance_costs" ON maintenance_costs;
CREATE POLICY "Users can view maintenance costs" ON maintenance_costs
  FOR SELECT USING (
    ticket_id IN (
      SELECT id FROM maintenance_tickets WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid())
    )
  );
CREATE POLICY "Staff can manage maintenance costs" ON maintenance_costs
  FOR ALL USING (
    ticket_id IN (
      SELECT id FROM maintenance_tickets WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'caretaker'))
    )
  ) WITH CHECK (
    ticket_id IN (
      SELECT id FROM maintenance_tickets WHERE 
        org_id IN (SELECT org_id FROM org_members WHERE user_id = auth.uid() AND role IN ('owner', 'manager', 'caretaker'))
    )
  );
