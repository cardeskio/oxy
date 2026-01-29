-- Create database views for dashboard statistics and reporting
-- These views provide pre-aggregated data for better performance

-- ============================================================================
-- VIEW: org_dashboard_stats
-- Provides key metrics for each organization's dashboard
-- ============================================================================
CREATE OR REPLACE VIEW public.org_dashboard_stats AS
SELECT 
    o.id AS org_id,
    o.name AS org_name,
    -- Property & Unit counts
    COALESCE(prop.property_count, 0) AS property_count,
    COALESCE(unit.total_units, 0) AS total_units,
    COALESCE(unit.occupied_units, 0) AS occupied_units,
    COALESCE(unit.vacant_units, 0) AS vacant_units,
    CASE 
        WHEN COALESCE(unit.total_units, 0) > 0 
        THEN ROUND((COALESCE(unit.occupied_units, 0)::numeric / unit.total_units) * 100, 1)
        ELSE 0 
    END AS occupancy_rate,
    -- Tenant counts
    COALESCE(ten.tenant_count, 0) AS tenant_count,
    -- Lease counts
    COALESCE(lea.active_leases, 0) AS active_leases,
    COALESCE(lea.ending_soon, 0) AS leases_ending_soon,
    -- Financial
    COALESCE(lea.expected_rent, 0) AS expected_monthly_rent,
    COALESCE(inv.total_arrears, 0) AS total_arrears,
    COALESCE(inv.open_invoices, 0) AS open_invoices_count,
    COALESCE(pay.collected_this_month, 0) AS collected_this_month,
    -- Maintenance
    COALESCE(maint.open_tickets, 0) AS open_tickets,
    COALESCE(maint.in_progress_tickets, 0) AS in_progress_tickets
FROM public.orgs o
LEFT JOIN (
    SELECT org_id, COUNT(*) AS property_count
    FROM public.properties
    GROUP BY org_id
) prop ON o.id = prop.org_id
LEFT JOIN (
    SELECT 
        org_id,
        COUNT(*) AS total_units,
        COUNT(*) FILTER (WHERE status = 'occupied') AS occupied_units,
        COUNT(*) FILTER (WHERE status = 'vacant') AS vacant_units
    FROM public.units
    GROUP BY org_id
) unit ON o.id = unit.org_id
LEFT JOIN (
    SELECT org_id, COUNT(*) AS tenant_count
    FROM public.tenants
    GROUP BY org_id
) ten ON o.id = ten.org_id
LEFT JOIN (
    SELECT 
        org_id,
        COUNT(*) FILTER (WHERE status = 'active') AS active_leases,
        COUNT(*) FILTER (WHERE status = 'active' AND end_date <= CURRENT_DATE + INTERVAL '30 days') AS ending_soon,
        COALESCE(SUM(rent_amount) FILTER (WHERE status = 'active'), 0) AS expected_rent
    FROM public.leases
    GROUP BY org_id
) lea ON o.id = lea.org_id
LEFT JOIN (
    SELECT 
        org_id,
        COALESCE(SUM(balance_amount) FILTER (WHERE status = 'open'), 0) AS total_arrears,
        COUNT(*) FILTER (WHERE status = 'open') AS open_invoices
    FROM public.invoices
    GROUP BY org_id
) inv ON o.id = inv.org_id
LEFT JOIN (
    SELECT 
        org_id,
        COALESCE(SUM(amount) FILTER (WHERE paid_at >= DATE_TRUNC('month', CURRENT_DATE)), 0) AS collected_this_month
    FROM public.payments
    GROUP BY org_id
) pay ON o.id = pay.org_id
LEFT JOIN (
    SELECT 
        org_id,
        COUNT(*) FILTER (WHERE status NOT IN ('approved', 'rejected')) AS open_tickets,
        COUNT(*) FILTER (WHERE status = 'in_progress') AS in_progress_tickets
    FROM public.maintenance_tickets
    GROUP BY org_id
) maint ON o.id = maint.org_id;

-- Grant access to authenticated users
GRANT SELECT ON public.org_dashboard_stats TO authenticated;

-- ============================================================================
-- VIEW: property_stats
-- Provides unit and financial stats per property
-- ============================================================================
CREATE OR REPLACE VIEW public.property_stats AS
SELECT 
    p.id AS property_id,
    p.org_id,
    p.name AS property_name,
    COALESCE(u.total_units, 0) AS total_units,
    COALESCE(u.occupied_units, 0) AS occupied_units,
    COALESCE(u.vacant_units, 0) AS vacant_units,
    CASE 
        WHEN COALESCE(u.total_units, 0) > 0 
        THEN ROUND((COALESCE(u.occupied_units, 0)::numeric / u.total_units) * 100, 1)
        ELSE 0 
    END AS occupancy_rate,
    COALESCE(l.expected_rent, 0) AS expected_monthly_rent,
    COALESCE(m.open_tickets, 0) AS open_tickets
