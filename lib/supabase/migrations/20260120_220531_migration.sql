-- =============================================
-- Migration: Add multi-tenancy support tables
-- =============================================

-- 1. Create profiles table linked to auth.users
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT,
  phone TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create organizations table
CREATE TABLE IF NOT EXISTS orgs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'KE',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Create org_members table
CREATE TABLE IF NOT EXISTS org_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'manager' CHECK (role IN ('owner', 'manager', 'accountant', 'caretaker')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(org_id, user_id)
);

-- 4. Create tenant_claim_codes table
CREATE TABLE IF NOT EXISTS tenant_claim_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id UUID REFERENCES orgs(id) ON DELETE SET NULL,
  tenant_id UUID,
  claimed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Create tenant_user_links table
CREATE TABLE IF NOT EXISTS tenant_user_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL,
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, tenant_id)
);

-- 6. Create vendors table
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  specialty TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. Create charge_types table
CREATE TABLE IF NOT EXISTS charge_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES orgs(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. Add org_id to existing tables (if not exists)
DO $$
BEGIN
  -- Add org_id to properties
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'org_id') THEN
    ALTER TABLE properties ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;

  -- Add org_id to units
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'units' AND column_name = 'org_id') THEN
    ALTER TABLE units ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;

  -- Add org_id to tenants
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'org_id') THEN
    ALTER TABLE tenants ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;

  -- Add user_id to tenants (for linking to auth user)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tenants' AND column_name = 'user_id') THEN
    ALTER TABLE tenants ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;

  -- Add org_id to leases
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'leases' AND column_name = 'org_id') THEN
    ALTER TABLE leases ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;

  -- Add org_id to invoices
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'invoices' AND column_name = 'org_id') THEN
    ALTER TABLE invoices ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;

  -- Add org_id to payments
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'payments' AND column_name = 'org_id') THEN
    ALTER TABLE payments ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;

  -- Add org_id to maintenance_tickets
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'maintenance_tickets' AND column_name = 'org_id') THEN
    ALTER TABLE maintenance_tickets ADD COLUMN org_id UUID REFERENCES orgs(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 9. Add foreign key from tenant_claim_codes to tenants
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'tenant_claim_codes_tenant_id_fkey' 
    AND table_name = 'tenant_claim_codes'
  ) THEN
    ALTER TABLE tenant_claim_codes 
    ADD CONSTRAINT tenant_claim_codes_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE SET NULL;
  END IF;
END $$;

