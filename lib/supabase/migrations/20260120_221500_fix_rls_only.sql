-- Migration: Fix RLS infinite recursion (policies only, no table changes)
-- This migration fixes the infinite recursion in RLS policies for org_members and tenant_user_links

-- ============================================================================
-- STEP 1: Drop ALL existing policies on affected tables
-- ============================================================================

-- Drop all policies on org_members
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'org_members' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.org_members', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on orgs
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'orgs' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.orgs', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on tenant_user_links
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'tenant_user_links' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.tenant_user_links', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on profiles
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'profiles' AND schemaname = 'public'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.profiles', pol.policyname);
    END LOOP;
END $$;

-- Drop all policies on all other org-scoped tables
DO $$
DECLARE
    tbl TEXT;
    pol RECORD;
BEGIN
    FOREACH tbl IN ARRAY ARRAY['properties', 'units', 'tenants', 'leases', 'invoices', 'invoice_lines', 
                               'payments', 'payment_allocations', 'maintenance_tickets', 'maintenance_costs',
                               'documents', 'audit_logs', 'vendors', 'charge_types', 'unit_types', 
                               'notification_outbox']
    LOOP
        FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = tbl AND schemaname = 'public'
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, tbl);
        END LOOP;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Drop and recreate helper functions
-- ============================================================================

