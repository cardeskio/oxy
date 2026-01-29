-- Add profile snapshot columns to tenant_claim_codes
-- This allows managers to see tenant info without needing cross-user profile access

ALTER TABLE public.tenant_claim_codes
ADD COLUMN IF NOT EXISTS user_name TEXT,
ADD COLUMN IF NOT EXISTS user_email TEXT,
ADD COLUMN IF NOT EXISTS user_phone TEXT;

-- Update existing claim codes with profile data (if any exist)
UPDATE public.tenant_claim_codes cc
SET 
    user_name = p.full_name,
    user_email = p.email,
    user_phone = p.phone
FROM public.profiles p
WHERE cc.user_id = p.id
AND cc.user_name IS NULL;
