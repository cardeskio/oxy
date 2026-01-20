-- ==============================================
-- Kenya Property Management System - Full PRD Migration
-- Multi-tenant SaaS with org_id isolation
-- ==============================================

-- ==============================================
-- PART 1: IDENTITY & ACCESS TABLES
-- ==============================================

-- Profiles table (linked to auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organizations table
CREATE TABLE orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'KE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Organization members table (role-based access)
CREATE TABLE org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'manager', 'accountant', 'caretaker', 'tenant_admin')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

-- Tenant-User links (for tenant portal access)
CREATE TABLE tenant_user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(tenant_id, user_id)
);

-- ==============================================
-- PART 2: ADD ORG_ID TO EXISTING TABLES
-- ==============================================

-- Add org_id to properties
ALTER TABLE properties ADD COLUMN org_id UUID;

-- Add org_id to units
ALTER TABLE units ADD COLUMN org_id UUID;

-- Add org_id to tenants
ALTER TABLE tenants ADD COLUMN org_id UUID;

-- Add org_id to leases
ALTER TABLE leases ADD COLUMN org_id UUID;

-- Add org_id to invoices
ALTER TABLE invoices ADD COLUMN org_id UUID;

-- Add org_id to invoice_lines
ALTER TABLE invoice_lines ADD COLUMN org_id UUID;

-- Add org_id to payments
ALTER TABLE payments ADD COLUMN org_id UUID;

-- Add org_id to payment_allocations
ALTER TABLE payment_allocations ADD COLUMN org_id UUID;

-- Add org_id to maintenance_tickets
ALTER TABLE maintenance_tickets ADD COLUMN org_id UUID;

-- Add org_id to maintenance_costs
ALTER TABLE maintenance_costs ADD COLUMN org_id UUID;

-- ==============================================
-- PART 3: ADDITIONAL TABLES FROM PRD
-- ==============================================

-- Unit types table (presets for common unit configurations)
CREATE TABLE unit_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  default_rent_amount NUMERIC(10, 2),
  default_deposit_amount NUMERIC(10, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Charge types table (for invoicing)
CREATE TABLE charge_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  default_amount NUMERIC(10, 2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vendors table (for maintenance)
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  trade TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Documents table (metadata for file storage)
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('lease', 'tenant', 'ticket', 'invoice', 'payment', 'property', 'unit')),
  entity_id UUID NOT NULL,
  storage_path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  uploaded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notification outbox table (for reliable messaging)
CREATE TABLE notification_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  channel TEXT NOT NULL CHECK (channel IN ('sms', 'whatsapp', 'email', 'in_app')),
  recipient TEXT NOT NULL,
  template_key TEXT NOT NULL,
  payload_json JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'sent', 'failed')),
  last_error TEXT,
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Audit logs table (for tracking critical actions)
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  actor_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  metadata_json JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================
-- PART 4: UPDATE CONSTRAINTS AND RELATIONSHIPS
-- ==============================================

-- Add foreign key references for org_id (after tables exist)
ALTER TABLE tenant_user_links ADD CONSTRAINT fk_tenant_user_links_tenant 
  FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

-- Update maintenance_tickets to reference vendors table
ALTER TABLE maintenance_tickets 
  ALTER COLUMN vendor_id TYPE UUID USING vendor_id::uuid,
  ADD CONSTRAINT fk_maintenance_tickets_vendor 
    FOREIGN KEY (vendor_id) REFERENCES vendors(id) ON DELETE SET NULL;

-- Add unique constraint for unit labels within a property
CREATE UNIQUE INDEX idx_units_property_label_unique ON units(property_id, unit_label);

-- Add partial unique index for active leases (only one active lease per unit)
CREATE UNIQUE INDEX idx_leases_unit_active_unique ON leases(unit_id) WHERE status = 'active';

-- Add unit_type_id to units table
ALTER TABLE units ADD COLUMN unit_type_id UUID REFERENCES unit_types(id) ON DELETE SET NULL;

-- Add charge_type_id to invoice_lines
ALTER TABLE invoice_lines ADD COLUMN charge_type_id UUID REFERENCES charge_types(id) ON DELETE SET NULL;

-- ==============================================
-- PART 5: ADDITIONAL INDEXES
-- ==============================================

-- Org-based indexes for performance
CREATE INDEX idx_properties_org_id ON properties(org_id);
CREATE INDEX idx_units_org_id ON units(org_id);
CREATE INDEX idx_tenants_org_id ON tenants(org_id);
CREATE INDEX idx_leases_org_id ON leases(org_id);
CREATE INDEX idx_invoices_org_id ON invoices(org_id);
CREATE INDEX idx_payments_org_id ON payments(org_id);
CREATE INDEX idx_maintenance_tickets_org_id ON maintenance_tickets(org_id);

