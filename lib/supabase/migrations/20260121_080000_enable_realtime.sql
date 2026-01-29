-- Enable realtime for key tables
-- This allows the app to receive instant updates when data changes

ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE public.leases;
ALTER PUBLICATION supabase_realtime ADD TABLE public.units;
ALTER PUBLICATION supabase_realtime ADD TABLE public.tenants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.invoices;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.ticket_comments;
