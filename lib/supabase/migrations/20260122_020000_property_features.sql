-- Add features column to properties table
-- Features are stored as a JSONB array of strings (e.g., ["Parking", "Security", "Pool"])
ALTER TABLE public.properties
ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '[]'::jsonb;

-- Update the listed_properties view to include features
CREATE OR REPLACE VIEW public.listed_properties AS
SELECT 
    p.id,
    p.org_id,
    p.name,
    p.type,
    p.location_text,
    p.images,
    p.listing_description,
    p.features,
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