DROP FUNCTION IF EXISTS public.get_user_org_ids(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_org_member(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS public.get_user_tenant_org_ids(uuid) CASCADE;
DROP FUNCTION IF EXISTS public.is_tenant_user(uuid) CASCADE;

-- Function to get all org IDs for a user (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_user_org_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT org_id FROM org_members WHERE user_id = p_user_id;
$$;

-- Function to check if a user is a member of an org (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_org_member(p_user_id uuid, p_org_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM org_members 
        WHERE user_id = p_user_id AND org_id = p_org_id
    );
$$;

-- Function to get org IDs for a tenant user (bypasses RLS)
CREATE OR REPLACE FUNCTION public.get_user_tenant_org_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT DISTINCT org_id FROM tenant_user_links WHERE user_id = p_user_id;
$$;

-- Function to check if a user is linked as a tenant (bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_tenant_user(p_user_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM tenant_user_links WHERE user_id = p_user_id
    );
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_user_org_ids(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_org_member(uuid, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_tenant_org_ids(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_tenant_user(uuid) TO authenticated;

-- ============================================================================
-- STEP 3: Enable RLS on all tables
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orgs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.org_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_user_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_costs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.charge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.unit_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 4: Create RLS policies for profiles
-- ============================================================================

-- Users can read their own profile
CREATE POLICY "profiles_select_own"
ON public.profiles FOR SELECT
TO authenticated
USING (id = auth.uid());

-- Users can insert their own profile
CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (id = auth.uid());

-- Users can update their own profile
CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- ============================================================================
-- STEP 5: Create RLS policies for orgs (NO recursion)
-- ============================================================================

-- Any authenticated user can create an org
CREATE POLICY "orgs_insert_authenticated"
ON public.orgs FOR INSERT
TO authenticated
WITH CHECK (true);

-- Users can only view orgs they are members of (uses helper function)
CREATE POLICY "orgs_select_member"
ON public.orgs FOR SELECT
TO authenticated
USING (id IN (SELECT get_user_org_ids(auth.uid())));

-- Users can only update orgs they are members of
CREATE POLICY "orgs_update_member"
ON public.orgs FOR UPDATE
TO authenticated
USING (id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (id IN (SELECT get_user_org_ids(auth.uid())));

-- Users can only delete orgs they are members of
CREATE POLICY "orgs_delete_member"
ON public.orgs FOR DELETE
TO authenticated
USING (id IN (SELECT get_user_org_ids(auth.uid())));

-- ============================================================================
-- STEP 6: Create RLS policies for org_members (NO recursion)
-- ============================================================================

-- Users can insert themselves as org members (for creating new orgs)
CREATE POLICY "org_members_insert_self"
ON public.org_members FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Users can view members of their orgs
CREATE POLICY "org_members_select_member"
ON public.org_members FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Users can update members of their orgs
CREATE POLICY "org_members_update_member"
ON public.org_members FOR UPDATE
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Users can delete members of their orgs
CREATE POLICY "org_members_delete_member"
ON public.org_members FOR DELETE
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- ============================================================================
-- STEP 7: Create RLS policies for tenant_user_links (NO recursion)
-- ============================================================================

-- Org members can insert tenant links for their orgs
CREATE POLICY "tenant_user_links_insert_org"
ON public.tenant_user_links FOR INSERT
TO authenticated
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Org members can view tenant links for their orgs
CREATE POLICY "tenant_user_links_select_org"
ON public.tenant_user_links FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Tenant users can view their own links
CREATE POLICY "tenant_user_links_select_own"
ON public.tenant_user_links FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- Org members can update tenant links for their orgs
CREATE POLICY "tenant_user_links_update_org"
ON public.tenant_user_links FOR UPDATE
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- Org members can delete tenant links for their orgs
CREATE POLICY "tenant_user_links_delete_org"
ON public.tenant_user_links FOR DELETE
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- ============================================================================
-- STEP 8: Create RLS policies for all org-scoped tables
-- ============================================================================

-- Helper macro for org-scoped tables (property managers access via org_id)
-- We'll also allow tenant users to access data for their linked orgs

-- PROPERTIES
CREATE POLICY "properties_all_org"
ON public.properties FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "properties_select_tenant"
ON public.properties FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- UNITS
CREATE POLICY "units_all_org"
ON public.units FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "units_select_tenant"
ON public.units FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- TENANTS
CREATE POLICY "tenants_all_org"
ON public.tenants FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "tenants_select_tenant"
ON public.tenants FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- LEASES
CREATE POLICY "leases_all_org"
ON public.leases FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "leases_select_tenant"
ON public.leases FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- INVOICES
CREATE POLICY "invoices_all_org"
ON public.invoices FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "invoices_select_tenant"
ON public.invoices FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- INVOICE_LINES
CREATE POLICY "invoice_lines_all_org"
ON public.invoice_lines FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "invoice_lines_select_tenant"
ON public.invoice_lines FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- PAYMENTS
CREATE POLICY "payments_all_org"
ON public.payments FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "payments_select_tenant"
ON public.payments FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- PAYMENT_ALLOCATIONS
CREATE POLICY "payment_allocations_all_org"
ON public.payment_allocations FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "payment_allocations_select_tenant"
ON public.payment_allocations FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- MAINTENANCE_TICKETS
CREATE POLICY "maintenance_tickets_all_org"
ON public.maintenance_tickets FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "maintenance_tickets_select_tenant"
ON public.maintenance_tickets FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- Tenants can create maintenance tickets for their org
CREATE POLICY "maintenance_tickets_insert_tenant"
ON public.maintenance_tickets FOR INSERT
TO authenticated
WITH CHECK (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- MAINTENANCE_COSTS
CREATE POLICY "maintenance_costs_all_org"
ON public.maintenance_costs FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "maintenance_costs_select_tenant"
ON public.maintenance_costs FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- DOCUMENTS
CREATE POLICY "documents_all_org"
ON public.documents FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "documents_select_tenant"
ON public.documents FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- AUDIT_LOGS
CREATE POLICY "audit_logs_all_org"
ON public.audit_logs FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- VENDORS
CREATE POLICY "vendors_all_org"
ON public.vendors FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- CHARGE_TYPES
CREATE POLICY "charge_types_all_org"
ON public.charge_types FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

CREATE POLICY "charge_types_select_tenant"
ON public.charge_types FOR SELECT
TO authenticated
USING (org_id IN (SELECT get_user_tenant_org_ids(auth.uid())));

-- UNIT_TYPES
CREATE POLICY "unit_types_all_org"
ON public.unit_types FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- NOTIFICATION_OUTBOX
CREATE POLICY "notification_outbox_all_org"
ON public.notification_outbox FOR ALL
TO authenticated
USING (org_id IN (SELECT get_user_org_ids(auth.uid())))
WITH CHECK (org_id IN (SELECT get_user_org_ids(auth.uid())));

-- ============================================================================
-- STEP 9: Create trigger for auto-creating profile on user signup
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, email, phone)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.email,
        NEW.raw_user_meta_data->>'phone'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
