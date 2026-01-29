-- =====================================================
-- LIVING FEATURE: Super App Services & Community
-- =====================================================

-- Enable PostGIS extension for location-based queries (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- =====================================================
-- ENUMS
-- =====================================================

-- Service provider status
DO $$ BEGIN
    CREATE TYPE provider_status AS ENUM ('pending', 'active', 'suspended', 'inactive');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Service category type
DO $$ BEGIN
    CREATE TYPE service_category_type AS ENUM (
        'food_dining',
        'shopping',
        'health_wellness',
        'home_services',
        'professional_services',
        'entertainment',
        'transport',
        'education',
        'beauty_spa',
        'fitness',
        'financial',
        'other'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Listing status
DO $$ BEGIN
    CREATE TYPE listing_status AS ENUM ('active', 'paused', 'sold_out', 'expired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Community post type
DO $$ BEGIN
    CREATE TYPE community_post_type AS ENUM ('announcement', 'discussion', 'event', 'recommendation', 'question', 'offer', 'alert');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- =====================================================
-- SERVICE PROVIDERS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.service_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Business details
    business_name TEXT NOT NULL,
    business_description TEXT,
    category service_category_type NOT NULL,
    subcategories TEXT[] DEFAULT '{}',
    
    -- Contact info
    phone TEXT NOT NULL,
    email TEXT,
    website TEXT,
    whatsapp TEXT,
    
    -- Location
    location_text TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOGRAPHY(POINT, 4326), -- PostGIS geography for distance queries
    service_radius_km DOUBLE PRECISION DEFAULT 10, -- How far they can serve
    
    -- Media
    logo_url TEXT,
    cover_image_url TEXT,
    images JSONB DEFAULT '[]'::jsonb,
    
    -- Business hours (JSONB for flexibility)
    -- Format: {"monday": {"open": "09:00", "close": "18:00"}, ...}
    business_hours JSONB DEFAULT '{}'::jsonb,
    
    -- Settings
    status provider_status NOT NULL DEFAULT 'pending',
    is_verified BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    
    -- Stats (denormalized for performance)
    rating_average DOUBLE PRECISION DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    
    -- Metadata
    tags TEXT[] DEFAULT '{}',
    features TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create geography point from lat/lng automatically
CREATE OR REPLACE FUNCTION update_provider_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_provider_location ON public.service_providers;
CREATE TRIGGER trigger_update_provider_location
    BEFORE INSERT OR UPDATE ON public.service_providers
    FOR EACH ROW EXECUTE FUNCTION update_provider_location();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_providers_user ON public.service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_providers_category ON public.service_providers(category);
CREATE INDEX IF NOT EXISTS idx_providers_status ON public.service_providers(status);
CREATE INDEX IF NOT EXISTS idx_providers_location ON public.service_providers USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_providers_featured ON public.service_providers(is_featured) WHERE is_featured = true;

-- =====================================================
-- SERVICE LISTINGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.service_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
    
    -- Listing details
    title TEXT NOT NULL,
    description TEXT,
    price DOUBLE PRECISION,
    price_unit TEXT, -- 'per_hour', 'per_item', 'per_service', 'from', etc.
    
    -- Media
    images JSONB DEFAULT '[]'::jsonb,
    
    -- Status
    status listing_status NOT NULL DEFAULT 'active',
    
    -- Metadata
    tags TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_listings_provider ON public.service_listings(provider_id);
CREATE INDEX IF NOT EXISTS idx_listings_status ON public.service_listings(status);

-- =====================================================
-- SERVICE REVIEWS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.service_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    
    -- Response from provider
    provider_response TEXT,
    provider_response_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(provider_id, user_id) -- One review per user per provider
);

CREATE INDEX IF NOT EXISTS idx_reviews_provider ON public.service_reviews(provider_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user ON public.service_reviews(user_id);

-- Trigger to update provider rating stats
CREATE OR REPLACE FUNCTION update_provider_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.service_providers
    SET 
        rating_average = (
            SELECT COALESCE(AVG(rating), 0) 
            FROM public.service_reviews 
            WHERE provider_id = COALESCE(NEW.provider_id, OLD.provider_id)
        ),
        rating_count = (
            SELECT COUNT(*) 
            FROM public.service_reviews 
            WHERE provider_id = COALESCE(NEW.provider_id, OLD.provider_id)
        ),
        updated_at = NOW()
    WHERE id = COALESCE(NEW.provider_id, OLD.provider_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_provider_rating ON public.service_reviews;
CREATE TRIGGER trigger_update_provider_rating
    AFTER INSERT OR UPDATE OR DELETE ON public.service_reviews
    FOR EACH ROW EXECUTE FUNCTION update_provider_rating();

-- =====================================================
-- COMMUNITY POSTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Post content
    post_type community_post_type NOT NULL DEFAULT 'discussion',
    title TEXT,
    content TEXT NOT NULL,
    images JSONB DEFAULT '[]'::jsonb,
    
    -- Location context
    location_text TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    location GEOGRAPHY(POINT, 4326),
    radius_km DOUBLE PRECISION DEFAULT 5, -- How far this post is relevant
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    
    -- Visibility
    is_pinned BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,
    
    -- Event-specific fields (when post_type = 'event')
    event_date TIMESTAMP WITH TIME ZONE,
    event_end_date TIMESTAMP WITH TIME ZONE,
    event_location TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create geography point from lat/lng
CREATE OR REPLACE FUNCTION update_post_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_post_location ON public.community_posts;
CREATE TRIGGER trigger_update_post_location
    BEFORE INSERT OR UPDATE ON public.community_posts
    FOR EACH ROW EXECUTE FUNCTION update_post_location();

CREATE INDEX IF NOT EXISTS idx_posts_user ON public.community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_type ON public.community_posts(post_type);
CREATE INDEX IF NOT EXISTS idx_posts_location ON public.community_posts USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_posts_created ON public.community_posts(created_at DESC);

-- =====================================================
-- COMMUNITY POST COMMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.community_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID NOT NULL REFERENCES public.community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES public.community_comments(id) ON DELETE CASCADE, -- For nested replies
    
    content TEXT NOT NULL,
    
    likes_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post ON public.community_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user ON public.community_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent ON public.community_comments(parent_id);

-- Trigger to update post comment count
CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.community_posts SET comments_count = comments_count + 1, updated_at = NOW()
        WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.community_posts SET comments_count = GREATEST(0, comments_count - 1), updated_at = NOW()
        WHERE id = OLD.post_id;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_comment_count ON public.community_comments;
CREATE TRIGGER trigger_update_comment_count
    AFTER INSERT OR DELETE ON public.community_comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comment_count();

-- =====================================================
-- LIKES TABLE (for posts and comments)
-- =====================================================

-- Reaction types enum
DO $$ BEGIN
    CREATE TYPE reaction_type AS ENUM ('like', 'love', 'celebrate', 'support', 'insightful', 'funny');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add reaction column to existing table if it exists without the column
DO $$ BEGIN
    ALTER TABLE public.community_likes ADD COLUMN reaction reaction_type NOT NULL DEFAULT 'like';
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.community_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.community_posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.community_comments(id) ON DELETE CASCADE,
    reaction reaction_type NOT NULL DEFAULT 'like',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    ),
    UNIQUE(user_id, post_id),
    UNIQUE(user_id, comment_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_user ON public.community_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_post ON public.community_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_comment ON public.community_likes(comment_id);

-- Triggers to update like counts
CREATE OR REPLACE FUNCTION update_like_counts()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.post_id IS NOT NULL THEN
            UPDATE public.community_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        ELSIF NEW.comment_id IS NOT NULL THEN
            UPDATE public.community_comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.post_id IS NOT NULL THEN
            UPDATE public.community_posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
        ELSIF OLD.comment_id IS NOT NULL THEN
            UPDATE public.community_comments SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.comment_id;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_like_counts ON public.community_likes;
CREATE TRIGGER trigger_update_like_counts
    AFTER INSERT OR DELETE ON public.community_likes
    FOR EACH ROW EXECUTE FUNCTION update_like_counts();

-- =====================================================
-- SAVED/BOOKMARKED PROVIDERS
-- =====================================================

CREATE TABLE IF NOT EXISTS public.saved_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, provider_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_user ON public.saved_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_provider ON public.saved_providers(provider_id);

-- =====================================================
-- ADD LOCATION TO PROPERTIES (for distance calculations)
-- =====================================================

ALTER TABLE public.properties
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326);

-- Trigger for property location
CREATE OR REPLACE FUNCTION update_property_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_property_location ON public.properties;
CREATE TRIGGER trigger_update_property_location
    BEFORE INSERT OR UPDATE ON public.properties
    FOR EACH ROW EXECUTE FUNCTION update_property_location();

CREATE INDEX IF NOT EXISTS idx_properties_location ON public.properties USING GIST(location);

-- =====================================================
-- ADD LOCATION TO PROFILES (user's location preference)
-- =====================================================

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS location GEOGRAPHY(POINT, 4326),
ADD COLUMN IF NOT EXISTS location_text TEXT;

-- Trigger for profile location
CREATE OR REPLACE FUNCTION update_profile_location()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
        NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_profile_location ON public.profiles;
CREATE TRIGGER trigger_update_profile_location
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_profile_location();

CREATE INDEX IF NOT EXISTS idx_profiles_location ON public.profiles USING GIST(location);

-- =====================================================
-- ROW LEVEL SECURITY
-- =====================================================

-- Service Providers RLS
ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;

-- Anyone can view active providers
DROP POLICY IF EXISTS providers_select_active ON public.service_providers;
CREATE POLICY providers_select_active ON public.service_providers
    FOR SELECT TO authenticated
    USING (status = 'active' OR user_id = auth.uid());

-- Providers can manage their own profile
DROP POLICY IF EXISTS providers_insert_own ON public.service_providers;
CREATE POLICY providers_insert_own ON public.service_providers
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS providers_update_own ON public.service_providers;
CREATE POLICY providers_update_own ON public.service_providers
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS providers_delete_own ON public.service_providers;
CREATE POLICY providers_delete_own ON public.service_providers
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- Service Listings RLS
ALTER TABLE public.service_listings ENABLE ROW LEVEL SECURITY;

-- Anyone can view active listings
DROP POLICY IF EXISTS listings_select_active ON public.service_listings;
CREATE POLICY listings_select_active ON public.service_listings
    FOR SELECT TO authenticated
    USING (
        status = 'active' OR 
        provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid())
    );

-- Providers can manage their own listings
DROP POLICY IF EXISTS listings_insert_own ON public.service_listings;
CREATE POLICY listings_insert_own ON public.service_listings
    FOR INSERT TO authenticated
    WITH CHECK (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS listings_update_own ON public.service_listings;
CREATE POLICY listings_update_own ON public.service_listings
    FOR UPDATE TO authenticated
    USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS listings_delete_own ON public.service_listings;
CREATE POLICY listings_delete_own ON public.service_listings
    FOR DELETE TO authenticated
    USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));

-- Service Reviews RLS
ALTER TABLE public.service_reviews ENABLE ROW LEVEL SECURITY;

-- Anyone can read reviews
DROP POLICY IF EXISTS reviews_select_all ON public.service_reviews;
CREATE POLICY reviews_select_all ON public.service_reviews
    FOR SELECT TO authenticated
    USING (true);

-- Users can write their own reviews
DROP POLICY IF EXISTS reviews_insert_own ON public.service_reviews;
CREATE POLICY reviews_insert_own ON public.service_reviews
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS reviews_update_own ON public.service_reviews;
CREATE POLICY reviews_update_own ON public.service_reviews
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid() OR provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));

