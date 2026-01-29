-- Create enquiry comments table for communication threads
CREATE TABLE IF NOT EXISTS public.enquiry_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enquiry_id UUID NOT NULL REFERENCES public.property_enquiries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_from_manager BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_enquiry_comments_enquiry ON public.enquiry_comments(enquiry_id);
CREATE INDEX IF NOT EXISTS idx_enquiry_comments_user ON public.enquiry_comments(user_id);

-- Enable RLS
ALTER TABLE public.enquiry_comments ENABLE ROW LEVEL SECURITY;

-- Users can view comments on their own enquiries
CREATE POLICY enquiry_comments_select_own ON public.enquiry_comments
    FOR SELECT TO authenticated
    USING (
        enquiry_id IN (SELECT id FROM public.property_enquiries WHERE user_id = auth.uid())
    );

-- Users can add comments to their own enquiries
CREATE POLICY enquiry_comments_insert_own ON public.enquiry_comments
    FOR INSERT TO authenticated
    WITH CHECK (
        user_id = auth.uid() AND
        enquiry_id IN (SELECT id FROM public.property_enquiries WHERE user_id = auth.uid())
    );

-- Managers can view all comments for their org's enquiries
CREATE POLICY enquiry_comments_select_admin ON public.enquiry_comments
    FOR SELECT TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Managers can add comments to any enquiry in their org
CREATE POLICY enquiry_comments_insert_admin ON public.enquiry_comments
    FOR INSERT TO authenticated
    WITH CHECK (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Managers can update comments in their org
CREATE POLICY enquiry_comments_update_admin ON public.enquiry_comments
    FOR UPDATE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Grant permissions
GRANT ALL ON public.enquiry_comments TO authenticated;

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.enquiry_comments;
