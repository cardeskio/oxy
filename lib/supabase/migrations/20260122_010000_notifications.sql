-- ============================================
-- NOTIFICATIONS TABLE
-- ============================================

-- Create notification types enum
CREATE TYPE notification_type AS ENUM (
  -- Manager notifications
  'new_ticket',           -- New maintenance ticket submitted
  'ticket_message',       -- New message on a ticket
  'new_enquiry',          -- New property enquiry
  'enquiry_message',      -- New message on an enquiry
  'payment_received',     -- Payment received from tenant
  'lease_expiring',       -- Lease expiring soon
  
  -- Tenant notifications
  'invoice_created',      -- New invoice generated
  'ticket_updated',       -- Ticket status changed
  'ticket_reply',         -- Manager replied to ticket
  'enquiry_updated',      -- Enquiry status changed
  'enquiry_reply',        -- Manager replied to enquiry
  'lease_reminder'        -- Lease renewal reminder
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id UUID REFERENCES public.orgs(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  data JSONB DEFAULT '{}',  -- Additional data (e.g., ticket_id, invoice_id)
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_org_id ON public.notifications(org_id);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read) WHERE is_read = FALSE;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can only see their own notifications
CREATE POLICY notifications_select_own ON public.notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

-- Users can update (mark as read) their own notifications
CREATE POLICY notifications_update_own ON public.notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- System can insert notifications (via triggers/functions)
CREATE POLICY notifications_insert_system ON public.notifications
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- Users can delete their own notifications
CREATE POLICY notifications_delete_own ON public.notifications
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- Grant permissions
GRANT ALL ON public.notifications TO authenticated;

-- ============================================
-- ENABLE REALTIME
-- ============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- ============================================
-- HELPER FUNCTION TO CREATE NOTIFICATIONS
-- ============================================

CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_org_id UUID,
  p_type notification_type,
  p_title TEXT,
  p_body TEXT DEFAULT NULL,
  p_data JSONB DEFAULT '{}'
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.notifications (user_id, org_id, type, title, body, data)
  VALUES (p_user_id, p_org_id, p_type, p_title, p_body, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$;

-- ============================================
-- TRIGGER: New Maintenance Ticket → Notify Managers
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_new_ticket()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_manager RECORD;
  v_unit_label TEXT;
  v_property_name TEXT;
BEGIN
  -- Get unit and property info
  SELECT u.unit_label, p.name INTO v_unit_label, v_property_name
  FROM public.units u
  JOIN public.properties p ON p.id = u.property_id
  WHERE u.id = NEW.unit_id;

  -- Notify all managers in the org
  FOR v_manager IN 
    SELECT user_id FROM public.org_members WHERE org_id = NEW.org_id
  LOOP
    PERFORM public.create_notification(
      v_manager.user_id,
      NEW.org_id,
      'new_ticket'::notification_type,
      'New Maintenance Request',
      COALESCE(v_property_name, 'Property') || ' - ' || COALESCE(v_unit_label, 'Unit') || ': ' || NEW.title,
      jsonb_build_object('ticket_id', NEW.id, 'unit_id', NEW.unit_id)
    );
  END LOOP;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_new_maintenance_ticket
  AFTER INSERT ON public.maintenance_tickets
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_ticket();

-- ============================================
-- TRIGGER: Ticket Status Change → Notify Tenant
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_ticket_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tenant_user_id UUID;
  v_status_text TEXT;
BEGIN
  -- Only notify if status actually changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get the tenant's user_id from the unit's current lease
  SELECT tul.user_id INTO v_tenant_user_id
  FROM public.leases l
  JOIN public.tenant_user_links tul ON tul.tenant_id = l.tenant_id
  WHERE l.unit_id = NEW.unit_id AND l.status = 'active'
  LIMIT 1;

  IF v_tenant_user_id IS NOT NULL THEN
    v_status_text := CASE NEW.status
      WHEN 'assigned' THEN 'has been assigned'
      WHEN 'in_progress' THEN 'is now in progress'
      WHEN 'done' THEN 'has been completed'
      WHEN 'approved' THEN 'has been approved'
      WHEN 'rejected' THEN 'has been rejected'
      ELSE 'has been updated'
    END;

    PERFORM public.create_notification(
      v_tenant_user_id,
      NEW.org_id,
      'ticket_updated'::notification_type,
      'Ticket Status Updated',
      'Your request "' || NEW.title || '" ' || v_status_text,
      jsonb_build_object('ticket_id', NEW.id)
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_ticket_status_change
  AFTER UPDATE ON public.maintenance_tickets
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_ticket_status_change();

-- ============================================
-- TRIGGER: New Invoice → Notify Tenant
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_new_invoice()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tenant_user_id UUID;
BEGIN
  -- Get tenant's user_id
  SELECT tul.user_id INTO v_tenant_user_id
  FROM public.tenant_user_links tul
  WHERE tul.tenant_id = NEW.tenant_id
  LIMIT 1;

  IF v_tenant_user_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_tenant_user_id,
      NEW.org_id,
      'invoice_created'::notification_type,
      'New Invoice',
      'A new invoice of ' || NEW.total_amount || ' has been generated',
      jsonb_build_object('invoice_id', NEW.id, 'amount', NEW.total_amount)
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_new_invoice
  AFTER INSERT ON public.invoices
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_invoice();

-- ============================================
-- TRIGGER: Payment Received → Notify Managers
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_payment_received()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_manager RECORD;
  v_tenant_name TEXT;
BEGIN
  -- Get tenant name
  SELECT full_name INTO v_tenant_name
  FROM public.tenants
  WHERE id = NEW.tenant_id;

  -- Notify all managers in the org
  FOR v_manager IN 
    SELECT user_id FROM public.org_members WHERE org_id = NEW.org_id
  LOOP
    PERFORM public.create_notification(
      v_manager.user_id,
      NEW.org_id,
      'payment_received'::notification_type,
      'Payment Received',
      COALESCE(v_tenant_name, 'A tenant') || ' made a payment of ' || NEW.amount,
      jsonb_build_object('payment_id', NEW.id, 'tenant_id', NEW.tenant_id, 'amount', NEW.amount)
    );
  END LOOP;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_payment_received
  AFTER INSERT ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_payment_received();

-- ============================================
-- TRIGGER: New Property Enquiry → Notify Managers
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_new_enquiry()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_manager RECORD;
  v_property_name TEXT;
BEGIN
  -- Get property name
  SELECT name INTO v_property_name
  FROM public.properties
  WHERE id = NEW.property_id;

  -- Notify all managers in the org
  FOR v_manager IN 
    SELECT user_id FROM public.org_members WHERE org_id = NEW.org_id
  LOOP
    PERFORM public.create_notification(
      v_manager.user_id,
      NEW.org_id,
      'new_enquiry'::notification_type,
      'New Property Enquiry',
      NEW.contact_name || ' is interested in ' || COALESCE(v_property_name, 'a property'),
      jsonb_build_object('enquiry_id', NEW.id, 'property_id', NEW.property_id)
    );
  END LOOP;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_new_enquiry
  AFTER INSERT ON public.property_enquiries
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_new_enquiry();

-- ============================================
-- TRIGGER: New Ticket Comment → Notify Relevant Party
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_ticket_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ticket RECORD;
  v_tenant_user_id UUID;
  v_is_from_manager BOOLEAN;
BEGIN
  -- Get ticket info
  SELECT * INTO v_ticket FROM public.maintenance_tickets WHERE id = NEW.ticket_id;
  
  -- Check if comment is from manager (org member)
  SELECT EXISTS(
    SELECT 1 FROM public.org_members WHERE user_id = NEW.user_id AND org_id = v_ticket.org_id
  ) INTO v_is_from_manager;

  IF v_is_from_manager THEN
    -- Manager commented, notify tenant
    SELECT tul.user_id INTO v_tenant_user_id
    FROM public.leases l
    JOIN public.tenant_user_links tul ON tul.tenant_id = l.tenant_id
    WHERE l.unit_id = v_ticket.unit_id AND l.status = 'active'
    LIMIT 1;

    IF v_tenant_user_id IS NOT NULL AND v_tenant_user_id != NEW.user_id THEN
      PERFORM public.create_notification(
        v_tenant_user_id,
        v_ticket.org_id,
        'ticket_reply'::notification_type,
        'New Reply on Your Request',
        'Manager replied to "' || v_ticket.title || '"',
        jsonb_build_object('ticket_id', NEW.ticket_id)
      );
    END IF;
  ELSE
    -- Tenant commented, notify managers
    DECLARE
      v_manager RECORD;
    BEGIN
      FOR v_manager IN 
        SELECT user_id FROM public.org_members WHERE org_id = v_ticket.org_id
      LOOP
        IF v_manager.user_id != NEW.user_id THEN
          PERFORM public.create_notification(
            v_manager.user_id,
            v_ticket.org_id,
            'ticket_message'::notification_type,
            'New Message on Ticket',
            'Tenant replied to "' || v_ticket.title || '"',
            jsonb_build_object('ticket_id', NEW.ticket_id)
          );
        END IF;
      END LOOP;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_ticket_comment
  AFTER INSERT ON public.ticket_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_ticket_comment();

-- ============================================
-- TRIGGER: New Enquiry Comment → Notify Relevant Party
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_enquiry_comment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_enquiry RECORD;
  v_is_from_manager BOOLEAN;
BEGIN
  -- Get enquiry info
  SELECT * INTO v_enquiry FROM public.property_enquiries WHERE id = NEW.enquiry_id;
  
  -- Check if comment is from manager
  IF NEW.is_from_manager THEN
    -- Manager commented, notify enquirer
    IF v_enquiry.user_id IS NOT NULL AND v_enquiry.user_id != NEW.user_id THEN
      PERFORM public.create_notification(
        v_enquiry.user_id,
        v_enquiry.org_id,
        'enquiry_reply'::notification_type,
        'Reply to Your Enquiry',
        'Property manager responded to your enquiry',
        jsonb_build_object('enquiry_id', NEW.enquiry_id)
      );
    END IF;
  ELSE
    -- Tenant/User commented, notify managers
    DECLARE
      v_manager RECORD;
    BEGIN
      FOR v_manager IN 
        SELECT user_id FROM public.org_members WHERE org_id = v_enquiry.org_id
      LOOP
        IF v_manager.user_id != NEW.user_id THEN
          PERFORM public.create_notification(
            v_manager.user_id,
            v_enquiry.org_id,
            'enquiry_message'::notification_type,
            'New Message on Enquiry',
            v_enquiry.full_name || ' sent a message',
            jsonb_build_object('enquiry_id', NEW.enquiry_id)
          );
        END IF;
      END LOOP;
    END;
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_enquiry_comment
  AFTER INSERT ON public.enquiry_comments
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_enquiry_comment();

-- ============================================
-- TRIGGER: Enquiry Status Change → Notify Tenant
-- ============================================

CREATE OR REPLACE FUNCTION public.notify_enquiry_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status_text TEXT;
BEGIN
  -- Only notify if status actually changed
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  IF NEW.user_id IS NOT NULL THEN
    v_status_text := CASE NEW.status
      WHEN 'contacted' THEN 'The manager has reached out'
      WHEN 'scheduled' THEN 'A viewing has been scheduled'
      WHEN 'viewing_done' THEN 'Your viewing has been completed'
      WHEN 'converted' THEN 'Your enquiry has been converted'
      WHEN 'declined' THEN 'Your enquiry has been declined'
      ELSE 'Your enquiry has been updated'
    END;

    PERFORM public.create_notification(
      NEW.user_id,
      NEW.org_id,
      'enquiry_updated'::notification_type,
      'Enquiry Update',
      v_status_text,
      jsonb_build_object('enquiry_id', NEW.id, 'status', NEW.status)
    );
  END IF;
  
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_enquiry_status_change
  AFTER UPDATE ON public.property_enquiries
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_enquiry_status_change();