-- Identity & access indexes
CREATE INDEX idx_org_members_org_id ON org_members(org_id);
CREATE INDEX idx_org_members_user_id ON org_members(user_id);
CREATE INDEX idx_tenant_user_links_tenant_id ON tenant_user_links(tenant_id);
CREATE INDEX idx_tenant_user_links_user_id ON tenant_user_links(user_id);

-- Additional table indexes
CREATE INDEX idx_unit_types_org_id ON unit_types(org_id);
CREATE INDEX idx_charge_types_org_id ON charge_types(org_id);
CREATE INDEX idx_vendors_org_id ON vendors(org_id);
CREATE INDEX idx_documents_org_id ON documents(org_id);
CREATE INDEX idx_documents_entity ON documents(entity_type, entity_id);
CREATE INDEX idx_notification_outbox_org_id ON notification_outbox(org_id);
CREATE INDEX idx_notification_outbox_status ON notification_outbox(status);
CREATE INDEX idx_audit_logs_org_id ON audit_logs(org_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_actor ON audit_logs(actor_user_id);

-- Invoice period indexes for reporting
CREATE INDEX idx_invoices_period ON invoices(period_start, period_end);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);

-- Payment date indexes
CREATE INDEX idx_payments_paid_at ON payments(paid_at);

-- ==============================================
-- PART 6: ROW LEVEL SECURITY POLICIES
-- ==============================================

-- Enable RLS on new tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_user_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE charge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (to replace with org-based policies)
DROP POLICY IF EXISTS "Allow authenticated users full access to properties" ON properties;
DROP POLICY IF EXISTS "Allow authenticated users full access to units" ON units;
DROP POLICY IF EXISTS "Allow authenticated users full access to tenants" ON tenants;
DROP POLICY IF EXISTS "Allow authenticated users full access to leases" ON leases;
DROP POLICY IF EXISTS "Allow authenticated users full access to invoices" ON invoices;
DROP POLICY IF EXISTS "Allow authenticated users full access to invoice_lines" ON invoice_lines;
DROP POLICY IF EXISTS "Allow authenticated users full access to payments" ON payments;
DROP POLICY IF EXISTS "Allow authenticated users full access to payment_allocations" ON payment_allocations;
DROP POLICY IF EXISTS "Allow authenticated users full access to maintenance_tickets" ON maintenance_tickets;
DROP POLICY IF EXISTS "Allow authenticated users full access to maintenance_costs" ON maintenance_costs;

-- ==============================================
-- Profiles Policies
-- ==============================================
CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- ==============================================
-- Orgs Policies
-- ==============================================
CREATE POLICY "Users can view orgs they belong to" ON orgs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = orgs.id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Users can create orgs" ON orgs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Org owners can update orgs" ON orgs
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = orgs.id AND org_members.user_id = auth.uid() AND org_members.role = 'owner')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = orgs.id AND org_members.user_id = auth.uid() AND org_members.role = 'owner')
  );

-- ==============================================
-- Org Members Policies
-- ==============================================
CREATE POLICY "Users can view org members of their orgs" ON org_members
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members om WHERE om.org_id = org_members.org_id AND om.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers can insert org members" ON org_members
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members om WHERE om.org_id = org_members.org_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager'))
    OR NOT EXISTS (SELECT 1 FROM org_members om WHERE om.org_id = org_members.org_id)
  );

CREATE POLICY "Org owners can update org members" ON org_members
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members om WHERE om.org_id = org_members.org_id AND om.user_id = auth.uid() AND om.role = 'owner')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members om WHERE om.org_id = org_members.org_id AND om.user_id = auth.uid() AND om.role = 'owner')
  );

CREATE POLICY "Org owners can delete org members" ON org_members
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members om WHERE om.org_id = org_members.org_id AND om.user_id = auth.uid() AND om.role = 'owner')
  );

-- ==============================================
-- Tenant User Links Policies
-- ==============================================
CREATE POLICY "Users can view their own tenant links" ON tenant_user_links
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Org members can manage tenant links" ON tenant_user_links
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM tenants t 
      JOIN org_members om ON om.org_id = t.org_id 
      WHERE t.id = tenant_user_links.tenant_id AND om.user_id = auth.uid()
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM tenants t 
      JOIN org_members om ON om.org_id = t.org_id 
      WHERE t.id = tenant_user_links.tenant_id AND om.user_id = auth.uid()
    )
  );

