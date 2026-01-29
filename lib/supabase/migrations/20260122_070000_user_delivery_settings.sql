-- Create user_delivery_settings table for storing saved delivery/contact info
CREATE TABLE IF NOT EXISTS public.user_delivery_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    default_name TEXT,
    default_phone TEXT,
    default_address TEXT,
    default_apartment TEXT,
    default_unit TEXT,
    default_instructions TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE public.user_delivery_settings ENABLE ROW LEVEL SECURITY;

-- Users can only access their own delivery settings
CREATE POLICY "Users can view own delivery settings"
    ON public.user_delivery_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own delivery settings"
    ON public.user_delivery_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own delivery settings"
    ON public.user_delivery_settings FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own delivery settings"
    ON public.user_delivery_settings FOR DELETE
    USING (auth.uid() = user_id);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_delivery_settings_user_id 
    ON public.user_delivery_settings(user_id);
