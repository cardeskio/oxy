-- ============================================================================
-- STORAGE BUCKETS CONFIGURATION
-- Creates storage buckets and policies for provider and listing images
-- ============================================================================

-- Create the public bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'public',
    'public',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
    public = true,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- ============================================================================
-- STORAGE POLICIES
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Public read access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own uploads" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own uploads" ON storage.objects;

-- Allow public read access to all files in public bucket
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'public');

-- Allow authenticated users to upload to specific folders
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'public' 
    AND (
        -- Listing images
        (storage.foldername(name))[1] = 'listing-images'
        -- Provider images
        OR (storage.foldername(name))[1] = 'provider-logos'
        OR (storage.foldername(name))[1] = 'provider-covers'
        OR (storage.foldername(name))[1] = 'provider-gallery'
        -- Community post images
        OR (storage.foldername(name))[1] = 'community-posts'
        -- Property images
        OR (storage.foldername(name))[1] = 'property-images'
        -- Tenant documents
        OR (storage.foldername(name))[1] = 'tenant-documents'
        -- Ticket attachments
        OR (storage.foldername(name))[1] = 'ticket-attachments'
    )
);

-- Allow users to update their own uploads
CREATE POLICY "Users can update own uploads"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'public' AND owner_id = auth.uid()::text)
WITH CHECK (bucket_id = 'public' AND owner_id = auth.uid()::text);

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete own uploads"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'public' AND owner_id = auth.uid()::text);
