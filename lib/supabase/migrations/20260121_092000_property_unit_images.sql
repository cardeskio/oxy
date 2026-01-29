-- Add images column to properties and units (JSONB array of image objects)
ALTER TABLE public.properties ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.units ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]'::jsonb;

-- Create storage bucket for property/unit images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'property-images',
  'property-images',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage policies for property-images bucket
DROP POLICY IF EXISTS "property_images_select" ON storage.objects;
DROP POLICY IF EXISTS "property_images_insert" ON storage.objects;
DROP POLICY IF EXISTS "property_images_delete" ON storage.objects;

CREATE POLICY "property_images_select" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'property-images');

CREATE POLICY "property_images_insert" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-images');

CREATE POLICY "property_images_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'property-images');
