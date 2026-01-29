-- Fix ambiguous parameter names in RPC functions
-- Parameters like 'radius_km' conflict with column references in PL/pgSQL

-- ============================================
-- Fix get_nearby_providers function
-- ============================================
DROP FUNCTION IF EXISTS get_nearby_providers(double precision, double precision, double precision, service_category_type, integer);

CREATE OR REPLACE FUNCTION get_nearby_providers(
    p_user_lat DOUBLE PRECISION,
    p_user_lng DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 10,
    p_category_filter service_category_type DEFAULT NULL,
    p_limit_count INTEGER DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    business_name TEXT,
    business_description TEXT,
    category service_category_type,
    subcategories TEXT[],
    phone TEXT,
    email TEXT,
    website TEXT,
    whatsapp TEXT,
    location_text TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    service_radius_km DOUBLE PRECISION,
    logo_url TEXT,
    cover_image_url TEXT,
    images JSONB,
    business_hours JSONB,
    status TEXT,
    is_verified BOOLEAN,
    is_featured BOOLEAN,
    rating_average DOUBLE PRECISION,
    rating_count INTEGER,
    tags TEXT[],
    features TEXT[],
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE,
    distance_km DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sp.id,
        sp.user_id,
        sp.business_name,
        sp.business_description,
        sp.category,
        sp.subcategories,
        sp.phone,
        sp.email,
        sp.website,
        sp.whatsapp,
        sp.location_text,
        sp.latitude,
        sp.longitude,
        sp.service_radius_km,
        sp.logo_url,
        sp.cover_image_url,
        sp.images,
        sp.business_hours,
        sp.status::TEXT,
        sp.is_verified,
        sp.is_featured,
        sp.rating_average,
        sp.rating_count,
        sp.tags,
        sp.features,
        sp.created_at,
        sp.updated_at,
        ST_Distance(
            sp.location,
            ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
        ) / 1000 as distance_km
    FROM public.service_providers sp
    WHERE sp.status = 'active'
        AND sp.location IS NOT NULL
        AND (p_category_filter IS NULL OR sp.category = p_category_filter)
        AND ST_DWithin(
            sp.location,
            ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
            p_radius_km * 1000
        )
    ORDER BY sp.is_featured DESC, distance_km ASC
    LIMIT p_limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Fix get_nearby_posts function
-- ============================================
DROP FUNCTION IF EXISTS get_nearby_posts(double precision, double precision, double precision, community_post_type, integer);

CREATE OR REPLACE FUNCTION get_nearby_posts(
    p_user_lat DOUBLE PRECISION,
    p_user_lng DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 10,
    p_post_type_filter community_post_type DEFAULT NULL,
    p_limit_count INTEGER DEFAULT 50
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
                    ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography
                ) / 1000
            ELSE NULL
        END as distance_km,
        p.full_name as user_name,
        p.avatar_url as user_avatar_url
    FROM public.community_posts cp
    LEFT JOIN public.profiles p ON p.id = cp.user_id
    WHERE cp.is_hidden = false
        AND (p_post_type_filter IS NULL OR cp.post_type = p_post_type_filter)
        AND (
            cp.location IS NULL OR
            ST_DWithin(
                cp.location,
                ST_SetSRID(ST_MakePoint(p_user_lng, p_user_lat), 4326)::geography,
                p_radius_km * 1000
            )
        )
    ORDER BY cp.is_pinned DESC, cp.created_at DESC
    LIMIT p_limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
