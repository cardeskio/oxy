-- Add listing visibility fields to properties and units
ALTER TABLE public.properties
ADD COLUMN IF NOT EXISTS is_listed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS listing_description TEXT;

ALTER TABLE public.units
ADD COLUMN IF NOT EXISTS is_listed BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS listing_description TEXT,
ADD COLUMN IF NOT EXISTS amenities JSONB DEFAULT '[]'::jsonb;

-- Create enquiry status enum type
DO $$ BEGIN
    CREATE TYPE enquiry_status AS ENUM ('pending', 'contacted', 'scheduled', 'viewing_done', 'declined', 'converted');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE enquiry_type AS ENUM ('viewing', 'information', 'application');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create property enquiries table
CREATE TABLE IF NOT EXISTS public.property_enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES public.orgs(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
    unit_id UUID REFERENCES public.units(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    enquiry_type enquiry_type NOT NULL DEFAULT 'viewing',
    status enquiry_status NOT NULL DEFAULT 'pending',
    message TEXT,
    contact_name TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT,
    preferred_date TIMESTAMP WITH TIME ZONE,
    scheduled_date TIMESTAMP WITH TIME ZONE,
    manager_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for enquiries
CREATE INDEX IF NOT EXISTS idx_enquiries_org ON public.property_enquiries(org_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_property ON public.property_enquiries(property_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_user ON public.property_enquiries(user_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_status ON public.property_enquiries(status);

-- Create indexes for listed properties
CREATE INDEX IF NOT EXISTS idx_properties_listed ON public.properties(is_listed) WHERE is_listed = true;
CREATE INDEX IF NOT EXISTS idx_units_listed ON public.units(is_listed) WHERE is_listed = true;

-- RLS for property_enquiries
ALTER TABLE public.property_enquiries ENABLE ROW LEVEL SECURITY;

-- Tenants can view and create their own enquiries
CREATE POLICY enquiries_select_own ON public.property_enquiries
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

CREATE POLICY enquiries_insert_own ON public.property_enquiries
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

-- Admins can view all enquiries for their org
CREATE POLICY enquiries_select_admin ON public.property_enquiries
    FOR SELECT TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Admins can update enquiries for their org
CREATE POLICY enquiries_update_admin ON public.property_enquiries
    FOR UPDATE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Admins can delete enquiries for their org
CREATE POLICY enquiries_delete_admin ON public.property_enquiries
    FOR DELETE TO authenticated
    USING (org_id IN (SELECT org_id FROM public.org_members WHERE user_id = auth.uid()));

-- Create a public view for listed properties (anyone can see)
CREATE OR REPLACE VIEW public.listed_properties AS
SELECT 
    p.id,
    p.org_id,
    p.name,
    p.type,
    p.location_text,
    p.images,
    p.listing_description,
    p.created_at,
    COUNT(u.id) FILTER (WHERE u.is_listed = true AND u.status = 'vacant') as available_units,
    MIN(u.rent_amount) FILTER (WHERE u.is_listed = true AND u.status = 'vacant') as min_rent,
    MAX(u.rent_amount) FILTER (WHERE u.is_listed = true AND u.status = 'vacant') as max_rent
FROM public.properties p
LEFT JOIN public.units u ON u.property_id = p.id
WHERE p.is_listed = true
GROUP BY p.id;

-- Grant select on the view to authenticated users
GRANT SELECT ON public.listed_properties TO authenticated;

-- Create a view for listed units
CREATE OR REPLACE VIEW public.listed_units AS
SELECT 
    u.id,
    u.org_id,
    u.property_id,
    u.unit_label,
    u.unit_type,
    u.rent_amount,
    u.deposit_amount,
    u.images,
    u.listing_description,
    u.amenities,
    u.created_at,
    p.name as property_name,
    p.location_text as property_location,
    p.type as property_type,
    p.images as property_images
FROM public.units u
JOIN public.properties p ON p.id = u.property_id
WHERE u.is_listed = true 
  AND u.status = 'vacant'
  AND p.is_listed = true;

GRANT SELECT ON public.listed_units TO authenticated;

-- Enable realtime for enquiries
ALTER PUBLICATION supabase_realtime ADD TABLE public.property_enquiries;

-- Grant permissions
GRANT ALL ON public.property_enquiries TO authenticated;