DROP POLICY IF EXISTS reviews_delete_own ON public.service_reviews;
CREATE POLICY reviews_delete_own ON public.service_reviews
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- Community Posts RLS
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;

-- Anyone can read non-hidden posts
DROP POLICY IF EXISTS posts_select_visible ON public.community_posts;
CREATE POLICY posts_select_visible ON public.community_posts
    FOR SELECT TO authenticated
    USING (is_hidden = false OR user_id = auth.uid());

-- Users can create posts
DROP POLICY IF EXISTS posts_insert_own ON public.community_posts;
CREATE POLICY posts_insert_own ON public.community_posts
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS posts_update_own ON public.community_posts;
CREATE POLICY posts_update_own ON public.community_posts
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS posts_delete_own ON public.community_posts;
CREATE POLICY posts_delete_own ON public.community_posts
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- Community Comments RLS
ALTER TABLE public.community_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS comments_select_all ON public.community_comments;
CREATE POLICY comments_select_all ON public.community_comments
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS comments_insert_own ON public.community_comments;
CREATE POLICY comments_insert_own ON public.community_comments
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS comments_update_own ON public.community_comments;
CREATE POLICY comments_update_own ON public.community_comments
    FOR UPDATE TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS comments_delete_own ON public.community_comments;
CREATE POLICY comments_delete_own ON public.community_comments
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- Community Likes RLS
ALTER TABLE public.community_likes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS likes_select_all ON public.community_likes;
CREATE POLICY likes_select_all ON public.community_likes
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS likes_insert_own ON public.community_likes;
CREATE POLICY likes_insert_own ON public.community_likes
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS likes_delete_own ON public.community_likes;
CREATE POLICY likes_delete_own ON public.community_likes
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- Saved Providers RLS
ALTER TABLE public.saved_providers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS saved_select_own ON public.saved_providers;
CREATE POLICY saved_select_own ON public.saved_providers
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS saved_insert_own ON public.saved_providers;
CREATE POLICY saved_insert_own ON public.saved_providers
    FOR INSERT TO authenticated
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS saved_delete_own ON public.saved_providers;
CREATE POLICY saved_delete_own ON public.saved_providers
    FOR DELETE TO authenticated
    USING (user_id = auth.uid());