-- ==============================================
-- Properties Policies (org-based)
-- ==============================================
CREATE POLICY "Org members can view properties" ON properties
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = properties.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org members can insert properties" ON properties
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = properties.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

CREATE POLICY "Org members can update properties" ON properties
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = properties.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = properties.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

CREATE POLICY "Org owners can delete properties" ON properties
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = properties.org_id AND org_members.user_id = auth.uid() AND org_members.role = 'owner')
  );

-- ==============================================
-- Units Policies (org-based)
-- ==============================================
CREATE POLICY "Org members can view units" ON units
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = units.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org members can insert units" ON units
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = units.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

CREATE POLICY "Org members can update units" ON units
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = units.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'caretaker'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = units.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'caretaker'))
  );

CREATE POLICY "Org owners can delete units" ON units
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = units.org_id AND org_members.user_id = auth.uid() AND org_members.role = 'owner')
  );

-- ==============================================
-- Tenants Policies (org-based + tenant self-view)
-- ==============================================
CREATE POLICY "Org members can view tenants" ON tenants
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = tenants.org_id AND org_members.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM tenant_user_links WHERE tenant_user_links.tenant_id = tenants.id AND tenant_user_links.user_id = auth.uid())
  );

CREATE POLICY "Org members can insert tenants" ON tenants
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = tenants.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org members can update tenants" ON tenants
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = tenants.org_id AND org_members.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = tenants.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers can delete tenants" ON tenants
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = tenants.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

-- ==============================================
-- Leases Policies (org-based + tenant self-view)
-- ==============================================
CREATE POLICY "Org members and linked tenants can view leases" ON leases
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = leases.org_id AND org_members.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM tenant_user_links WHERE tenant_user_links.tenant_id = leases.tenant_id AND tenant_user_links.user_id = auth.uid())
  );

CREATE POLICY "Org members can insert leases" ON leases
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = leases.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

CREATE POLICY "Org members can update leases" ON leases
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = leases.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = leases.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

CREATE POLICY "Org owners can delete leases" ON leases
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = leases.org_id AND org_members.user_id = auth.uid() AND org_members.role = 'owner')
  );

-- ==============================================
-- Invoices Policies (org-based + tenant self-view)
-- ==============================================
CREATE POLICY "Org members and linked tenants can view invoices" ON invoices
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = invoices.org_id AND org_members.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM tenant_user_links WHERE tenant_user_links.tenant_id = invoices.tenant_id AND tenant_user_links.user_id = auth.uid())
  );

CREATE POLICY "Org members can insert invoices" ON invoices
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = invoices.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  );

CREATE POLICY "Org members can update invoices" ON invoices
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = invoices.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = invoices.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  );

CREATE POLICY "Org owners/accountants can delete invoices" ON invoices
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = invoices.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'accountant'))
  );

-- ==============================================
-- Invoice Lines Policies
-- ==============================================
CREATE POLICY "Org members and linked tenants can view invoice lines" ON invoice_lines
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM invoices i 
      JOIN org_members om ON om.org_id = i.org_id 
      WHERE i.id = invoice_lines.invoice_id AND om.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM invoices i 
      JOIN tenant_user_links tul ON tul.tenant_id = i.tenant_id 
      WHERE i.id = invoice_lines.invoice_id AND tul.user_id = auth.uid()
    )
  );

CREATE POLICY "Org members can manage invoice lines" ON invoice_lines
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM invoices i 
      JOIN org_members om ON om.org_id = i.org_id 
      WHERE i.id = invoice_lines.invoice_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager', 'accountant')
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM invoices i 
      JOIN org_members om ON om.org_id = i.org_id 
      WHERE i.id = invoice_lines.invoice_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager', 'accountant')
    )
  );

-- ==============================================
-- Payments Policies (org-based + tenant self-view)
-- ==============================================
CREATE POLICY "Org members and linked tenants can view payments" ON payments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = payments.org_id AND org_members.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM tenant_user_links WHERE tenant_user_links.tenant_id = payments.tenant_id AND tenant_user_links.user_id = auth.uid())
  );

CREATE POLICY "Org members can insert payments" ON payments
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = payments.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org members can update payments" ON payments
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = payments.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = payments.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  );

CREATE POLICY "Org owners/accountants can delete payments" ON payments
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = payments.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'accountant'))
  );

-- ==============================================
-- Payment Allocations Policies
-- ==============================================
CREATE POLICY "Org members and linked tenants can view payment allocations" ON payment_allocations
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM payments p 
      JOIN org_members om ON om.org_id = p.org_id 
      WHERE p.id = payment_allocations.payment_id AND om.user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM payments p 
      JOIN tenant_user_links tul ON tul.tenant_id = p.tenant_id 
      WHERE p.id = payment_allocations.payment_id AND tul.user_id = auth.uid()
    )
  );

