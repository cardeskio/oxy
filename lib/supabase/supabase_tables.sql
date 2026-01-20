-- Properties table
CREATE TABLE properties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('residential', 'commercial', 'mixed')),
  location_text TEXT NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Units table
CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  unit_label TEXT NOT NULL,
  unit_type TEXT,
  rent_amount NUMERIC(10, 2) NOT NULL,
  deposit_amount NUMERIC(10, 2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'vacant' CHECK (status IN ('vacant', 'occupied', 'maintenance')),
  meter_ref_water TEXT,
  meter_ref_power TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Tenants table
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name TEXT NOT NULL,
  phone TEXT NOT NULL,
  id_number TEXT,
  email TEXT,
  next_of_kin_name TEXT,
  next_of_kin_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Leases table
CREATE TABLE leases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  rent_amount NUMERIC(10, 2) NOT NULL,
  deposit_amount NUMERIC(10, 2) NOT NULL,
  due_day INTEGER NOT NULL CHECK (due_day >= 1 AND due_day <= 31),
  grace_days INTEGER NOT NULL DEFAULT 0,
  late_fee_type TEXT NOT NULL DEFAULT 'none' CHECK (late_fee_type IN ('none', 'fixed', 'percent')),
  late_fee_value NUMERIC(10, 2),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'ended')),
  move_in_notes TEXT,
  move_out_notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Invoices table
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lease_id UUID NOT NULL REFERENCES leases(id) ON DELETE CASCADE,
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  period_start TIMESTAMPTZ NOT NULL,
  period_end TIMESTAMPTZ NOT NULL,
  due_date TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'paid', 'void')),
  total_amount NUMERIC(10, 2) NOT NULL,
  balance_amount NUMERIC(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Invoice lines table
CREATE TABLE invoice_lines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  charge_type TEXT NOT NULL,
  description TEXT NOT NULL,
  amount NUMERIC(10, 2) NOT NULL,
  balance_amount NUMERIC(10, 2) NOT NULL
);

-- Payments table
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
  lease_id UUID REFERENCES leases(id) ON DELETE SET NULL,
  unit_id UUID REFERENCES units(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL,
  method TEXT NOT NULL CHECK (method IN ('mpesa', 'cash', 'bank')),
  reference TEXT NOT NULL,
  paid_at TIMESTAMPTZ NOT NULL,
  captured_by TEXT NOT NULL,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'unallocated' CHECK (status IN ('unallocated', 'partiallyAllocated', 'allocated')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Payment allocations table
CREATE TABLE payment_allocations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
  invoice_line_id UUID NOT NULL REFERENCES invoice_lines(id) ON DELETE CASCADE,
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  amount_allocated NUMERIC(10, 2) NOT NULL
);

-- Maintenance tickets table
CREATE TABLE maintenance_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
  unit_id UUID NOT NULL REFERENCES units(id) ON DELETE CASCADE,
  tenant_id UUID REFERENCES tenants(id) ON DELETE SET NULL,
  lease_id UUID REFERENCES leases(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'assigned', 'inProgress', 'done', 'approved', 'rejected')),
  assigned_to_user_id TEXT,
  vendor_id TEXT,
  vendor_name TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Maintenance costs table
CREATE TABLE maintenance_costs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES maintenance_tickets(id) ON DELETE CASCADE,
  item TEXT NOT NULL,
  amount NUMERIC(10, 2) NOT NULL,
  notes TEXT
);

-- Create indexes for better query performance
CREATE INDEX idx_units_property_id ON units(property_id);
CREATE INDEX idx_leases_unit_id ON leases(unit_id);
CREATE INDEX idx_leases_tenant_id ON leases(tenant_id);
CREATE INDEX idx_leases_status ON leases(status);
CREATE INDEX idx_invoices_lease_id ON invoices(lease_id);
CREATE INDEX idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoice_lines_invoice_id ON invoice_lines(invoice_id);
CREATE INDEX idx_payments_tenant_id ON payments(tenant_id);
CREATE INDEX idx_payment_allocations_payment_id ON payment_allocations(payment_id);
CREATE INDEX idx_payment_allocations_invoice_id ON payment_allocations(invoice_id);
CREATE INDEX idx_maintenance_tickets_property_id ON maintenance_tickets(property_id);
CREATE INDEX idx_maintenance_tickets_unit_id ON maintenance_tickets(unit_id);
CREATE INDEX idx_maintenance_tickets_status ON maintenance_tickets(status);
CREATE INDEX idx_maintenance_costs_ticket_id ON maintenance_costs(ticket_id);