-- =====================================================
-- GRANTS
-- =====================================================

GRANT ALL ON public.service_providers TO authenticated;
GRANT ALL ON public.service_listings TO authenticated;
GRANT ALL ON public.service_reviews TO authenticated;
GRANT ALL ON public.community_posts TO authenticated;
GRANT ALL ON public.community_comments TO authenticated;
GRANT ALL ON public.community_likes TO authenticated;
GRANT ALL ON public.saved_providers TO authenticated;

-- =====================================================
-- REALTIME
-- =====================================================

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.service_providers;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_posts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_comments;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.community_likes;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function to get nearby providers
CREATE OR REPLACE FUNCTION get_nearby_providers(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10,
    category_filter service_category_type DEFAULT NULL,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    business_name TEXT,
    business_description TEXT,
    category service_category_type,
    phone TEXT,
    location_text TEXT,
    logo_url TEXT,
    rating_average DOUBLE PRECISION,
    rating_count INTEGER,
    distance_km DOUBLE PRECISION,
    is_featured BOOLEAN,
    features TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.business_name,
        sp.business_description,
        sp.category,
        sp.phone,
        sp.location_text,
        sp.logo_url,
        sp.rating_average,
        sp.rating_count,
        ST_Distance(
            sp.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
        ) / 1000 as distance_km,
        sp.is_featured,
        sp.features
    FROM public.service_providers sp
    WHERE sp.status = 'active'
        AND (category_filter IS NULL OR sp.category = category_filter)
        AND ST_DWithin(
            sp.location,
            ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
            radius_km * 1000
        )
    ORDER BY sp.is_featured DESC, distance_km ASC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get nearby community posts
DROP FUNCTION IF EXISTS get_nearby_posts(double precision, double precision, double precision, community_post_type, integer);
CREATE OR REPLACE FUNCTION get_nearby_posts(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10,
    post_type_filter community_post_type DEFAULT NULL,
    limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    post_type community_post_type,
    title TEXT,
    content TEXT,
    images JSONB,
    location_text TEXT,
    likes_count INTEGER,
    comments_count INTEGER,
    is_pinned BOOLEAN,
    event_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    distance_km DOUBLE PRECISION,
    user_name TEXT,
    user_avatar_url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cp.id,
        cp.user_id,
        cp.post_type,
        cp.title,
        cp.content,
        cp.images,
        cp.location_text,
        cp.likes_count,
        cp.comments_count,
        cp.is_pinned,
        cp.event_date,
        cp.created_at,
        cp.updated_at,
        CASE 
            WHEN cp.location IS NOT NULL THEN
                ST_Distance(
                    cp.location,
                    ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography
                ) / 1000
            ELSE NULL
        END as distance_km,
        p.full_name as user_name,
        p.avatar_url as user_avatar_url
    FROM public.community_posts cp
    LEFT JOIN public.profiles p ON p.id = cp.user_id
    WHERE cp.is_hidden = false
        AND (post_type_filter IS NULL OR cp.post_type = post_type_filter)
        AND (
            cp.location IS NULL OR
            ST_DWithin(
                cp.location,
                ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)::geography,
                radius_km * 1000
            )
        )
    ORDER BY cp.is_pinned DESC, cp.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- STORAGE BUCKET FOR COMMUNITY POSTS
-- =============================================

-- Create community storage bucket (run in Supabase dashboard or via API)
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('community', 'community', true)
-- ON CONFLICT (id) DO NOTHING;

-- Storage policies for community bucket
-- Note: Run these in Supabase dashboard as storage policies require special permissions

-- Policy: Authenticated users can upload to community bucket
-- CREATE POLICY "Authenticated users can upload to community bucket"
-- ON storage.objects FOR INSERT TO authenticated
-- WITH CHECK (bucket_id = 'community' AND auth.uid()::text = (storage.foldername(name))[2]);

-- Policy: Anyone can view community bucket files
-- CREATE POLICY "Anyone can view community bucket files"
-- ON storage.objects FOR SELECT TO public
-- USING (bucket_id = 'community');

-- Policy: Users can delete their own community uploads
-- CREATE POLICY "Users can delete their own community uploads"
-- ON storage.objects FOR DELETE TO authenticated
-- USING (bucket_id = 'community' AND auth.uid()::text = (storage.foldername(name))[2]);
