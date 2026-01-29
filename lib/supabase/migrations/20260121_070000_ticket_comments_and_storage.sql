-- Create ticket_comments table for threaded discussions
CREATE TABLE IF NOT EXISTS public.ticket_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES public.maintenance_tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachments JSONB DEFAULT '[]'::jsonb,
    is_internal BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_ticket_comments_ticket_id ON public.ticket_comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_comments_user_id ON public.ticket_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_ticket_comments_org_id ON public.ticket_comments(org_id);

-- Enable RLS
ALTER TABLE public.ticket_comments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ticket_comments
-- Admins can do everything for their org
CREATE POLICY ticket_comments_admin_select ON public.ticket_comments
    FOR SELECT TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

CREATE POLICY ticket_comments_admin_insert ON public.ticket_comments
    FOR INSERT TO authenticated
    WITH CHECK (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

CREATE POLICY ticket_comments_admin_update ON public.ticket_comments
    FOR UPDATE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()) AND user_id = auth.uid());

CREATE POLICY ticket_comments_admin_delete ON public.ticket_comments
    FOR DELETE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()) AND user_id = auth.uid());

-- Tenants can view non-internal comments and add their own
CREATE POLICY ticket_comments_tenant_select ON public.ticket_comments
    FOR SELECT TO authenticated
    USING (
        org_id IN (SELECT org_id FROM public.tenant_user_links WHERE user_id = auth.uid())
        AND is_internal = false
        AND ticket_id IN (
            SELECT id FROM public.maintenance_tickets 
            WHERE tenant_id IN (SELECT tenant_id FROM public.tenant_user_links WHERE user_id = auth.uid())
        )
    );

CREATE POLICY ticket_comments_tenant_insert ON public.ticket_comments
    FOR INSERT TO authenticated
    WITH CHECK (
        org_id IN (SELECT org_id FROM public.tenant_user_links WHERE user_id = auth.uid())
        AND user_id = auth.uid()
        AND is_internal = false
        AND ticket_id IN (
            SELECT id FROM public.maintenance_tickets 
            WHERE tenant_id IN (SELECT tenant_id FROM public.tenant_user_links WHERE user_id = auth.uid())
        )
    );

-- Grant permissions
GRANT ALL ON public.ticket_comments TO authenticated;

-- Create storage bucket for ticket attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'ticket-attachments',
    'ticket-attachments',
    false,
    52428800, -- 50MB limit
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/quicktime', 'video/webm']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS policies
CREATE POLICY "ticket_attachments_upload"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'ticket-attachments');

CREATE POLICY "ticket_attachments_select"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'ticket-attachments');

CREATE POLICY "ticket_attachments_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'ticket-attachments' AND owner_id = auth.uid()::text);