-- 10. Add foreign key from tenant_user_links to tenants
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'tenant_user_links_tenant_id_fkey' 
    AND table_name = 'tenant_user_links'
  ) THEN
    ALTER TABLE tenant_user_links 
    ADD CONSTRAINT tenant_user_links_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 11. Create indexes for new tables and columns
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON org_members(org_id);
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON org_members(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_claim_codes_code ON tenant_claim_codes(code);
CREATE INDEX IF NOT EXISTS idx_tenant_claim_codes_user_id ON tenant_claim_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_user_links_user_id ON tenant_user_links(user_id);
CREATE INDEX IF NOT EXISTS idx_tenant_user_links_tenant_id ON tenant_user_links(tenant_id);
CREATE INDEX IF NOT EXISTS idx_vendors_org_id ON vendors(org_id);
CREATE INDEX IF NOT EXISTS idx_charge_types_org_id ON charge_types(org_id);
CREATE INDEX IF NOT EXISTS idx_properties_org_id ON properties(org_id);
CREATE INDEX IF NOT EXISTS idx_tenants_org_id ON tenants(org_id);
CREATE INDEX IF NOT EXISTS idx_tenants_user_id ON tenants(user_id);

-- =============================================
-- Security Functions (SECURITY DEFINER to bypass RLS)
-- =============================================

-- Drop existing functions if they exist (with CASCADE to remove dependent policies)
DROP FUNCTION IF EXISTS public.get_user_org_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_org_member(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_tenant_org_ids(UUID) CASCADE;
DROP FUNCTION IF EXISTS public.is_tenant_user(UUID, UUID) CASCADE;

-- Function to get all org IDs a user belongs to (as admin)
CREATE OR REPLACE FUNCTION public.get_user_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT org_id FROM org_members WHERE user_id = p_user_id;
$$;

-- Function to check if a user is a member of an org (as admin)
CREATE OR REPLACE FUNCTION public.is_org_member(p_user_id UUID, p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM org_members WHERE user_id = p_user_id AND org_id = p_org_id
  );
$$;

-- Function to get all org IDs a user has tenant access to
CREATE OR REPLACE FUNCTION public.get_user_tenant_org_ids(p_user_id UUID)
RETURNS SETOF UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT org_id FROM tenant_user_links WHERE user_id = p_user_id;
$$;

-- Function to check if a user is a tenant in an org
CREATE OR REPLACE FUNCTION public.is_tenant_user(p_user_id UUID, p_org_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM tenant_user_links WHERE user_id = p_user_id AND org_id = p_org_id
  );
$$;

-- Grant execute permissions on helper functions
GRANT EXECUTE ON FUNCTION public.get_user_org_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_member(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_tenant_org_ids(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_tenant_user(UUID, UUID) TO authenticated;

-- =============================================
-- Row Level Security Policies
-- =============================================

-- Enable RLS on all new tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_claim_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant_user_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE charge_types ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies on these tables (to avoid conflicts)
DO $$
DECLARE
  pol RECORD;
BEGIN
  -- Drop policies on profiles
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol.policyname);
  END LOOP;
  
  -- Drop policies on orgs
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'orgs' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.orgs', pol.policyname);
  END LOOP;
  
  -- Drop policies on org_members
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'org_members' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.org_members', pol.policyname);
  END LOOP;
  
  -- Drop policies on tenant_claim_codes
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_claim_codes' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_claim_codes', pol.policyname);
  END LOOP;
  
  -- Drop policies on tenant_user_links
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_user_links' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_user_links', pol.policyname);
  END LOOP;
  
  -- Drop policies on vendors
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'vendors' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.vendors', pol.policyname);
  END LOOP;
  
  -- Drop policies on charge_types
  FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'charge_types' AND schemaname = 'public' LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.charge_types', pol.policyname);
  END LOOP;
END $$;

-- =============================================
-- Profiles Policies
-- =============================================
-- Users can read and update their own profile
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- =============================================
-- Orgs Policies
-- =============================================
-- Any authenticated user can create an org
CREATE POLICY "orgs_insert_authenticated" ON orgs
  FOR INSERT TO authenticated WITH CHECK (true);

-- Members can view their orgs
CREATE POLICY "orgs_select_member" ON orgs
  FOR SELECT USING (id IN (SELECT get_user_org_ids(auth.uid())));

-- Members can update their orgs
CREATE POLICY "orgs_update_member" ON orgs
  FOR UPDATE USING (id IN (SELECT get_user_org_ids(auth.uid()))) WITH CHECK (true);

-- =============================================
-- Org Members Policies
-- =============================================
-- Users can insert themselves as members (for creating new orgs)
CREATE POLICY "org_members_insert_self" ON org_members
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Members can view members in their orgs
CREATE POLICY "org_members_select_member" ON org_members
  FOR SELECT USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Members can update members in their orgs
CREATE POLICY "org_members_update_member" ON org_members
  FOR UPDATE USING (org_id IN (SELECT get_user_org_ids(auth.uid()))) WITH CHECK (true);

-- Members can delete members in their orgs
CREATE POLICY "org_members_delete_member" ON org_members
  FOR DELETE USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- =============================================
-- Tenant Claim Codes Policies
-- =============================================
-- Users can create their own claim codes
CREATE POLICY "tenant_claim_codes_insert_own" ON tenant_claim_codes
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- Users can view their own claim codes
CREATE POLICY "tenant_claim_codes_select_own" ON tenant_claim_codes
  FOR SELECT USING (user_id = auth.uid());

-- Org members can view and update claim codes (for linking)
CREATE POLICY "tenant_claim_codes_select_org" ON tenant_claim_codes
  FOR SELECT USING (true); -- Allow lookup by code

CREATE POLICY "tenant_claim_codes_update_org" ON tenant_claim_codes
  FOR UPDATE USING (true) WITH CHECK (true); -- Allow claiming

-- =============================================
-- Tenant User Links Policies
-- =============================================
-- Org members can create tenant links
CREATE POLICY "tenant_user_links_insert_org" ON tenant_user_links
  FOR INSERT TO authenticated WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Users can view their own links
CREATE POLICY "tenant_user_links_select_own" ON tenant_user_links
  FOR SELECT USING (user_id = auth.uid());

-- Org members can view links in their org
CREATE POLICY "tenant_user_links_select_org" ON tenant_user_links
  FOR SELECT USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- =============================================
-- Vendors Policies
-- =============================================
CREATE POLICY "vendors_all_org_members" ON vendors
  FOR ALL USING (org_id IN (SELECT get_user_org_ids(auth.uid()))) WITH CHECK (true);

-- =============================================
-- Charge Types Policies
-- =============================================
CREATE POLICY "charge_types_all_org_members" ON charge_types
  FOR ALL USING (org_id IN (SELECT get_user_org_ids(auth.uid()))) WITH CHECK (true);

-- =============================================
-- Update existing table policies to use org_id
-- =============================================

-- Drop old simple policies and create org-aware ones
DO $$
DECLARE
  pol RECORD;
BEGIN
  -- Drop all existing policies on properties, units, tenants, leases, invoices, payments, maintenance_tickets
  FOR pol IN 
    SELECT policyname, tablename 
    FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename IN ('properties', 'units', 'tenants', 'leases', 'invoices', 'invoice_lines', 'payments', 'payment_allocations', 'maintenance_tickets', 'maintenance_costs')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, pol.tablename);
  END LOOP;
