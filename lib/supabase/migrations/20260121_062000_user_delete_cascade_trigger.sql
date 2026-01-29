-- Trigger to clean up related data when auth user is deleted
-- This ensures no orphaned tenant records remain

CREATE OR REPLACE FUNCTION public.handle_user_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Delete tenant records linked to this user
    DELETE FROM tenants WHERE user_id = OLD.id;
    
    -- Delete tenant_user_links
    DELETE FROM tenant_user_links WHERE user_id = OLD.id;
    
    -- Delete claim codes
    DELETE FROM tenant_claim_codes WHERE user_id = OLD.id;
    
    -- Delete profile
    DELETE FROM profiles WHERE id = OLD.id;
    
    RETURN OLD;
END;
$$;

-- Create trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_delete ON auth.users;
CREATE TRIGGER on_auth_user_delete
    BEFORE DELETE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_delete();
