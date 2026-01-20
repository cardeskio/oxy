-- Enable Row Level Security for all tables
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE leases ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_costs ENABLE ROW LEVEL SECURITY;

-- Properties policies
CREATE POLICY "Allow authenticated users full access to properties" ON properties
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Units policies
CREATE POLICY "Allow authenticated users full access to units" ON units
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Tenants policies
CREATE POLICY "Allow authenticated users full access to tenants" ON tenants
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Leases policies
CREATE POLICY "Allow authenticated users full access to leases" ON leases
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Invoices policies
CREATE POLICY "Allow authenticated users full access to invoices" ON invoices
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Invoice lines policies
CREATE POLICY "Allow authenticated users full access to invoice_lines" ON invoice_lines
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Payments policies
CREATE POLICY "Allow authenticated users full access to payments" ON payments
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Payment allocations policies
CREATE POLICY "Allow authenticated users full access to payment_allocations" ON payment_allocations
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Maintenance tickets policies
CREATE POLICY "Allow authenticated users full access to maintenance_tickets" ON maintenance_tickets
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);

-- Maintenance costs policies
CREATE POLICY "Allow authenticated users full access to maintenance_costs" ON maintenance_costs
  FOR ALL USING (auth.uid() IS NOT NULL) WITH CHECK (auth.uid() IS NOT NULL);