END $$;

-- Properties: org members OR tenants in org
CREATE POLICY "properties_select" ON properties
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL -- Allow null org_id for migration period
  );

CREATE POLICY "properties_insert" ON properties
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "properties_update" ON properties
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "properties_delete" ON properties
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Units
CREATE POLICY "units_select" ON units
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "units_insert" ON units
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "units_update" ON units
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "units_delete" ON units
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Tenants
CREATE POLICY "tenants_select" ON tenants
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR user_id = auth.uid()
    OR org_id IS NULL
  );

CREATE POLICY "tenants_insert" ON tenants
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "tenants_update" ON tenants
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR user_id = auth.uid()
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "tenants_delete" ON tenants
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Leases
CREATE POLICY "leases_select" ON leases
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "leases_insert" ON leases
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "leases_update" ON leases
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "leases_delete" ON leases
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Invoices
CREATE POLICY "invoices_select" ON invoices
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "invoices_insert" ON invoices
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "invoices_update" ON invoices
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "invoices_delete" ON invoices
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Invoice lines (inherit from invoices)
CREATE POLICY "invoice_lines_all" ON invoice_lines
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM invoices WHERE invoices.id = invoice_lines.invoice_id
      AND (
        invoices.org_id IN (SELECT get_user_org_ids(auth.uid()))
        OR invoices.org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
        OR invoices.org_id IS NULL
      )
    )
  ) WITH CHECK (true);

-- Payments
CREATE POLICY "payments_select" ON payments
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "payments_insert" ON payments
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "payments_update" ON payments
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "payments_delete" ON payments
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Payment allocations (inherit from payments)
CREATE POLICY "payment_allocations_all" ON payment_allocations
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM payments WHERE payments.id = payment_allocations.payment_id
      AND (
        payments.org_id IN (SELECT get_user_org_ids(auth.uid()))
        OR payments.org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
        OR payments.org_id IS NULL
      )
    )
  ) WITH CHECK (true);

-- Maintenance tickets
CREATE POLICY "maintenance_tickets_select" ON maintenance_tickets
  FOR SELECT USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "maintenance_tickets_insert" ON maintenance_tickets
  FOR INSERT WITH CHECK (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  );

CREATE POLICY "maintenance_tickets_update" ON maintenance_tickets
  FOR UPDATE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
    OR org_id IS NULL
  ) WITH CHECK (true);

CREATE POLICY "maintenance_tickets_delete" ON maintenance_tickets
  FOR DELETE USING (
    org_id IN (SELECT get_user_org_ids(auth.uid()))
    OR org_id IS NULL
  );

-- Maintenance costs (inherit from tickets)
CREATE POLICY "maintenance_costs_all" ON maintenance_costs
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM maintenance_tickets WHERE maintenance_tickets.id = maintenance_costs.ticket_id
      AND (
        maintenance_tickets.org_id IN (SELECT get_user_org_ids(auth.uid()))
        OR maintenance_tickets.org_id IN (SELECT get_user_tenant_org_ids(auth.uid()))
        OR maintenance_tickets.org_id IS NULL
      )
    )
  ) WITH CHECK (true);

-- =============================================
-- Trigger for automatic profile creation
-- =============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- Create trigger for new user signup (drop first if exists)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