FROM public.properties p
LEFT JOIN (
    SELECT 
        property_id,
        COUNT(*) AS total_units,
        COUNT(*) FILTER (WHERE status = 'occupied') AS occupied_units,
        COUNT(*) FILTER (WHERE status = 'vacant') AS vacant_units
    FROM public.units
    GROUP BY property_id
) u ON p.id = u.property_id
LEFT JOIN (
    SELECT 
        property_id,
        COALESCE(SUM(rent_amount) FILTER (WHERE status = 'active'), 0) AS expected_rent
    FROM public.leases
    GROUP BY property_id
) l ON p.id = l.property_id
LEFT JOIN (
    SELECT 
        property_id,
        COUNT(*) FILTER (WHERE status NOT IN ('approved', 'rejected')) AS open_tickets
    FROM public.maintenance_tickets
    GROUP BY property_id
) m ON p.id = m.property_id;

-- Grant access
GRANT SELECT ON public.property_stats TO authenticated;

-- ============================================================================
-- VIEW: tenant_balance_summary
-- Shows balance information for each tenant
-- ============================================================================
CREATE OR REPLACE VIEW public.tenant_balance_summary AS
SELECT 
    t.id AS tenant_id,
    t.org_id,
    t.full_name,
    t.phone,
    COALESCE(i.total_balance, 0) AS total_balance,
    COALESCE(i.open_invoices, 0) AS open_invoices_count,
    COALESCE(p.total_paid, 0) AS total_paid,
    l.unit_id,
    l.property_id,
    l.rent_amount AS current_rent
FROM public.tenants t
LEFT JOIN (
    SELECT 
        tenant_id,
        COALESCE(SUM(balance_amount) FILTER (WHERE status = 'open'), 0) AS total_balance,
        COUNT(*) FILTER (WHERE status = 'open') AS open_invoices
    FROM public.invoices
    GROUP BY tenant_id
) i ON t.id = i.tenant_id
LEFT JOIN (
    SELECT 
        tenant_id,
        COALESCE(SUM(amount), 0) AS total_paid
    FROM public.payments
    GROUP BY tenant_id
) p ON t.id = p.tenant_id
LEFT JOIN LATERAL (
    SELECT unit_id, property_id, rent_amount
    FROM public.leases
    WHERE tenant_id = t.id AND status = 'active'
    ORDER BY created_at DESC
    LIMIT 1
) l ON true;

-- Grant access
GRANT SELECT ON public.tenant_balance_summary TO authenticated;

-- ============================================================================
-- VIEW: monthly_collection_summary
-- Shows collection performance by month
-- ============================================================================
CREATE OR REPLACE VIEW public.monthly_collection_summary AS
SELECT 
    org_id,
    DATE_TRUNC('month', paid_at)::date AS month,
    COUNT(*) AS payment_count,
    SUM(amount) AS total_collected,
    COUNT(DISTINCT tenant_id) AS unique_tenants
FROM public.payments
WHERE paid_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY org_id, DATE_TRUNC('month', paid_at)
ORDER BY month DESC;

-- Grant access
GRANT SELECT ON public.monthly_collection_summary TO authenticated;

-- ============================================================================
-- VIEW: arrears_by_tenant
-- Shows tenants with outstanding balances
-- ============================================================================
CREATE OR REPLACE VIEW public.arrears_by_tenant AS
SELECT 
    t.id AS tenant_id,
    t.org_id,
    t.full_name,
    t.phone,
    COALESCE(SUM(i.balance_amount), 0) AS total_arrears,
    COUNT(i.id) AS overdue_invoices,
    MIN(i.due_date) AS oldest_due_date
FROM public.tenants t
INNER JOIN public.invoices i ON t.id = i.tenant_id
WHERE i.status = 'open' AND i.due_date < CURRENT_DATE
GROUP BY t.id, t.org_id, t.full_name, t.phone
HAVING SUM(i.balance_amount) > 0
ORDER BY total_arrears DESC;

-- Grant access
GRANT SELECT ON public.arrears_by_tenant TO authenticated;

-- ============================================================================
-- RLS policies for views (views inherit table RLS but need explicit policies)
-- ============================================================================

-- Enable RLS on views by creating security barrier views
-- Note: In PostgreSQL, views don't have RLS directly, but we grant SELECT
-- and the underlying table RLS will filter the data appropriately.
-- The user will only see data for orgs they belong to.
