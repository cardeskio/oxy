-- Add user_id column to tenants table for linking tenant records to auth users
ALTER TABLE public.tenants 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_tenants_user_id ON public.tenants(user_id);