CREATE POLICY "Org members can manage payment allocations" ON payment_allocations
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM payments p 
      JOIN org_members om ON om.org_id = p.org_id 
      WHERE p.id = payment_allocations.payment_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager', 'accountant')
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM payments p 
      JOIN org_members om ON om.org_id = p.org_id 
      WHERE p.id = payment_allocations.payment_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager', 'accountant')
    )
  );

-- ==============================================
-- Maintenance Tickets Policies (org-based + tenant self-view)
-- ==============================================
CREATE POLICY "Org members and linked tenants can view tickets" ON maintenance_tickets
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = maintenance_tickets.org_id AND org_members.user_id = auth.uid())
    OR EXISTS (SELECT 1 FROM tenant_user_links WHERE tenant_user_links.tenant_id = maintenance_tickets.tenant_id AND tenant_user_links.user_id = auth.uid())
  );

CREATE POLICY "Org members and linked tenants can insert tickets" ON maintenance_tickets
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = maintenance_tickets.org_id AND org_members.user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM tenant_user_links tul 
      JOIN tenants t ON t.id = tul.tenant_id 
      WHERE t.org_id = maintenance_tickets.org_id AND tul.user_id = auth.uid()
    )
  );

CREATE POLICY "Org members can update tickets" ON maintenance_tickets
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = maintenance_tickets.org_id AND org_members.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = maintenance_tickets.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers can delete tickets" ON maintenance_tickets
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = maintenance_tickets.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

-- ==============================================
-- Maintenance Costs Policies
-- ==============================================
CREATE POLICY "Org members can view maintenance costs" ON maintenance_costs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM maintenance_tickets mt 
      JOIN org_members om ON om.org_id = mt.org_id 
      WHERE mt.id = maintenance_costs.ticket_id AND om.user_id = auth.uid()
    )
  );

CREATE POLICY "Org members can manage maintenance costs" ON maintenance_costs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM maintenance_tickets mt 
      JOIN org_members om ON om.org_id = mt.org_id 
      WHERE mt.id = maintenance_costs.ticket_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager', 'caretaker')
    )
  ) WITH CHECK (
    EXISTS (
      SELECT 1 FROM maintenance_tickets mt 
      JOIN org_members om ON om.org_id = mt.org_id 
      WHERE mt.id = maintenance_costs.ticket_id AND om.user_id = auth.uid() AND om.role IN ('owner', 'manager', 'caretaker')
    )
  );

-- ==============================================
-- Unit Types Policies
-- ==============================================
CREATE POLICY "Org members can view unit types" ON unit_types
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = unit_types.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers can manage unit types" ON unit_types
  FOR ALL USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = unit_types.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = unit_types.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

-- ==============================================
-- Charge Types Policies
-- ==============================================
CREATE POLICY "Org members can view charge types" ON charge_types
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = charge_types.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers/accountants can manage charge types" ON charge_types
  FOR ALL USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = charge_types.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = charge_types.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager', 'accountant'))
  );

-- ==============================================
-- Vendors Policies
-- ==============================================
CREATE POLICY "Org members can view vendors" ON vendors
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = vendors.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers can manage vendors" ON vendors
  FOR ALL USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = vendors.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = vendors.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

-- ==============================================
-- Documents Policies
-- ==============================================
CREATE POLICY "Org members can view documents" ON documents
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = documents.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org members can manage documents" ON documents
  FOR ALL USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = documents.org_id AND org_members.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = documents.org_id AND org_members.user_id = auth.uid())
  );

-- ==============================================
-- Notification Outbox Policies
-- ==============================================
CREATE POLICY "Org members can view notifications" ON notification_outbox
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = notification_outbox.org_id AND org_members.user_id = auth.uid())
  );

CREATE POLICY "Org owners/managers can manage notifications" ON notification_outbox
  FOR ALL USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = notification_outbox.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = notification_outbox.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'manager'))
  );

-- ==============================================
-- Audit Logs Policies (read-only for org members)
-- ==============================================
CREATE POLICY "Org owners/accountants can view audit logs" ON audit_logs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM org_members WHERE org_members.org_id = audit_logs.org_id AND org_members.user_id = auth.uid() AND org_members.role IN ('owner', 'accountant'))
  );

-- Audit logs should only be inserted by the system (via service role)
-- No insert/update/delete policies for regular users

-- ==============================================
-- PART 7: DEFAULT CHARGE TYPES (inserted per org)
-- ==============================================
-- Note: These will be created via edge function when org is created
